/// Priority levels for sync issues
enum IssuePriority {
  normal,
  medium,
  high,
  critical;

  /// Build priority from interruption percentage
  factory IssuePriority.fromHour(double hour) {
    if (hour >= 12) return IssuePriority.critical;
    if (hour >= 5) return IssuePriority.high;
    if (hour >= 1) return IssuePriority.medium;
    return IssuePriority.normal;
  }
}

extension IssuePriorityX on IssuePriority {
  /// Vietnamese label (for UI / CSV)
  String get label {
    switch (this) {
      case IssuePriority.normal:
        return 'Bình thường';
      case IssuePriority.medium:
        return 'Trung bình';
      case IssuePriority.high:
        return 'Cao';
      case IssuePriority.critical:
        return 'Nguy hiểm';
    }
  }

  /// Rank for sorting (higher = more serious)
  int get rank {
    switch (this) {
      case IssuePriority.normal:
        return 1;
      case IssuePriority.medium:
        return 2;
      case IssuePriority.high:
        return 3;
      case IssuePriority.critical:
        return 4;
    }
  }
}

extension IssuePriorityParseX on String {
  /// Parse Vietnamese label back to enum (useful when reading CSV)
  IssuePriority toIssuePriority() {
    switch (trim()) {
      case 'Nguy hiểm':
        return IssuePriority.critical;
      case 'Cao':
        return IssuePriority.high;
      case 'Trung bình':
        return IssuePriority.medium;
      case 'Bình thường':
      default:
        return IssuePriority.normal;
    }
  }
}
