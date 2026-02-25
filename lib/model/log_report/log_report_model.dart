/// Statistics model for log report analysis
class LogReportStats {
  final int totalLogs;
  final Set<String> uniqueUsers;
  final DateTime? earliestLog;
  final DateTime? latestLog;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final int autoSyncCount;
  final int gattErrorCount;
  final int syncOnTimeCount;
  final int syncNotOnTimeCount;
  final Map<String, int> logsByHour; // for timeline chart

  LogReportStats({
    required this.totalLogs,
    required this.uniqueUsers,
    this.earliestLog,
    this.latestLog,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
    required this.autoSyncCount,
    required this.gattErrorCount,
    required this.syncOnTimeCount,
    required this.syncNotOnTimeCount,
    required this.logsByHour,
  });

  factory LogReportStats.empty() => LogReportStats(
        totalLogs: 0,
        uniqueUsers: {},
        errorCount: 0,
        warningCount: 0,
        infoCount: 0,
        autoSyncCount: 0,
        gattErrorCount: 0,
        syncOnTimeCount: 0,
        syncNotOnTimeCount: 0,
        logsByHour: {},
      );
}

/// Single parsed log entry for report display
class ReportLogEntry {
  final String? userId;
  final String? accountId;
  final DateTime? timestamp;
  final DateTime? genTime;
  final String message;
  final LogLevel level;
  final String? deviceModel;
  final String? platform;

  ReportLogEntry({
    this.userId,
    this.accountId,
    this.timestamp,
    this.genTime,
    required this.message,
    required this.level,
    this.deviceModel,
    this.platform,
  });
}

enum LogLevel {
  info,
  warning,
  error;

  String get displayName {
    switch (this) {
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
    }
  }
}
