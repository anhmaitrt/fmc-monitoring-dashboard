import 'dart:io';

import 'dart:html' as html;
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../model/export/issue_export_row.dart';

class FileService {
    FileService._();

    static FileService instance = FileService._();


    Future<void> exportCsv(List<IssueExportRow> rows) async {
      final csv = buildCsv(rows);

      String _two(int v) => v.toString().padLeft(2, '0');

      final now = DateTime.now();
      final fileName =
          'issues_${now.year}-${_two(now.month)}-${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}${_two(now.second)}.csv';

      if (kIsWeb) {
        downloadCsvWeb(csv, fileName: fileName);
      }/* else {
        await exportCsvMobile(csv);
      }*/
    }

    void downloadCsvWeb(String csvContent, {String fileName = 'export.csv'}) {
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();

      html.Url.revokeObjectUrl(url);
    }

    // Future<void> exportCsvMobile(String csvContent) async {
    //   final dir = await getTemporaryDirectory();
    //   final file = File('${dir.path}/fmc_monitoring_${DateTime.now().millisecondsSinceEpoch}.csv');
    //
    //   await file.writeAsString(csvContent, encoding: utf8);
    //
    //   await Share.shareXFiles(
    //     [XFile(file.path)],
    //     text: 'CSV Export',
    //   );
    // }

    String buildCsv(List<IssueExportRow> rows) {
      final data = <List<String>>[
        // Header
        ['SDT', 'Tên khách', 'Độ ưu tiên', 'Vấn đề'],
      ];

      for (final r in rows) {
        data.add(r.toCsvRow());
      }

      return const ListToCsvConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
      ).convert(data);
    }
}