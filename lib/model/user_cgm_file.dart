// import 'package:copy_with_extension/copy_with_extension.dart';
import 'dart:core';
import 'dart:math';

import 'package:fmc_monitoring_dashboard/core/utils/extension/date_extension.dart';
import 'package:fmc_monitoring_dashboard/core/utils/extension/string_extension.dart';
import 'package:fmc_monitoring_dashboard/model/sync_gap.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/utils/extension/list_extension.dart';

part 'user_cgm_file.g.dart';

@JsonSerializable(explicitToJson: true)
class UserCGMFile {
  UserCGMFile({
    this.fileName,
    required this.userId,
    required this.phoneNumber,
    required this.fullName,
    required this.platform,
    required this.isDeleted,
    required this.startedAt,
    required this.stoppedAt,
    required this.syncGaps,
    required this.syncGapCount,
  });

  /// from Drive metadata, not from JSON
  String? fileName;

  @JsonKey(name: 'user_id')
  final String? userId;

  @JsonKey(name: 'username')
  final String? phoneNumber;

  @JsonKey(name: 'full_name')
  final String? fullName;

  @JsonKey(name: 'device_type')
  final String? platform;

  @JsonKey(name: 'is_delete')
  final bool? isDeleted;

  @JsonKey(name: 'started_at')
  final String? startedAt;

  @JsonKey(name: 'stopped_at')
  final String? stoppedAt;

  /// [[start, end], ...]
  @JsonKey(
    name: 'sync_gaps',
    fromJson: _syncGapsFromJson,
    toJson: _syncGapsToJson,
  )
  final List<SyncGap> syncGaps;

  @JsonKey(name: 'sync_gap_count')
  final int? syncGapCount;

  factory UserCGMFile.fromJson(Map<String, dynamic> json) =>
      _$UserCGMFileFromJson(json);

  Map<String, dynamic> toJson() => _$UserCGMFileToJson(this);

  static List<SyncGap> _syncGapsFromJson(List<dynamic> json) =>
      json.map((e) => SyncGap.fromJson(e as List<dynamic>)).toList();

  static List<List<String>> _syncGapsToJson(List<SyncGap> gaps) =>
      gaps.map((e) => e.toJson()).toList();

  @override
  String toString() => 'UserCGMFile('
        'fileName: $fileName, '
        'userId: $userId, '
        'phoneNumber: $phoneNumber, '
        'fullName: $fullName, '
        'platform: $platform, '
        'isDeleted: $isDeleted, '
        'startedAt: $startedAt, '
        'stoppedAt: $stoppedAt, '
        'syncGap: $syncGaps'
        'syncGapCount: $syncGapCount'
        ')';

  DateTime? get dateTime {
    if(fileName.isNullOrEmpty) return null;

    final base = fileName!.toLowerCase().endsWith('.json')
        ? fileName!.substring(0, fileName!.length - 5)
        : fileName!;

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

  Duration get currentSessionDuration {
    if(startedAt.isNullOrEmpty) {
      return Duration(minutes: -1);
    }

    return startedAt!.getGap(DateTime(dateTime!.year, dateTime!.month, dateTime!.day, 23, 59, 59).formatHHMMDDMMYYYY);
  }

  String summarizeSyncGaps() {
    if(syncGaps.isEmpty) return 'Ổn định';

    List<String> result = List.empty(growable: true);
    var syncGapInMinute = 0;
    int longestGapIndex = 0;
    int longestGap = syncGaps.first.duration.inMinutes;
    int totalGap = 0;
    for(int i = 0; i < syncGaps.length; i++) {
      syncGapInMinute = syncGaps[i].duration.inMinutes;
      totalGap += syncGapInMinute;
      if(longestGap < syncGapInMinute) {
        longestGapIndex = i;
        longestGap = syncGapInMinute;
      }

      result.add('${syncGaps[i]} ($syncGapInMinute phút)');
    }

    result[longestGapIndex] += ' (*)';
    print('File ${fileName} (${dateTime!.formatHHMMDDMMYYYY}): Tổng $totalGap phút (${(totalGap/getCurrentSessionInHour(maxHour: 24)).toStringAsFixed(2)}%), ${currentSessionDuration.inHours}, ${getCurrentSessionInHour(maxHour: 24)}');
    return '- Tổng $totalGap phút (${(totalGap/getCurrentSessionInHour(maxHour: 24)).toStringAsFixed(2)}%)' //24 hour
        '\n- Gap dài nhất: $longestGap phút (${(longestGap/60).toStringAsFixed(2)} giờ)'
        '\n- $syncGapCount khoảng chậm:'
        '\n${result.join('\n')}'
        // '\n${syncGaps.inString()}'
    ;
    return '${syncGaps.length} lần chậm:\n${syncGaps.inString()}';
  }
}

extension EUserCGMFile on UserCGMFile {
  double get totalGapTimeInMinute {
    int totalGapTime = 0;
    for(int i = 0; i < syncGaps.length; i++) {
      totalGapTime += syncGaps[i].duration.inMinutes;
    }

    return totalGapTime.toDouble();
  }

  double get totalGapTimeInHour {
    int totalGapTime = 0;
    for(int i = 0; i < syncGaps.length; i++) {
      totalGapTime += syncGaps[i].duration.inHours;
    }

    return totalGapTime.toDouble();
  }

  double get longestGapTimeInMinute {
    int syncGapInMinute = 0;
    int longestGap = syncGaps.firstOrNull?.duration.inMinutes ?? 0;
    for(int i = 0; i < syncGaps.length; i++) {
      syncGapInMinute = syncGaps[i].duration.inMinutes;
      if(longestGap < syncGapInMinute) {
        longestGap = syncGapInMinute;
      }
    }

    return longestGap.toDouble();
  }

  double get longestGapTimeInHour {
    int syncGapInMinute = 0;
    int longestGap = syncGaps.firstOrNull?.duration.inHours ?? 0;
    for(int i = 0; i < syncGaps.length; i++) {
      syncGapInMinute = syncGaps[i].duration.inHours;
      if(longestGap < syncGapInMinute) {
        longestGap = syncGapInMinute;
      }
    }

    return longestGap.toDouble();
  }

  double getCurrentSessionInHour({int? maxHour}) {
    // double count = 0;
    //
    // if(maxHour != null && currentSessionDuration.inHours > maxHour) {
    //   count += maxHour;
    // } else {
    //   count += currentSessionDuration.inHours;
    // }
    return ((maxHour != null && currentSessionDuration.inHours > maxHour) ? maxHour : currentSessionDuration.inHours).toDouble();
  }
}

extension EListTotalCgmFile on List<UserCGMFile> {
  int countByPlatform(String platform) {
    var count = 0;
    forEach((d) {
      if(d.platform == platform) {
        count++;
      }
    });
    return count;
  }

  List<UserCGMFile> filterByPlatform(String platform) => where((d) => d.platform == platform).toList();

  double get longestGapTimeInMinute => map((f) => f.longestGapTimeInMinute).toList().reduce(max);

  double get longestGapTimeInHour => map((f) => f.longestGapTimeInHour).toList().reduce(max);

  double get totalGapTimeInHour {
    double count = 0;
    for(int i = 0; i < length; i++) {
        count += this[i].totalGapTimeInHour;
    }
    return count;
  }

  double getTotalSessionInHour({int? maxHour}) {
    double count = 0;
    for(int i = 0; i < length; i++) {
        if(maxHour != null && this[i].currentSessionDuration.inHours > maxHour) {
          count += maxHour;
        } else {
          count += this[i].currentSessionDuration.inHours;
        }
    }
    return count;
  }

  double get percentageInterruption {
    return ((totalGapTimeInHour / getTotalSessionInHour(maxHour: 24)) * 100).roundToDouble();
  }
}

extension EListListTotalCgmFile on List<List<UserCGMFile>> {
  List<double> countByPlatform(String platform) => map((l) => l.countByPlatform(platform).toDouble()).toList();

  List<List<UserCGMFile>> splitByPlatform(String platform) {
    return map((l) => l.filterByPlatform(platform)).toList();
  }

  List<double> count() {
    return map((l) => l.length.toDouble()).toList(growable: false);
  }

  double? get maxX {
    return 31;
    // final totalIos = map((f) => f.countPlatform('ios').toDouble()).toList();
    // final totalAndroid = map((f) => f.countPlatform('android').toDouble()).toList();
    // final nums = [...totalIos, ...totalAndroid];
    // return nums.reduce((a, b) => a > b ? a : b);
  }

  double get maxY {
    final totalIos = map((f) => f.countByPlatform('ios').toDouble()).toList();
    final totalAndroid = map((f) => f.countByPlatform('android').toDouble()).toList();
    final nums = [...totalIos, ...totalAndroid];
    if(nums.isEmpty) return -1;
    return nums.reduce((a, b) => a > b ? a : b);
  }

  List<String> toDateList() {
    return map((f) {
      final d = parseDdMmYyFilename(f.firstOrNull?.fileName ?? "")!;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }).toList();
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
}
