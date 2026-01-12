import 'package:csv/csv.dart';
import 'package:fmc_monitoring_dashboard/model/export/issue_priority.dart';

class IssueExportRow {
  final String phone;
  final String name;
  final IssuePriority priority;
  final String issue;

  IssueExportRow({
    required this.phone,
    required this.name,
    required this.priority,
    required this.issue,
  });

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
