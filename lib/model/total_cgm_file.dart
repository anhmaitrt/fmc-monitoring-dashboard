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
  List<double> splitByPlatform(String platform) {
    return map((l) => l.countPlatform(platform).toDouble()).toList();
  }

  double? get maxX {
    return 31;
    // final totalIos = map((f) => f.countPlatform('ios').toDouble()).toList();
    // final totalAndroid = map((f) => f.countPlatform('android').toDouble()).toList();
    // final nums = [...totalIos, ...totalAndroid];
    // return nums.reduce((a, b) => a > b ? a : b);
  }

  double get maxY {
    final totalIos = map((f) => f.countPlatform('ios').toDouble()).toList();
    final totalAndroid = map((f) => f.countPlatform('android').toDouble()).toList();
    final nums = [...totalIos, ...totalAndroid];
    if(nums.isEmpty) return -1;
    return nums.reduce((a, b) => a > b ? a : b);
  }

  List<String> toDateList() {
    return map((f) => _fmt(parseDdMmYyFilename(f.firstOrNull?.fileName ?? "")!)).toList();
  }

  DateTime? parseDdMmYyFilename(String fileName) {
    final base = fileName.toLowerCase().endsWith('.json')
        ? fileName.substring(0, fileName.length - 5)
        : fileName;

    if (base.length != 6) return null; // ddMMyy

    final dd = int.tryParse(base.substring(0, 2));
    final mm = int.tryParse(base.substring(2, 4));
    final yy = int.tryParse(base.substring(4, 6));
    if (dd == null || mm == null || yy == null) return null;

    // choose a century rule (adjust if needed)
    final year = (yy >= 70) ? 1900 + yy : 2000 + yy;

    // basic validation
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;

    return DateTime(year, mm, dd);
  }
  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

extension EListTotalCgmFile on List<TotalCgmFile> {
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
