import 'package:csv/csv.dart';
import 'issue_priority.dart';

class IssueExportRow {
  IssueExportRow({
    required this.phone,
    required this.name,
    required this.priority,
    required this.issue,
    required this.avgPercent,
  });

  final String phone;
  final String name;
  final IssuePriority priority;
  final String issue;
  final double avgPercent;
}

extension EIssueExportRow on IssueExportRow {
  List<String> toCsvRow() {
    return [
      phone,
      name,
      priority.label,
      issue,
    ];
  }
}
