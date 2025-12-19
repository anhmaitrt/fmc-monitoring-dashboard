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
