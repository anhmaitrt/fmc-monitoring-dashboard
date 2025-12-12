// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'total_cgm_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TotalCgmFile _$TotalCgmFileFromJson(Map<String, dynamic> json) => TotalCgmFile(
  fileName: json['fileName'] as String?,
  id: json['id'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  platform: json['platform'] as String?,
  isDeleted: json['isDeleted'] as bool?,
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  name: json['name'] as String?,
);

Map<String, dynamic> _$TotalCgmFileToJson(TotalCgmFile instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'id': instance.id,
      'phoneNumber': instance.phoneNumber,
      'name': instance.name,
      'platform': instance.platform,
      'isDeleted': instance.isDeleted,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };
