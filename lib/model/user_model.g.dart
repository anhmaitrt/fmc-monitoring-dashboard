// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) =>
    UserModel(
        userId: json['userId'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        fullName: json['fullName'] as String?,
        platform: json['platform'] as String?,
        deviceModel: json['deviceModel'] as String?,
        appVersion: json['appVersion'] as String?,
      )
      ..dataFiles = (json['dataFiles'] as List<dynamic>)
          .map(
            (e) => (e as List<dynamic>)
                .map((e) => UserCGMDataRow.fromJson(e as Map<String, dynamic>))
                .toList(),
          )
          .toList();

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'userId': instance.userId,
  'phoneNumber': instance.phoneNumber,
  'fullName': instance.fullName,
  'platform': instance.platform,
  'deviceModel': instance.deviceModel,
  'appVersion': instance.appVersion,
  'dataFiles': instance.dataFiles,
};
