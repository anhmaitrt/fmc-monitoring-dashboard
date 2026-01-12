import 'package:csv/csv.dart';

class IssueExportRow {
  final String phone;
  final String name;
  final String priority;
  final String issue;

  IssueExportRow({
    required this.phone,
    required this.name,
    required this.priority,
    required this.issue,
  });

  String buildCsv(List<IssueExportRow> rows) {
    final data = <List<String>>[
      // Header
      ['SDT', 'Tên khách', 'Độ ưu tiên', 'Vấn đề'],
    ];

    for (final r in rows) {
      data.add([
        r.phone,
        r.name,
        r.priority,
        r.issue,
      ]);
    }

    return const ListToCsvConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      eol: '\n',
    ).convert(data);
  }

}
