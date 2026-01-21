import 'package:csv/csv.dart';
import 'issue_priority.dart';

class IssueExportRow {
  IssueExportRow({
    required this.phone,
    required this.name,
    required this.priority,
    required this.issue,
    required this.totalHourInterruption,
    required this.isVIP,
    required this.note,
  });

  final String phone;
  final String name;
  final IssuePriority priority;
  final String issue;
  final double totalHourInterruption;
  final bool isVIP;
  final String? note;
}

extension EIssueExportRow on IssueExportRow {
  List<String> toCsvRow() {
    return [
      phone,
      name,
      priority.label,
      if (isVIP) 'VIP' else '',
      note ?? '',
      issue,
    ];
  }
}
