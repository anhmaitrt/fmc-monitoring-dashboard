import 'dart:convert';
import 'dart:html' as html;

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../../../model/export/issue_export_row.dart';
import '../../utils/extension/date_extension.dart';

class FileService {
    FileService._();

    static FileService instance = FileService._();

    Future<void> exportCsv(
        List<IssueExportRow> rows, {
          String? dateRange,
          DateTime? startTime,
          DateTime? endTime,
        }) async {
      final csv = buildCsv(rows);

      String _two(int v) => v.toString().padLeft(2, '0');

      final now = DateTime.now();
      String fileName = '';

      if (dateRange != null && dateRange.trim().isNotEmpty) {
        final safeRange = sanitizeFileName(dateRange); // ✅ sanitize here
        fileName = 'issues_${safeRange.toLowerCase()}.csv';
      } else if (startTime != null && endTime != null) {
        fileName = 'cham_dong_bo_${startTime.onlyDDMMYYYY()}-${endTime.onlyDDMMYYYY()}.csv';
      } else {
        fileName =
        'issues_${now.year}-${_two(now.month)}-${_two(now.day)}_${_two(now.hour)}${_two(now.minute)}${_two(now.second)}.csv';
      }

      if (kIsWeb) {
        downloadCsvWeb(csv, fileName: fileName);
      }
    }

    String sanitizeFileName(String input) {
      // Windows + common browser restrictions
      const forbidden = r'<>:"/\|?*';
      var out = input;
      for (final ch in forbidden.split('')) {
        out = out.replaceAll(ch, '-');
      }
      out = out.replaceAll(RegExp(r'\s+'), ' ').trim(); // normalize spaces
      return out;
    }

    // label example: "16:00 20/01/26_21:00 21/01/26"
    String buildIssuesFileNameFromLabel(String label) {
      final safe = sanitizeFileName(label);
      return 'issues_$safe.csv';
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
        ['SDT', 'Tên khách', 'Độ ưu tiên', 'Hạng', 'Note', 'Vấn đề'],
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