import 'package:flutter/material.dart';

import 'log_report_model.dart';

/// The type/category of a journey event
enum JourneyEventType {
  appLifecycle, // App open, splash, foreground/background transitions
  screen, // Screen navigation events
  feature, // Feature usage (auto-sync, BLE, live activity, etc.)
  error, // Errors and crashes
  network, // Network status changes
  notification, // Push notifications
  unknown;

  String get displayName {
    switch (this) {
      case JourneyEventType.appLifecycle:
        return 'App Lifecycle';
      case JourneyEventType.screen:
        return 'Screen';
      case JourneyEventType.feature:
        return 'Feature';
      case JourneyEventType.error:
        return 'Error';
      case JourneyEventType.network:
        return 'Network';
      case JourneyEventType.notification:
        return 'Notification';
      case JourneyEventType.unknown:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case JourneyEventType.appLifecycle:
        return '📱';
      case JourneyEventType.screen:
        return '🖥️';
      case JourneyEventType.feature:
        return '⚙️';
      case JourneyEventType.error:
        return '🔴';
      case JourneyEventType.network:
        return '🌐';
      case JourneyEventType.notification:
        return '🔔';
      case JourneyEventType.unknown:
        return '📝';
    }
  }
}

extension JourneyEventTypeUI on JourneyEventType {
  Color get color {
    switch (this) {
      case JourneyEventType.appLifecycle:
        return Colors.blue;
      case JourneyEventType.screen:
        return Colors.purple;
      case JourneyEventType.feature:
        return Colors.teal;
      case JourneyEventType.error:
        return Colors.red;
      case JourneyEventType.network:
        return Colors.cyan;
      case JourneyEventType.notification:
        return Colors.amber.shade700;
      case JourneyEventType.unknown:
        return Colors.grey;
    }
  }
}

/// Represents the app's foreground/background state
enum AppState {
  foreground,
  background,
  unknown;

  String get displayName {
    switch (this) {
      case AppState.foreground:
        return 'Foreground';
      case AppState.background:
        return 'Background';
      case AppState.unknown:
        return 'Unknown';
    }
  }
}

/// A single parsed event in the user's journey through the app
class UserJourneyEvent {
  UserJourneyEvent({
    required this.timestamp,
    required this.type,
    required this.appState,
    required this.component,
    required this.action,
    required this.details,
    required this.logLevel,
    this.accountId,
    this.layer,
    this.tag,
  });

  final DateTime timestamp;
  final JourneyEventType type;
  final AppState appState;
  final String component;
  final String action;
  final String details;
  final String? accountId;
  final LogLevel logLevel;

  /// The source layer: "Native" or "Flutter"
  final String? layer;

  /// The event tag/category (e.g. "auto_sync", "app", "other")
  final String? tag;
}

extension UserJourneyEventUI on UserJourneyEvent {
  IconData get lifecycleIcon {
    final act = action.toLowerCase();
    if (act.contains('splash') ||
        act.contains('open') ||
        act.contains('started') ||
        act.contains('init complete') ||
        act.contains('first load')) {
      return Icons.power_settings_new_rounded;
    }
    if (act.contains('backgrounded') || act.contains('background')) {
      return Icons.minimize_rounded;
    }
    if (act.contains('resumed') || act.contains('foreground')) {
      return Icons.flip_to_front_rounded;
    }
    if (act.contains('detached')) {
      return Icons.close_rounded;
    }
    if (appState == AppState.background) return Icons.minimize_rounded;
    if (appState == AppState.foreground) {
      return Icons.flip_to_front_rounded;
    }
    return Icons.circle;
  }
}

/// A major lifecycle node on the main timeline bone (e.g. App Killed, App Opened, Background, Foreground)
/// Contains all secondary events that occurred while in this state.
class JourneyNode {
  JourneyNode({
    required this.startTime,
    required this.mainStateEvent,
    this.endTime,
    List<UserJourneyEvent>? events,
  }) : events = events ?? [];

  /// The timestamp this lifecycle state started
  final DateTime startTime;

  /// The timestamp this lifecycle state ended (moved to next state), if known
  DateTime? endTime;

  /// The primary event that triggered this node (e.g., App Open, App Background)
  final UserJourneyEvent mainStateEvent;

  /// All secondary events (syncs, screens, errors) that happened during this lifecycle state
  final List<UserJourneyEvent> events;

  /// Duration of this lifecycle state
  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  int get errorCount =>
      events.where((e) => e.logLevel == LogLevel.error).length +
      (mainStateEvent.logLevel == LogLevel.error ? 1 : 0);

  int get warningCount =>
      events.where((e) => e.logLevel == LogLevel.warning).length +
      (mainStateEvent.logLevel == LogLevel.warning ? 1 : 0);
}
