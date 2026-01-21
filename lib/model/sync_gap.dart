import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/utils/extension/date_extension.dart';

@JsonSerializable()
class SyncGap {
  final String start;
  final String end;

  SyncGap({
    required this.start,
    required this.end,
  });

  factory SyncGap.fromJson(List<dynamic> json) {
    return SyncGap(
      start: json[0] as String,
      end: json[1] as String,
    );
  }

  List<String> toJson() => [start, end];

  @override
  String toString() => '$start - $end';

  String onlyHHMM() => '${start.onlyHHMM} - ${end.onlyHHMM}';

  Duration get duration => start.getGap(end);
}

extension ESyncGapFormat on SyncGap {
  String toCompactString() {
    final s = _parseHhmmDdMmYyyy(start);
    final e = _parseHhmmDdMmYyyy(end);

    if (s == null || e == null) {
      // fallback: giữ nguyên cách cũ nếu parse fail
      return toString();
    }

    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;

    final date = _ddMMyyyy(s);
    if (sameDay) {
      return '${_hhmm(s)} - ${_hhmm(e)} $date';
    }

    return '${_hhmm(s)} ${_ddMMyyyy(s)} - ${_hhmm(e)} ${_ddMMyyyy(e)}';
  }

  DateTime? _parseHhmmDdMmYyyy(String? input) {
    if (input == null) return null;

    // Matches: "00:00 21/01/2026" or "00:00:30 21/01/2026"
    final m = RegExp(
      r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s+(\d{1,2})/(\d{1,2})/(\d{4})',
    ).firstMatch(input.trim());

    if (m == null) return null;

    final hh = int.tryParse(m.group(1)!);
    final mm = int.tryParse(m.group(2)!);
    final ss = int.tryParse(m.group(3) ?? '0');
    final dd = int.tryParse(m.group(4)!);
    final mo = int.tryParse(m.group(5)!);
    final yy = int.tryParse(m.group(6)!);

    if ([hh, mm, ss, dd, mo, yy].any((v) => v == null)) return null;

    return DateTime(yy!, mo!, dd!, hh!, mm!, ss!);
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _hhmm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  String _ddMMyyyy(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
}


extension ESyncGapListSimple on List<SyncGap> {
  String summarizeSimple({int? maxItems}) {
    if (isEmpty) return 'Ổn định';

    final total = length;
    final show = (maxItems == null) ? this : take(maxItems).toList();

    final sb = StringBuffer();
    sb.writeln('$total khoảng chậm:');

    for (final g in show) {
      sb.writeln('${g.toCompactString()} ('
          // '${(g.duration.inMinutes/60).toStringAsFixed(1)} giờ'
          '${g.duration.inMinutes > 60 ? '${g.duration.inHours} giờ' : '${g.duration.inMinutes} phút'}'
          ')');
    }

    if (maxItems != null && total > maxItems) {
      sb.writeln('... (+${total - maxItems} khoảng chậm)');
    }

    return sb.toString().trimRight();
  }
}
