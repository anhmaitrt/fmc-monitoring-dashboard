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