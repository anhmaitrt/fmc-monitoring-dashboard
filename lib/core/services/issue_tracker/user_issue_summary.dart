import 'issue_tracker.dart';

class UserRecoverySummary {
  final String userId;
  final int totalErrors;
  final int recoveredErrors;
  final double recoveredRate; // 0..1
  final Duration? avgRecoveryTime;
  final ErrorIncident? latestError;

  UserRecoverySummary({
    required this.userId,
    required this.totalErrors,
    required this.recoveredErrors,
    required this.recoveredRate,
    required this.avgRecoveryTime,
    required this.latestError,
  });
}

List<UserRecoverySummary> summarizeRecoveryByUser(List<ErrorIncident> incidents) {
  final byUser = <String, List<ErrorIncident>>{};
  for (final i in incidents) {
    (byUser[i.userId] ??= []).add(i);
  }

  final out = <UserRecoverySummary>[];
  byUser.forEach((uid, list) {
    list.sort((a, b) => b.errorAt.compareTo(a.errorAt));
    final total = list.length;
    final recovered = list.where((x) => x.recovered).length;

    final recoveredDurations = list
        .map((x) => x.recoveryTime)
        .whereType<Duration>()
        .toList();

    Duration? avg;
    if (recoveredDurations.isNotEmpty) {
      final sumMs = recoveredDurations
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a + b);
      avg = Duration(milliseconds: sumMs ~/ recoveredDurations.length);
    }

    out.add(UserRecoverySummary(
      userId: uid,
      totalErrors: total,
      recoveredErrors: recovered,
      recoveredRate: total == 0 ? 0 : recovered / total,
      avgRecoveryTime: avg,
      latestError: list.firstOrNull,
    ));
  });

  // worst users first (low recovered rate)
  out.sort((a, b) => a.recoveredRate.compareTo(b.recoveredRate));
  return out;
}
