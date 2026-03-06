import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../model/log_report/log_report_model.dart';

/// Parse CSV log file and return list of ReportLogEntry
/// This runs in isolate for performance with large files
Map<String, dynamic> parseLogCsvInIsolate(String content) {
  final converter = const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false,
  );

  int indexOfAny(List<String> header, List<String> keys) {
    final lowerKeys = keys.map((e) => e.toLowerCase()).toSet();
    return header.indexWhere((h) => lowerKeys.contains(h.toLowerCase()));
  }

  try {
    final rows = converter.convert(content);

    if (rows.isEmpty) {
      return {'error': 'File CSV rỗng.', 'logs': <Map<String, dynamic>>[]};
    }

    final header = rows.first.map((e) => e.toString().trim()).toList();

    final timestampIndex = indexOfAny(header, ['@timestamp', 'timestamp']);
    final requestBodyIndex = indexOfAny(header, [
      'request_body',
      'requestBody',
    ]);

    if (timestampIndex == -1 || requestBodyIndex == -1) {
      return {
        'error':
            'Không tìm thấy cột "timestamp/@timestamp" hoặc "request_body" trong header CSV.',
        'logs': <Map<String, dynamic>>[],
      };
    }

    final logs = <Map<String, dynamic>>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      if (row.length <= requestBodyIndex) continue;

      final timestampRaw = row[timestampIndex]?.toString() ?? '';
      final requestBodyRaw = row[requestBodyIndex]?.toString() ?? '';

      if (requestBodyRaw.isEmpty) continue;

      try {
        // Normalize double quotes in CSV
        final normalizedJson = requestBodyRaw.replaceAll('""', '"');
        final decoded = jsonDecode(normalizedJson);

        if (decoded is! Map<String, dynamic>) continue;

        final logsList = decoded['logs'];
        if (logsList is! List) continue;

        for (final item in logsList) {
          if (item is! Map<String, dynamic>) continue;

          final genTimeRaw = item['genTime'];
          final messageRaw = item['message'];

          if (genTimeRaw == null || messageRaw == null) continue;

          final genTime = int.tryParse(genTimeRaw.toString());
          if (genTime == null) continue;

          var message = messageRaw.toString();

          // Flutter logs arrive as JSON-wrapped messages:
          // {"message":"[3.7.2] [timestamp] [Level] ...", "accountId":"...", "info":{...}}
          // Unwrap to extract the inner message and metadata.
          String? accountId = decoded['accountId']?.toString();
          String? deviceModel;
          String? platform;

          try {
            if (message.startsWith('{')) {
              final msgJson = jsonDecode(message);
              // Extract the actual log message
              final innerMsg = msgJson['message'];
              if (innerMsg is String && innerMsg.isNotEmpty) {
                message = innerMsg;
              }
              // Extract accountId
              accountId ??= msgJson['accountId']?.toString();
              // Extract device info
              final info = msgJson['info'] as Map?;
              final device = info?['device'] as Map?;
              deviceModel = device?['model']?.toString();
              platform = device?['platform']?.toString();
            }
          } catch (_) {}

          // Determine log level from message content
          String level = 'info';
          if (message.contains('[Error]') || message.contains('🔴')) {
            level = 'error';
          } else if (message.contains('[Warning]') || message.contains('⚠️')) {
            level = 'warning';
          }

          logs.add({
            'timestamp': timestampRaw,
            'genTime': genTime,
            'message': message,
            'level': level,
            'accountId': accountId,
            'deviceModel': deviceModel,
            'platform': platform,
          });
        }
      } catch (_) {
        continue;
      }
    }

    return {'error': null, 'logs': logs};
  } catch (e) {
    return {'error': 'Lỗi parse CSV: $e', 'logs': <Map<String, dynamic>>[]};
  }
}

/// Convert parsed map data to ReportLogEntry objects
List<ReportLogEntry> convertToReportEntries(List<dynamic> rawLogs) {
  final dateFormats = [
    DateFormat("MMM d, yyyy '@' HH:mm:ss.SSS"),
    DateFormat("yyyy-MM-dd'T'HH:mm:ss"),
    DateFormat("yyyy-MM-dd HH:mm:ss"),
  ];

  DateTime? parseTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final fmt in dateFormats) {
      try {
        return fmt.parse(raw);
      } catch (_) {}
    }
    return null;
  }

  return rawLogs.map((m) {
    final map = m as Map<String, dynamic>;

    final genTimeMs = map['genTime'] as int;
    // Convert to DateTime (handle both seconds and milliseconds)
    final ms = genTimeMs < 1000000000000 ? genTimeMs * 1000 : genTimeMs;
    final genTime = DateTime.fromMillisecondsSinceEpoch(
      ms,
      isUtc: true,
    ).toLocal();

    LogLevel level;
    switch (map['level']) {
      case 'error':
        level = LogLevel.error;
        break;
      case 'warning':
        level = LogLevel.warning;
        break;
      default:
        level = LogLevel.info;
    }

    return ReportLogEntry(
      timestamp: parseTimestamp(map['timestamp']),
      genTime: genTime,
      message: map['message'] ?? '',
      level: level,
      accountId: map['accountId'],
      deviceModel: map['deviceModel'],
      platform: map['platform'],
    );
  }).toList();
}

/// Calculate statistics from log entries
LogReportStats calculateStats(List<ReportLogEntry> logs) {
  if (logs.isEmpty) return LogReportStats.empty();

  final uniqueUsers = <String>{};
  int errorCount = 0;
  int warningCount = 0;
  int infoCount = 0;
  int autoSyncCount = 0;
  int gattErrorCount = 0;
  int syncOnTimeCount = 0;
  int syncNotOnTimeCount = 0;
  DateTime? earliest;
  DateTime? latest;
  final logsByHour = <String, int>{};

  for (final log in logs) {
    // Unique users
    if (log.accountId != null && log.accountId!.isNotEmpty) {
      uniqueUsers.add(log.accountId!);
    }

    // Level counts
    switch (log.level) {
      case LogLevel.error:
        errorCount++;
        break;
      case LogLevel.warning:
        warningCount++;
        break;
      case LogLevel.info:
        infoCount++;
        break;
    }

    // Special patterns
    final msg = log.message.toLowerCase();
    if (msg.contains('auto_sync') || msg.contains('auto sync')) {
      autoSyncCount++;
    }
    if (msg.contains('gatt') && msg.contains('error') ||
        msg.contains('status=133') ||
        msg.contains('gattconnectexception')) {
      gattErrorCount++;
    }
    if (msg.contains('sync on time: true')) {
      syncOnTimeCount++;
    }
    if (msg.contains('sync on time: false')) {
      syncNotOnTimeCount++;
    }

    // Date range
    final dt = log.genTime;
    if (dt != null) {
      if (earliest == null || dt.isBefore(earliest)) earliest = dt;
      if (latest == null || dt.isAfter(latest)) latest = dt;

      // Group by hour for timeline
      final hourKey = DateFormat('yyyy-MM-dd HH:00').format(dt);
      logsByHour[hourKey] = (logsByHour[hourKey] ?? 0) + 1;
    }
  }

  return LogReportStats(
    totalLogs: logs.length,
    uniqueUsers: uniqueUsers,
    earliestLog: earliest,
    latestLog: latest,
    errorCount: errorCount,
    warningCount: warningCount,
    infoCount: infoCount,
    autoSyncCount: autoSyncCount,
    gattErrorCount: gattErrorCount,
    syncOnTimeCount: syncOnTimeCount,
    syncNotOnTimeCount: syncNotOnTimeCount,
    logsByHour: logsByHour,
  );
}
