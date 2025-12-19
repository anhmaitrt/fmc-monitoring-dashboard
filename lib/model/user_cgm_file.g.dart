// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_cgm_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCGMFile _$UserCGMFileFromJson(Map<String, dynamic> json) => UserCGMFile(
  fileName: json['fileName'] as String?,
  userId: json['user_id'] as String?,
  phoneNumber: json['username'] as String?,
  fullName: json['full_name'] as String?,
  platform: json['device_type'] as String?,
  isDeleted: json['is_delete'] as bool?,
  startedAt: json['started_at'] as String?,
  stoppedAt: json['stopped_at'] as String?,
  syncGaps: UserCGMFile._syncGapsFromJson(json['sync_gaps'] as List),
  syncGapCount: (json['sync_gap_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserCGMFileToJson(UserCGMFile instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'user_id': instance.userId,
      'username': instance.phoneNumber,
      'full_name': instance.fullName,
      'device_type': instance.platform,
      'is_delete': instance.isDeleted,
      'started_at': instance.startedAt,
      'stopped_at': instance.stoppedAt,
      'sync_gaps': UserCGMFile._syncGapsToJson(instance.syncGaps),
      'sync_gap_count': instance.syncGapCount,
    };
