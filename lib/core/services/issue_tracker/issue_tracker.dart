import '../../../model/log/csv_log_model.dart';

/// Your sync progress states parsed from HealthCheck log text.
enum SyncProgress {
  scanning,
  connecting,
  connected,
  syncing,
  idle,
  disconnected,
  unknown,
}

extension ESyncProgress on SyncProgress {
  bool get isSuccess =>
      this == SyncProgress.connected ||
          this == SyncProgress.syncing ||
          this == SyncProgress.idle;
}

SyncProgress _parseProgress(String raw) {
  final s = raw.trim().toUpperCase();
  switch (s) {
    case 'SCANNING':
      return SyncProgress.scanning;
    case 'CONNECTING':
      return SyncProgress.connecting;
    case 'CONNECTED':
      return SyncProgress.connected;
    case 'SYNCING':
      return SyncProgress.syncing;
    case 'IDLE':
      return SyncProgress.idle;
    case 'DISCONNECTED':
      return SyncProgress.disconnected;
    default:
      return SyncProgress.unknown;
  }
}

/// One parsed snapshot from a HealthCheck message
class SyncEvent {
  final String userId;
  final DateTime time;

  /// SN9640000xxx (if found)
  final String? deviceSn;

  final SyncProgress progress;

  /// true if snapshot contains an error
  final bool hasError;

  /// e.g. 133, 147, ... or null if not detected
  final int? errorCode;

  /// raw error string after "Error:"
  final String? errorText;

  /// keep message for debug
  final String? rawMessage;

  SyncEvent({
    required this.userId,
    required this.time,
    required this.progress,
    required this.hasError,
    this.deviceSn,
    this.errorCode,
    this.errorText,
    this.rawMessage,
  });

  bool get isError => hasError;

  /// ✅ "Recovered success" snapshot:
  /// - progress is success (CONNECTED / SYNCING / IDLE)
  /// - and snapshot has NO error
  bool get isOkSnapshot => progress.isSuccess && !hasError;
}

/// Incident: one error and whether it later recovered within window
class ErrorIncident {
  final String userId;
  final String? deviceSn;

  final DateTime errorAt;
  final int? errorCode;
  final String? errorText;

  final bool recovered;
  final DateTime? recoveredAt;
  final SyncProgress? recoveredTo;

  ErrorIncident({
    required this.userId,
    required this.errorAt,
    required this.recovered,
    this.deviceSn,
    this.errorCode,
    this.errorText,
    this.recoveredAt,
    this.recoveredTo,
  });

  Duration? get recoveryTime =>
      (recovered && recoveredAt != null) ? recoveredAt!.difference(errorAt) : null;
}

class UserRecoverySummary {
  final String userId;
  final int totalErrors;
  final int recoveredCount;
  final double recoveredRate; // 0..1
  final Duration? avgRecoveryTime;
  final ErrorIncident? latestError;

  UserRecoverySummary({
    required this.userId,
    required this.totalErrors,
    required this.recoveredCount,
    required this.recoveredRate,
    required this.avgRecoveryTime,
    required this.latestError,
  });

  @override
  String toString() =>
      'UserRecoverySummary(userId=$userId, totalErrors=$totalErrors, recovered=$recoveredCount, rate=${(recoveredRate * 100).toStringAsFixed(0)}%)';
}

class IssueTracker {
  IssueTracker._();
  static final instance = IssueTracker._();

  // =========================
  // 1) PARSER
  // =========================
  SyncEvent? tryParseSyncEventFromHealthCheck(CSVLogModel row) {
    final uid = row.userId;
    final t = row.genTime;
    final msg = row.message;

    if (uid == null || t == null || msg == null) return null;

    // only HealthCheck snapshots that include device block
    if (!msg.contains('[HealthCheck]') || !msg.contains('=== Device')) return null;

    String? firstGroup(RegExp r, {int group = 1}) =>
        r.firstMatch(msg)?.group(group)?.trim();

    // === Device SN96400002471's Health:
    final deviceSn = firstGroup(RegExp(r'===\s*Device\s+(SN[0-9A-Za-z]+)'));

    // Progress: CONNECTING
    final progressStr = firstGroup(
      RegExp(r'(^|\n)Progress:\s*([A-Z_]+)', multiLine: true),
      group: 2,
    ) ??
        firstGroup(RegExp(r'Progress:\s*([A-Z_]+)'), group: 1);

    final progress = _parseProgress(progressStr ?? '');

    // Error: null   OR   Error: [SN...] Connect error: ... status=133
    final errorLine = firstGroup(
      RegExp(r'(^|\n)Error:\s*([^\n]+)', multiLine: true),
      group: 2,
    );

    final errorText = (errorLine == null || errorLine == 'null') ? null : errorLine;

    // status=133 / status=147 ...
    final codeStr = firstGroup(RegExp(r'status=(\d+)'), group: 1) ??
        firstGroup(RegExp(r'code=(\d+)'), group: 1);

    final errorCode = codeStr == null ? null : int.tryParse(codeStr);

    // timeout detection (when no status=)
    final isTimeout = msg.toLowerCase().contains('timeout');
    final finalErrorText = errorText ?? (isTimeout ? 'timeout' : null);

    final hasError = (finalErrorText != null) || (errorCode != null);

    return SyncEvent(
      userId: uid,
      time: t,
      progress: progress,
      hasError: hasError,
      deviceSn: deviceSn,
      errorText: finalErrorText,
      errorCode: errorCode,
      rawMessage: msg, // optional but useful for debugging
    );
  }

  // =========================
  // 2) ANALYZE: ERROR -> RECOVERED?
  // =========================
  List<ErrorIncident> analyzeRecoveryForAllUsers(
      List<CSVLogModel> logs, {
        Duration window = const Duration(minutes: 10),
      }) {
    // 1) Extract events
    final events = <SyncEvent>[];
    for (final r in logs) {
      final e = tryParseSyncEventFromHealthCheck(r);
      if (e != null) events.add(e);
    }

    // 2) Sort ASC timeline
    events.sort((a, b) => a.time.compareTo(b.time));

    // 3) Group by user + deviceSn (but if deviceSn missing => group by user only)
    String keyOf(SyncEvent e) {
      final sn = e.deviceSn;
      if (sn == null || sn.isEmpty || sn == 'unknown') return e.userId;
      return '${e.userId}__$sn';
    }

    final byKey = <String, List<SyncEvent>>{};
    for (final e in events) {
      (byKey[keyOf(e)] ??= []).add(e);
    }

    // 4) Scan timeline -> incidents
    final incidents = <ErrorIncident>[];

    for (final entry in byKey.entries) {
      final list = entry.value;

      for (int i = 0; i < list.length; i++) {
        final e = list[i];
        if (!e.isError) continue;

        final deadline = e.time.add(window);

        DateTime? recoveredAt;
        SyncProgress? recoveredTo;

        // ✅ recovery rule:
        // Error -> (SCANNING/CONNECTING/...) -> CONNECTED/SYNCING/IDLE (no error) => recovered
        for (int j = i + 1; j < list.length; j++) {
          final next = list[j];
          if (next.time.isAfter(deadline)) break;

          // ignore intermediate states
          if (!next.progress.isSuccess) continue;

          // must be a "clean" success snapshot
          if (next.isOkSnapshot) {
            recoveredAt = next.time;
            recoveredTo = next.progress;
            break;
          }
        }

        incidents.add(ErrorIncident(
          userId: e.userId,
          deviceSn: e.deviceSn,
          errorAt: e.time,
          errorCode: e.errorCode,
          errorText: e.errorText,
          recovered: recoveredAt != null,
          recoveredAt: recoveredAt,
          recoveredTo: recoveredTo,
        ));
      }
    }

    // Optional: newest first for UI
    incidents.sort((a, b) => b.errorAt.compareTo(a.errorAt));
    return incidents;
  }

  // =========================
  // 3) SUMMARY PER USER
  // =========================
  List<UserRecoverySummary> summarizeRecoveryByUser(List<ErrorIncident> incidents) {
    final byUser = <String, List<ErrorIncident>>{};
    for (final i in incidents) {
      (byUser[i.userId] ??= []).add(i);
    }

    final result = <UserRecoverySummary>[];

    byUser.forEach((userId, list) {
      final total = list.length;
      final recoveredList = list.where((i) => i.recovered).toList();
      final recoveredCount = recoveredList.length;

      final recoveredRate = total == 0 ? 0.0 : (recoveredCount / total);

      Duration? avgRecovery;
      if (recoveredList.isNotEmpty) {
        final durations = recoveredList
            .map((e) => e.recoveryTime)
            .whereType<Duration>()
            .toList();

        if (durations.isNotEmpty) {
          final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
          avgRecovery = Duration(milliseconds: (totalMs / durations.length).round());
        }
      }

      // latest error = max(errorAt)
      ErrorIncident? latest;
      for (final i in list) {
        if (latest == null || i.errorAt.isAfter(latest!.errorAt)) latest = i;
      }

      result.add(UserRecoverySummary(
        userId: userId,
        totalErrors: total,
        recoveredCount: recoveredCount,
        recoveredRate: recoveredRate,
        avgRecoveryTime: avgRecovery,
        latestError: latest,
      ));
    });

    // Sort: most severe first (more errors, lower recovery, latest errors)
    result.sort((a, b) {
      final c1 = b.totalErrors.compareTo(a.totalErrors);
      if (c1 != 0) return c1;

      final c2 = a.recoveredRate.compareTo(b.recoveredRate); // lower rate first
      if (c2 != 0) return c2;

      final ta = a.latestError?.errorAt;
      final tb = b.latestError?.errorAt;
      if (ta == null || tb == null) return 0;
      return tb.compareTo(ta);
    });

    return result;
  }
}

// Small helper (avoid importing collection helpers)
extension _Let<T> on T {
  R? let<R>(R Function(T) fn) => fn(this);
}