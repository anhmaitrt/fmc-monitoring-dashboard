import 'package:json_annotation/json_annotation.dart';

part 'log_file.g.dart';

@JsonSerializable(explicitToJson: true)
class LogFile {
  final List<LogEntry> logs;

  LogFile({required this.logs});

  factory LogFile.fromJson(Map<String, dynamic> json) => _$LogFileFromJson(json);
  Map<String, dynamic> toJson() => _$LogFileToJson(this);
}

@JsonSerializable()
class LogEntry {
  /// raw value from JSON (seconds or milliseconds)
  @JsonKey(name: 'genTime')
  final int genTime;

  final String message;

  LogEntry({
    required this.genTime,
    required this.message,
  });

  /// Convenient computed DateTime (local)
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get genDateTime => _fromEpoch(genTime);

  factory LogEntry.fromJson(Map<String, dynamic> json) => _$LogEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LogEntryToJson(this);

  static DateTime _fromEpoch(int v) {
    // if it's 10-digit seconds, convert -> ms
    final ms = v < 1000000000000 ? v * 1000 : v;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }
}