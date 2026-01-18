import 'dart:convert';

import 'package:fmc_monitoring_dashboard/model/log/log_file.dart';

class CSVLogModel {
  final String? userId;
  final String? createdAt;
  final LogEntry? log;

  CSVLogModel({
    required this.userId,
    required this.createdAt,
    required this.log,
  });

  DateTime? get genTime => log?.genDateTime;
  String? get message => log?.message;
}

extension EListCSVLogModel on List<CSVLogModel> {
  /// Return a NEW list sorted by genTime desc (latest first).
  List<CSVLogModel> sortedByGenTimeDesc() {
    final copy = [...this];
    copy.sort((a, b) {
      final da = a.genTime;
      final db = b.genTime;
      if (da == null && db == null) return 0;
      if (da == null) return 1; // null goes last
      if (db == null) return -1;
      return db.compareTo(da); // DESC
    });
    return copy;
  }

  /// Latest log (by genTime). Null if list empty.
  CSVLogModel? latest() => sortedByGenTimeDesc().firstOrNull;

  /// Find latest log whose JSON string matches [predicate] and return parsed Map.
  Map<String, dynamic>? _latestJsonWhere(
      bool Function(String rawJson) predicate, {
        int maxScan = 500,
      }) {
    final sorted = sortedByGenTimeDesc();
    final limit = maxScan.clamp(0, sorted.length);

    for (int i = 0; i < limit; i++) {
      final raw = sorted[i].message; // <- your JSON string
      if (raw == null || raw.isEmpty) continue;
      if (!predicate(raw)) continue;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // ignore bad JSON row
      }
    }
    return null;
  }

  /// Use this if you want only logs with tag auto_sync (based on JSON content)
  Map<String, dynamic>? _latestAutoSyncJson({int maxScan = 500}) {
    return _latestJsonWhere(
          (raw) => raw.contains('"tag":"auto_sync"') || raw.contains('"logType":"auto_sync"'),
      maxScan: maxScan,
    );
  }

  String? extractDeviceModelLatest({int maxScan = 500}) {
    final json = _latestAutoSyncJson(maxScan: maxScan);
    if (json == null) return null;

    final info = json['info'];
    if (info is! Map) return null;
    final device = info['device'];
    if (device is! Map) return null;

    return device['model']?.toString(); // e.g. iPhone16,2
  }

  String? extractPlatformVersionLatest({int maxScan = 500}) {
    final json = _latestAutoSyncJson(maxScan: maxScan);
    if (json == null) return null;

    final device = (json['info'] as Map?)?['device'] as Map?;
    if (device == null) return null;

    final platform = device['platform']?.toString();
    final version = device['version'] as Map?;
    if (version == null) return null;

    if (platform == 'android') {
      final release = version['release']?.toString(); // "14"
      final sdkInt = version['sdkInt']?.toString();   // "34"
      if (release == null) return null;
      return 'Android $release (SDK $sdkInt)';
    }

    // ios
    return version['version']?.toString(); // Darwin Kernel Version ...
  }

  String? extractAppVersionLatest({int maxScan = 500}) {
    final json = _latestAutoSyncJson(maxScan: maxScan);
    if (json == null) return null;

    final msg = json['message']?.toString() ?? '';
    // message starts with: [3.6.3] ...
    final m = RegExp(r'^\s*\[([0-9]+(?:\.[0-9]+){1,3})\]').firstMatch(msg);
    // print('Getting app version ${m?.group(1)}: $msg');
    return m?.group(1); // 3.6.3
  }

  Map<String, List<CSVLogModel>> groupLogsByUserId() {
    final map = <String, List<CSVLogModel>>{};
    for (final l in this) {
      final uid = l.userId;
      if (uid == null || uid.isEmpty) continue;
      (map[uid] ??= <CSVLogModel>[]).add(l);
    }

    // Optional: sort logs newest first if you have a parseable createdAt
    // map.forEach((k, v) => v.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? '')));

    return map;
  }
}
