import '../../model/log_report/log_report_model.dart';
import '../../model/log_report/user_journey_event.dart';

/// Parses a list of [ReportLogEntry] into meaningful [UserJourneyEvent]s
/// grouped by user account.
class UserJourneyParser {
  /// Regex to extract the structured message parts:
  /// [timestamp] [Level] [STATE] [Layer] [Component] [Tag] message
  static final _nativeLogPattern = RegExp(
    r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+)\]\s*'
    r'\[(\w+)\]\s*'
    r'(?:⚠️\s*|🔴\s*)?'
    r'\[(\w+)\]\s*' // FOREGROUND / BACKGROUND
    r'\[(\w+)\]\s*' // Native / Flutter
    r'\[([^\]]*)\]\s*' // Component name
    r'\[([^\]]*)\]\s*' // Tag
    r'(.*)', // Rest of message
    dotAll: true,
  );

  /// Parse all log entries into journey events
  static List<UserJourneyEvent> parseJourneyEvents(List<ReportLogEntry> logs) {
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

  /// Group events into sessions. A new session starts when there's a gap > [gapMinutes]
  /// between consecutive events, or when an app lifecycle event indicates restart.
  static List<UserJourneySession> groupIntoSessions(
    List<UserJourneyEvent> events, {
    int gapMinutes = 5,
  }) {
    if (events.isEmpty) return [];

    final sessions = <UserJourneySession>[];
    var currentSessionEvents = <UserJourneyEvent>[events.first];

    for (int i = 1; i < events.length; i++) {
      final prev = events[i - 1];
      final curr = events[i];

      final gap = curr.timestamp.difference(prev.timestamp);
      final isNewSession =
          gap.inMinutes > gapMinutes || _isAppRestartEvent(curr);

      if (isNewSession && currentSessionEvents.isNotEmpty) {
        sessions.add(_buildSession(currentSessionEvents));
        currentSessionEvents = [];
      }
      currentSessionEvents.add(curr);
    }

    if (currentSessionEvents.isNotEmpty) {
      sessions.add(_buildSession(currentSessionEvents));
    }

    return sessions;
  }

  /// Get unique account IDs from events
  static Set<String> getUniqueAccounts(List<UserJourneyEvent> events) {
    return events
        .where((e) => e.accountId != null && e.accountId!.isNotEmpty)
        .map((e) => e.accountId!)
        .toSet();
  }

  // ─── Private helpers ───────────────────────────────────────────────

  static UserJourneyEvent? _parseLogEntry(ReportLogEntry log) {
    final msg = log.message;
    final timestamp = log.genTime!;

    // Try native-style log first
    final nativeMatch = _nativeLogPattern.firstMatch(msg);
    if (nativeMatch != null) {
      return _parseNativeLog(nativeMatch, log, timestamp);
    }

    // Try Flutter-style embedded JSON log
    if (msg.contains('[Info]') ||
        msg.contains('[Error]') ||
        msg.contains('[Warning]')) {
      return _parseFlutterLog(msg, log, timestamp);
    }

    // Fallback: still create an event for errors
    if (log.level == LogLevel.error) {
      return UserJourneyEvent(
        timestamp: timestamp,
        type: JourneyEventType.error,
        appState: AppState.unknown,
        component: 'Unknown',
        action: 'Error',
        details: _cleanMessage(msg),
        accountId: log.accountId,
        logLevel: log.level,
      );
    }

    return null;
  }

  static UserJourneyEvent _parseNativeLog(
    RegExpMatch match,
    ReportLogEntry log,
    DateTime timestamp,
  ) {
    final state = match.group(3) ?? '';
    final component = match.group(5)?.trim() ?? '';
    final tag = match.group(6)?.trim() ?? '';
    final body = match.group(7)?.trim() ?? '';

    final appState = _parseAppState(state);
    final type = _classifyEvent(component, tag, body, log.level);
    final action = _extractAction(component, tag, body, type);

    return UserJourneyEvent(
      timestamp: timestamp,
      type: type,
      appState: appState,
      component: component.isNotEmpty ? component : tag,
      action: action,
      details: _cleanMessage(body),
      accountId: log.accountId,
      logLevel: log.level,
    );
  }

  static UserJourneyEvent? _parseFlutterLog(
    String msg,
    ReportLogEntry log,
    DateTime timestamp,
  ) {
    // Extract the inner message from JSON wrapper
    String innerMsg = msg;
    if (msg.startsWith('{') && msg.contains('"message"')) {
      try {
        // Try to extract message field value via simple string ops
        final msgStart = msg.indexOf('"message":"');
        if (msgStart != -1) {
          final contentStart = msgStart + 11;
          // Find the matching closing quote (handle escaped quotes)
          var end = contentStart;
          while (end < msg.length) {
            if (msg[end] == '"' && (end == 0 || msg[end - 1] != '\\')) break;
            end++;
          }
          innerMsg = msg.substring(contentStart, end);
        }
      } catch (_) {}
    }

    // Remove ANSI escape codes
    innerMsg = innerMsg.replaceAll(RegExp(r'\\u001b\[\d+m'), '');

    // Parse the structure: [version] [date] [Level] [tag] [component] message
    String component = '';
    String tag = '';
    String body = innerMsg;
    AppState appState = AppState.unknown;

    // Extract tag and component from brackets
    final bracketParts = RegExp(r'\[([^\]]*)\]').allMatches(innerMsg).toList();
    if (bracketParts.length >= 4) {
      // Skip version and date brackets, level bracket
      // Look for tag and component
      for (int i = 3; i < bracketParts.length; i++) {
        final val = bracketParts[i].group(1) ?? '';
        if (val == 'FOREGROUND' || val == 'Background') {
          appState = val == 'FOREGROUND'
              ? AppState.foreground
              : AppState.background;
        } else if (tag.isEmpty) {
          tag = val;
        } else if (component.isEmpty) {
          component = val;
        }
      }
      // Body is everything after the last bracket
      final lastBracket = bracketParts.last;
      body = innerMsg.substring(lastBracket.end).trim();
    }

    if (component.isEmpty) component = tag;

    final type = _classifyEvent(component, tag, body, log.level);
    final action = _extractAction(component, tag, body, type);

    // Filter out very noisy/uninteresting events
    if (_isNoiseEvent(component, tag, body)) return null;

    return UserJourneyEvent(
      timestamp: timestamp,
      type: type,
      appState: appState,
      component: component,
      action: action,
      details: _cleanMessage(body.isNotEmpty ? body : innerMsg),
      accountId: log.accountId,
      logLevel: log.level,
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

    // App lifecycle events
    if (lc.contains('splash') ||
        lt.contains('app') ||
        lc.contains('_appstate')) {
      return JourneyEventType.appLifecycle;
    }
    if (lb.contains('init app complete') ||
        lb.contains('splash complete') ||
        lb.contains('app initialized') ||
        lb.contains('app resumed')) {
      return JourneyEventType.appLifecycle;
    }

    // Screen navigation
    if (lc.contains('screen') || lc.contains('page') || lc.contains('widget')) {
      return JourneyEventType.screen;
    }

    // Network
    if (lc.contains('network') ||
        lc.contains('appservices') ||
        lt.contains('lite_mode') ||
        lb.contains('network status') ||
        lb.contains('connectivity')) {
      return JourneyEventType.network;
    }

    // Notifications
    if (lc.contains('notification') || lc.contains('firebase')) {
      return JourneyEventType.notification;
    }

    // Features (BLE, auto-sync, measurement, device alert, etc.)
    if (lt.contains('auto_sync') ||
        lt.contains('device_alert') ||
        lc.contains('ble') ||
        lc.contains('bluetooth') ||
        lc.contains('measurement') ||
        lc.contains('liveactivity') ||
        lc.contains('devicerepository') ||
        lc.contains('autosync') ||
        lc.contains('devicechannel') ||
        lc.contains('abnormal') ||
        lc.contains('sipservice') ||
        lc.contains('audioservice')) {
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

    // App lifecycle actions
    if (lb.contains('init app complete')) return 'App Init Complete';
    if (lb.contains('splash complete')) return 'Splash Complete';
    if (lb.contains('app initialized')) return 'App Initialized';
    if (lb.contains('user authenticated')) return 'User Authenticated';
    if (lb.contains('listener triggered')) return 'State Changed';
    if (lb.contains('checking network')) return 'Checking Network';
    if (lb.contains('checking lite mode')) return 'Checking Lite Mode';
    if (lb.contains('server heartbeat')) return 'Server Heartbeat';
    if (lb.contains('cgm connection')) return 'CGM Connection Check';
    if (lb.contains('all checks completed')) return 'All Checks Complete';
    if (lb.contains('finalstate=')) return 'Final State Determined';
    if (lb.contains('appfirstload')) return 'First Load';

    // Feature actions
    if (lb.contains('start auto sync')) return 'Auto Sync Started';
    if (lb.contains('stop ble services')) return 'BLE Stopped';
    if (lb.contains('start scanning')) return 'BLE Scanning';
    if (lb.contains('fetched managed device')) return 'Devices Fetched';
    if (lb.contains('start live activity')) return 'Live Activity Started';
    if (lb.contains('stop sync timer')) return 'Sync Timer Stopped';
    if (lb.contains('sync timer triggered')) return 'Sync Timer Triggered';
    if (lb.contains('health check') || lb.contains('healthcheck'))
      return 'Health Check';
    if (lb.contains('start tracking')) return 'Tracking Started';
    if (lb.contains('startbackgroundsync')) return 'Background Sync Started';
    if (lb.contains('stopbackgroundsync')) return 'Background Sync Stopped';
    if (lb.contains('detect') && lb.contains('missing records'))
      return 'Missing Records Detected';
    if (lb.contains('sync measurement')) return 'Data Synced to Server';
    if (lb.contains('abnormal')) return 'Abnormal Data Detected';
    if (lb.contains('outofmemory')) return 'Out of Memory';

    // Notification actions
    if (lb.contains('message received')) return 'Push Received';
    if (lb.contains('trigger ble service from silent'))
      return 'Silent Push → BLE Sync';
    if (lb.contains('restart auto-sync')) return 'Restart Auto-Sync';

    // Network actions
    if (lb.contains('network status') || lb.contains('network details'))
      return 'Network Status';
    if (lb.contains('server heartbeat: ok')) return 'Server OK';
    if (lb.contains('app configs fetched')) return 'Config Fetched';

    // Error actions
    if (type == JourneyEventType.error) {
      if (lb.contains('outofmemory')) return 'OOM Error';
      if (lb.contains('oom_error')) return 'OOM Error';
      if (lb.contains('platformexception')) return 'Platform Exception';
      if (lb.contains('gatt')) return 'GATT Error';
      return 'Error';
    }

    // Generic
    if (lb.contains('started') || lb.contains('start')) return 'Started';
    if (lb.contains('stopped') || lb.contains('stop')) return 'Stopped';
    if (lb.contains('done') || lb.contains('complete')) return 'Completed';

    // Truncate body for short label
    if (body.length > 50) return body.substring(0, 47) + '...';
    return body.isEmpty ? component : body;
  }

  static bool _isNoiseEvent(String component, String tag, String body) {
    final lb = body.toLowerCase();
    // Filter out very repetitive health-check logs that don't add journey info
    // Keep only the first occurrence per session (handled at grouping level)
    // Also filter out pure config/remote-config noise
    if (lb.contains('initializing firebase remote configs') &&
        !lb.contains('done')) {
      return true;
    }
    if (lb.contains('server connection monitor already running')) return true;
    if (lb.contains('server connection check') && lb.contains('waiting for'))
      return true;
    if (lb.contains('checkandupdatestate') && !lb.contains('start'))
      return true;
    if (lb.contains('checkandreloadforlanguagechange')) return true;
    if (lb.contains('firebase lite mode:')) return true;
    if (lb.contains('user manual lite mode:')) return true;
    if (lb.contains('litemode state changed')) return true;
    if (lb.contains('state: connected - restarting')) return true;
    if (lb.contains('appconnection state transition')) return true;
    if (lb.contains('firebase configs:')) return true;
    return false;
  }

  static bool _isAppRestartEvent(UserJourneyEvent event) {
    final lb = event.details.toLowerCase();
    return lb.contains('init app complete') ||
        lb.contains('appfirstload') ||
        (event.component.contains('Splash') &&
            lb.contains('listener triggered'));
  }

  static String _cleanMessage(String msg) {
    // Remove ANSI escape codes
    msg = msg.replaceAll(RegExp(r'\\u001b\[\d+m'), '');
    // Remove excessive whitespace
    msg = msg.replaceAll(RegExp(r'\s+'), ' ').trim();
    return msg;
  }

  static UserJourneySession _buildSession(List<UserJourneyEvent> events) {
    int errors = 0;
    int warnings = 0;
    for (final e in events) {
      if (e.logLevel == LogLevel.error) errors++;
      if (e.logLevel == LogLevel.warning) warnings++;
    }
    return UserJourneySession(
      accountId: events
          .firstWhere(
            (e) => e.accountId != null && e.accountId!.isNotEmpty,
            orElse: () => events.first,
          )
          .accountId,
      startTime: events.first.timestamp,
      endTime: events.last.timestamp,
      events: events,
      errorCount: errors,
      warningCount: warnings,
    );
  }
}
