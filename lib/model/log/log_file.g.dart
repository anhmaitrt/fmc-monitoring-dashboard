// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogFile _$LogFileFromJson(Map<String, dynamic> json) => LogFile(
  logs: (json['logs'] as List<dynamic>)
      .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LogFileToJson(LogFile instance) => <String, dynamic>{
  'logs': instance.logs.map((e) => e.toJson()).toList(),
};

LogEntry _$LogEntryFromJson(Map<String, dynamic> json) => LogEntry(
  genTime: (json['genTime'] as num).toInt(),
  message: json['message'] as String,
);

Map<String, dynamic> _$LogEntryToJson(LogEntry instance) => <String, dynamic>{
  'genTime': instance.genTime,
  'message': instance.message,
};
