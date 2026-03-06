import '../../model/log_report/log_report_model.dart';
import '../../model/log_report/user_journey_event.dart';

/// Parses a list of [ReportLogEntry] into meaningful [UserJourneyEvent]s
/// grouped by user account.
///
/// Supports two log formats:
/// - **Native (Kotlin)**: `[timestamp.SSS] [Level] [AppState] [Native] [Component] [Tag] message`
/// - **Flutter (Dart)**: `[timestamp] [Level] [Background] [eventName] [runtimeType] message`
class UserJourneyParser {
  factory UserJourneyParser() => _instance;
  UserJourneyParser._();

  static final _instance = UserJourneyParser._();

  // ─── ANSI / cleanup patterns ───────────────────────────────────────

  /// ANSI escape codes (e.g. \u001b[34m)
  static final _ansiPattern = RegExp(r'\u001b\[\d+m');

  /// App-version wrapper injected by the server payload: "[1.2.3] ..."
  static final _appVersionPrefix = RegExp(r'^\[[\d.]+\]\s*');

  // ─── Structured log regex ──────────────────────────────────────────
  //
  // Matches both Native and Flutter log formats after ANSI stripping:
  //   [timestamp]  [Level]  [AppState]?  [Layer]?  [Bracket1]  [Bracket2]?  body
  //
  // Native example:
  //   [2026-03-02 14:00:05.123] [Info] [FOREGROUND] [Native] [BLEService] [auto_sync] Scanning...
  //
  // Flutter example:
  //   [2026-03-02 14:00:05] [Info] [Background] [app] [AppLifecycleObserver] App is in the background
  //   [2026-03-02 14:00:05] [Info] [app] [SplashBloc] Splash complete  (no app-state when foreground)

  static final _structuredLogPattern = RegExp(
    r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?)\]\s*' // G1: timestamp (millis optional)
    r'(?:⚠️\s*|🔴\s*)?'
    r'\[(\w+)\]\s*' // G2: Level (Info/Warning/Error/Debug)
    r'(?:⚠️\s*|🔴\s*)?' // optional emoji after level tag
    r'(?:\[(FOREGROUND|BACKGROUND|Background)\]\s*)?' // G3: AppState (optional)
    r'(?:\[(Native|Flutter)\]\s*)?' // G4: Layer (optional)
    r'\[([^\]]*)\]\s*' // G5: First bracket content (component or eventName)
    r'(?:\[([^\]]*)\]\s*)?' // G6: Second bracket content (tag or runtimeType, optional)
    r'(.*)', // G7: Message body
    dotAll: true,
  );

  /// Parse all log entries into journey events
  List<UserJourneyEvent> parseJourneyEvents(List<ReportLogEntry> logs) {
    final events = <UserJourneyEvent>[];

    for (final log in logs) {
      if (log.genTime == null) continue;

      final event = _parseLogEntry(log);
      if (event != null) {
        events.add(event);
      }
    }

    // Sort by timestamp
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return events;
  }

  /// Minimum time gap (in seconds) between events to auto-split into a new node.
  static const _timeGapThresholdSeconds = 120; // 2 minutes

  /// Group events into chronological `JourneyNode`s based on:
  /// 1. Explicit major lifecycle events (app open, background, foreground, etc.)
  /// 2. Session-boundary events (push notification received, sync timer triggered)
  /// 3. Time gaps > 2 minutes between consecutive events
  List<JourneyNode> buildJourneyNodes(List<UserJourneyEvent> events) {
    if (events.isEmpty) return [];

    final nodes = <JourneyNode>[];
    JourneyNode? currentNode;
    DateTime? lastEventTime;

    for (final event in events) {
      // Check if this is a boundary: explicit lifecycle, session boundary, or time gap
      final bool isBoundary =
          _isMajorLifecycleEvent(event) ||
          _isSessionBoundary(event) ||
          (lastEventTime != null &&
              event.timestamp.difference(lastEventTime).inSeconds >
                  _timeGapThresholdSeconds);

      if (isBoundary) {
        // Close the current node
        if (currentNode != null) {
          currentNode.endTime = event.timestamp;
          nodes.add(currentNode);
        }

        // Start a new node using this event as the anchor
        currentNode = JourneyNode(
          startTime: event.timestamp,
          mainStateEvent: event,
        );
      } else {
        // If we don't have a current node yet, create an implicit one
        if (currentNode == null) {
          currentNode = JourneyNode(
            startTime: event.timestamp,
            mainStateEvent: UserJourneyEvent(
              timestamp: event.timestamp,
              type: JourneyEventType.appLifecycle,
              appState: event.appState,
              component: 'System',
              action: 'Session Started',
              details: 'Implicit start',
              logLevel: LogLevel.info,
              accountId: event.accountId,
              layer: event.layer,
            ),
          );
        }
        currentNode.events.add(event);
      }

      lastEventTime = event.timestamp;
    }

    if (currentNode != null) {
      currentNode.endTime = currentNode.events.isNotEmpty
          ? currentNode.events.last.timestamp
          : currentNode.startTime;
      nodes.add(currentNode);
    }

    return nodes;
  }

  /// Get unique account IDs from events
  Set<String> getUniqueAccounts(List<UserJourneyEvent> events) {
    return events
        .where((e) => e.accountId != null && e.accountId!.isNotEmpty)
        .map((e) => e.accountId!)
        .toSet();
  }

  // ─── Private helpers ───────────────────────────────────────────────

  /// Pre-process the raw message: strip ANSI codes, app version prefix, emojis in tags
  static String _preprocess(String raw) {
    var msg = raw;
    // Strip ANSI escape codes
    msg = msg.replaceAll(_ansiPattern, '');
    // Strip app version wrapper e.g. "[1.2.3] "
    msg = msg.replaceFirst(_appVersionPrefix, '');
    // Remove excessive whitespace
    msg = msg.replaceAll(RegExp(r'\s+'), ' ').trim();
    return msg;
  }

  UserJourneyEvent? _parseLogEntry(ReportLogEntry log) {
    final cleaned = _preprocess(log.message);
    final timestamp = log.genTime!;

    // Try the structured log pattern (works for both Native and Flutter)
    final match = _structuredLogPattern.firstMatch(cleaned);
    if (match != null) {
      return _parseStructuredLog(match, log, timestamp);
    }

    // Fallback: still create an event for errors
    if (log.level == LogLevel.error) {
      return UserJourneyEvent(
        timestamp: timestamp,
        type: JourneyEventType.error,
        appState: AppState.unknown,
        component: 'Unknown',
        action: 'Error',
        details: cleaned,
        accountId: log.accountId,
        logLevel: log.level,
      );
    }

    return null;
  }

  /// Parse a structured log matched by _structuredLogPattern
  UserJourneyEvent? _parseStructuredLog(
    RegExpMatch match,
    ReportLogEntry log,
    DateTime timestamp,
  ) {
    final stateRaw = match.group(3) ?? '';
    final layerRaw = match.group(4); // "Native" or "Flutter" or null
    final bracket1 = match.group(5)?.trim() ?? '';
    final bracket2 = match.group(6)?.trim();
    final body = match.group(7)?.trim() ?? '';

    final appState = _parseAppState(stateRaw);

    // Determine layer, component, and tag based on what was captured.
    //
    // Native format has: [AppState] [Native] [Component] [Tag] body
    //   → layer = "Native", component = bracket1, tag = bracket2
    //
    // Flutter format has: [Background]? [eventName] [runtimeType]? body
    //   → layer = "Flutter", eventName = bracket1, component = bracket2 or bracket1
    //
    // If layer is explicitly present, assignment is straightforward.
    // Otherwise, infer from the data.

    String layer;
    String component;
    String? tag;

    if (layerRaw != null) {
      // Explicit layer marker present (Native logs always have [Native])
      layer = layerRaw;
      component = bracket1;
      tag = bracket2;
    } else {
      // No explicit layer → likely Flutter
      layer = 'Flutter';
      // In Flutter format: bracket1 = eventName (tag), bracket2 = runtimeType (component)
      if (bracket2 != null && bracket2.isNotEmpty) {
        tag = bracket1;
        component = bracket2;
      } else {
        // Only one bracket → use as component
        component = bracket1;
        tag = null;
      }
    }

    final type = _classifyEvent(component, tag ?? '', body, log.level);
    final action = _extractAction(component, tag ?? '', body, type);

    // Filter out noisy events
    if (_isNoiseEvent(component, tag ?? '', body)) return null;

    return UserJourneyEvent(
      timestamp: timestamp,
      type: type,
      appState: appState,
      component: component,
      action: action,
      details: body.isNotEmpty ? body : component,
      accountId: log.accountId,
      logLevel: log.level,
      layer: layer,
      tag: tag,
    );
  }

  static AppState _parseAppState(String state) {
    switch (state.toUpperCase()) {
      case 'FOREGROUND':
        return AppState.foreground;
      case 'BACKGROUND':
        return AppState.background;
      default:
        return AppState.unknown;
    }
  }

  static JourneyEventType _classifyEvent(
    String component,
    String tag,
    String body,
    LogLevel level,
  ) {
    if (level == LogLevel.error) return JourneyEventType.error;

    final lc = component.toLowerCase();
    final lt = tag.toLowerCase();
    final lb = body.toLowerCase();

    // ── App Lifecycle ──
    if (lc.contains('splash') || lc.contains('main') || lt == 'app') {
      return JourneyEventType.appLifecycle;
    }
    if (lc == '_appstate' || lc.contains('applifecycleobserver')) {
      return JourneyEventType.appLifecycle;
    }
    if (lb.contains('init app complete') ||
        lb.contains('splash complete') ||
        lb.contains('app initialized') ||
        lb.contains('app resumed') ||
        lb.contains('app is in the foreground') ||
        lb.contains('app is in the background') ||
        lb.contains('app is detached') ||
        lb.contains('app is inactive') ||
        lb.contains('app is hidden') ||
        lb.contains('appfirstload')) {
      return JourneyEventType.appLifecycle;
    }

    // ── Screen Navigation ──
    if (lc.contains('screen') || lc.contains('page') || lc.contains('widget')) {
      return JourneyEventType.screen;
    }

    // ── Network ──
    if (lc.contains('network') ||
        lc.contains('appservices') ||
        lc.contains('appconnection') ||
        lt.contains('lite_mode') ||
        lb.contains('network status') ||
        lb.contains('connectivity') ||
        lb.contains('server heartbeat') ||
        lb.contains('app configs fetched')) {
      return JourneyEventType.network;
    }

    // ── Notifications ──
    if (lc.contains('notification') ||
        lc.contains('firebase') ||
        lc.contains('firebasenotification')) {
      return JourneyEventType.notification;
    }

    // ── Features (BLE, auto-sync, measurement, device, audio, sip, etc.) ──
    if (lt.contains('auto_sync') ||
        lt.contains('device_alert') ||
        lc.contains('ble') ||
        lc.contains('bluetooth') ||
        lc.contains('blehandler') ||
        lc.contains('ble_sdk_log') ||
        lc.contains('measurement') ||
        lc.contains('measurementbloc') ||
        lc.contains('liveactivity') ||
        lc.contains('devicerepository') ||
        lc.contains('deviceusecase') ||
        lc.contains('autosync') ||
        lc.contains('devicechannel') ||
        lc.contains('abnormal') ||
        lc.contains('sipservice') ||
        lc.contains('audioservice') ||
        lc.contains('socketclient') ||
        lc.contains('backgroundservice') ||
        lc.contains('watchdog') ||
        lc.contains('deviceinfoservice')) {
      return JourneyEventType.feature;
    }

    if (level == LogLevel.warning) return JourneyEventType.feature;

    return JourneyEventType.unknown;
  }

  static String _extractAction(
    String component,
    String tag,
    String body,
    JourneyEventType type,
  ) {
    final lb = body.toLowerCase();

    // ── App Lifecycle actions (from main.dart init sequence) ──
    if (lb.contains('init app complete')) return 'App Init Complete';
    if (lb.contains('init app failed')) return 'App Init Failed';
    if (lb.contains('splash complete')) return 'Splash Complete';
    if (lb.contains('app initialized')) return 'App Initialized';
    if (lb.contains('initialize sharedpreferences'))
      return 'Init SharedPreferences';
    if (lb.contains('initialize firebase core')) return 'Init Firebase Core';
    if (lb.contains('firebase core initialized')) return 'Firebase Core Ready';
    if (lb.contains('initialize native channels'))
      return 'Init Native Channels';
    if (lb.contains('initialize other app services'))
      return 'Init App Services';
    if (lb.contains('localdatabase initialized')) return 'DB Initialized';
    if (lb.contains('di configured')) return 'DI Configured';
    if (lb.contains('blehandler initialized')) return 'BLE Handler Init';
    if (lb.contains('initializing firebase services'))
      return 'Init Firebase Services';
    if (lb.contains('done initializing firebase services'))
      return 'Firebase Services Ready';
    if (lb.contains('initializing notification services'))
      return 'Init Notifications';

    // ── App State transitions (from AppLifecycleObserver) ──
    if (lb.contains('app is in the foreground')) return 'App Resumed';
    if (lb.contains('app is in the background')) return 'App Backgrounded';
    if (lb.contains('app is detached')) return 'App Detached';
    if (lb.contains('app is inactive')) return 'App Inactive';
    if (lb.contains('app is hidden')) return 'App Hidden';
    if (lb.contains('user authenticated')) return 'User Authenticated';
    if (lb.contains('listener triggered')) return 'State Changed';
    if (lb.contains('appfirstload')) return 'First Load';

    // ── Network actions ──
    if (lb.contains('checking network')) return 'Checking Network';
    if (lb.contains('checking lite mode')) return 'Checking Lite Mode';
    if (lb.contains('server heartbeat')) return 'Server Heartbeat';
    if (lb.contains('cgm connection')) return 'CGM Connection Check';
    if (lb.contains('all checks completed')) return 'All Checks Complete';
    if (lb.contains('finalstate=')) return 'Final State Determined';
    if (lb.contains('network status') || lb.contains('network details')) {
      return 'Network Status';
    }
    if (lb.contains('server heartbeat: ok')) return 'Server OK';
    if (lb.contains('app configs fetched')) return 'Config Fetched';

    // ── Feature actions ──
    if (lb.contains('start auto sync') ||
        lb.contains('start auto-sync') ||
        lb.contains('restart auto-sync')) {
      return 'Auto Sync Started';
    }
    if (lb.contains('watchdog')) return 'Watchdog Triggered';
    if (lb.contains('stop ble services')) return 'BLE Stopped';
    if (lb.contains('start scanning')) return 'BLE Scanning';
    if (lb.contains('fetched managed device')) return 'Devices Fetched';
    if (lb.contains('start live activity')) return 'Live Activity Started';
    if (lb.contains('stop sync timer')) return 'Sync Timer Stopped';
    if (lb.contains('sync timer triggered')) return 'Sync Timer Triggered';
    if (lb.contains('health check') || lb.contains('healthcheck')) {
      return 'Health Check';
    }
    if (lb.contains('start tracking')) return 'Tracking Started';
    if (lb.contains('startbackgroundsync')) return 'Background Sync Started';
    if (lb.contains('stopbackgroundsync')) return 'Background Sync Stopped';
    if (lb.contains('detect') && lb.contains('missing records')) {
      return 'Missing Records Detected';
    }
    if (lb.contains('sync measurement')) return 'Data Synced to Server';
    if (lb.contains('abnormal')) return 'Abnormal Data Detected';
    if (lb.contains('outofmemory')) return 'Out of Memory';
    if (lb.contains('done handling task when app back')) {
      return 'Resume Tasks Complete';
    }
    if (lb.contains('no valid device for auto-sync')) {
      return 'No Valid Device';
    }
    if (lb.contains('sipservice') && lb.contains('cleanup')) {
      return 'SIP Cleanup';
    }

    // ── Notification actions ──
    if (lb.contains('message received')) return 'Push Received';
    if (lb.contains('trigger ble service from silent')) {
      return 'Silent Push → BLE Sync';
    }

    // ── Error actions ──
    if (type == JourneyEventType.error) {
      if (lb.contains('outofmemory') || lb.contains('oom_error')) {
        return 'OOM Error';
      }
      if (lb.contains('platformexception')) return 'Platform Exception';
      if (lb.contains('gatt')) return 'GATT Error';
      return 'Error';
    }

    // ── Generic ──
    if (lb.contains('started') || lb.contains('start')) return 'Started';
    if (lb.contains('stopped') || lb.contains('stop')) return 'Stopped';
    if (lb.contains('done') || lb.contains('complete')) return 'Completed';

    // Truncate body for short label
    if (body.length > 50) return '${body.substring(0, 47)}...';
    return body.isEmpty ? component : body;
  }

  static bool _isNoiseEvent(String component, String tag, String body) {
    final lb = body.toLowerCase();
    // Filter out very repetitive logs that don't add journey info
    if (lb.contains('initializing firebase remote configs') &&
        !lb.contains('done')) {
      return true;
    }
    if (lb.contains('server connection monitor already running')) return true;
    if (lb.contains('server connection check') && lb.contains('waiting for')) {
      return true;
    }
    if (lb.contains('checkandupdatestate') && !lb.contains('start')) {
      return true;
    }
    if (lb.contains('checkandreloadforlanguagechange')) return true;
    if (lb.contains('firebase lite mode:')) return true;
    if (lb.contains('user manual lite mode:')) return true;
    if (lb.contains('litemode state changed')) return true;
    if (lb.contains('state: connected - restarting')) return true;
    if (lb.contains('appconnection state transition')) return true;
    if (lb.contains('firebase configs:')) return true;
    // Filter BLE SDK noise (very frequent during scanning)
    if (lb.contains('[ble_sdk_log]') && lb.length < 30) return true;
    return false;
  }

  /// True for explicit app lifecycle transitions (app open, close, foreground, background)
  static bool _isMajorLifecycleEvent(UserJourneyEvent event) {
    if (event.type != JourneyEventType.appLifecycle) return false;

    final lb = event.details.toLowerCase();
    final action = event.action;

    return lb.contains('init app complete') ||
        lb.contains('app is in the foreground') ||
        lb.contains('app is in the background') ||
        lb.contains('app is detached') ||
        lb.contains('appfirstload') ||
        lb.contains('splash complete') ||
        action == 'App Init Complete' ||
        action == 'App Resumed' ||
        action == 'App Backgrounded' ||
        action == 'App Detached' ||
        action == 'Splash Complete' ||
        action == 'First Load';
  }

  /// True for events that mark the start of a new "session" of activity,
  /// e.g. push notification arrivals or sync timer triggers.
  static bool _isSessionBoundary(UserJourneyEvent event) {
    final action = event.action;
    final lb = event.details.toLowerCase();

    // Push notification received — signals a new sync cycle
    if (action == 'Push Received' || lb.contains('message received')) {
      return true;
    }
    // Sync timer trigger — signals a new sync cycle
    if (lb.contains('sync timer triggered')) return true;
    // Watchdog trigger — signals a new sync cycle
    if (lb.contains('watchdog')) return true;
    // Silent push → BLE sync
    if (action == 'Silent Push → BLE Sync') return true;
    // Restart auto-sync from notification
    if (lb.contains('restart auto-sync')) return true;

    return false;
  }
}
