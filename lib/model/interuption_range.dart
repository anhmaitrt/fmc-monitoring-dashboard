import 'package:fmc_monitoring_dashboard/model/user_cgm_data_row.dart';

import '../core/services/settings/settings.dart';

enum InterruptionRange {
  lt20, gte20, gte50, gte80, x;

  factory InterruptionRange.fromPercent(double percent) {
    if (percent < 20) return InterruptionRange.lt20;
    if (percent < 50) return InterruptionRange.gte20;
    if (percent < 80) return InterruptionRange.gte50;
    if(percent >= 99.93 && percent <= 99.99 && Settings.filterStopSync) return InterruptionRange.x;
    return InterruptionRange.gte80;
  }
}

extension InterruptionRangeUI on InterruptionRange {
  String get label {
    switch (this) {
      case InterruptionRange.lt20:
        return '<20%';
      case InterruptionRange.gte20:
        return '≥20%';
      case InterruptionRange.gte50:
        return '≥50%';
      case InterruptionRange.gte80:
        return '≥80%';
      case InterruptionRange.x:
        return 'Ngưng đồng bộ';
    }
  }
}

extension EUserCGMFileRange on UserCGMDataRow {
  bool get _isX {
    final p = interruptionPercentage;
    if (p == null) return true;
    if (!p.isFinite) return true;
    return p >= 100; // <-- adjust if your "X" definition differs
  }

  InterruptionRange get interruptionRange {
    final p = interruptionPercentage;
    if (_isX) return InterruptionRange.x;
    if (p == null) return InterruptionRange.x;
    if (p >= 80) return InterruptionRange.gte80;
    if (p >= 50) return InterruptionRange.gte50;
    if (p >= 20) return InterruptionRange.gte20;
    return InterruptionRange.lt20;
  }
}

extension EListUserCGMFileRange on List<UserCGMDataRow> {
  List<UserCGMDataRow> filterByRange(InterruptionRange? range) {
    if (range == null) return this;
    return where((e) => e.interruptionRange == range).toList();
  }
}
