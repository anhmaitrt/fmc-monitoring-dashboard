// import 'package:copy_with_extension/copy_with_extension.dart';
import 'dart:core';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:googleapis/drive/v3.dart';

part 'total_cgm_file.g.dart';

@JsonSerializable()
// @CopyWith()
class TotalCgmFile {
  TotalCgmFile({
    this.fileName,
    this.id,
    this.phoneNumber,
    this.platform,
    this.isDeleted,
    this.startDate,
    this.endDate,
    this.name,
  });

  factory TotalCgmFile.fromJson(Map<String, dynamic> json) => _$TotalCgmFileFromJson(json);

  Map<String, dynamic> toJson() => _$TotalCgmFileToJson(this);

  final String? fileName;
  final String? id;
  final String? phoneNumber;
  final String? name;
  final String? platform;
  final bool? isDeleted;
  final String? startDate;
  final String? endDate;

  @override
  String toString() {
    return 'TotalCgmFile(fileName: $fileName, id: $id, phoneNumber: $phoneNumber, name: $name, platform: $platform, isDeleted: $isDeleted, startDate: $startDate, endDate: $endDate)';
  }
}

extension EListListTotalCgmFile on List<List<TotalCgmFile>> {
  // List<List<TotalCgmFile>> fromRawFiles(List<File> rawFiles) {
  //
  // }
  // int countAndroid() {
  //
  // }
}

extension EListTotalCgmFile on List<TotalCgmFile> {
  // List<List<TotalCgmFile>> fromRawFiles(List<File> rawFiles) {
  //
  // }
  int countPlatform(String platform) {
    var count = 0;
    forEach((d) {
      if(d.platform == platform) {
        count++;
      }
    });
    return count;
  }
}
