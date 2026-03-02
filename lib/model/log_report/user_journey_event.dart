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
  });

  final DateTime timestamp;
  final JourneyEventType type;
  final AppState appState;
  final String component;
  final String action;
  final String details;
  final String? accountId;
  final LogLevel logLevel;
}

/// A complete user journey session (grouped block of events)
class UserJourneySession {
  UserJourneySession({
    required this.startTime,
    required this.endTime,
    required this.events,
    required this.errorCount,
    required this.warningCount,
    this.accountId,
  });

  final String? accountId;
  final DateTime startTime;
  final DateTime endTime;
  final List<UserJourneyEvent> events;
  final int errorCount;
  final int warningCount;

  Duration get duration => endTime.difference(startTime);
}
