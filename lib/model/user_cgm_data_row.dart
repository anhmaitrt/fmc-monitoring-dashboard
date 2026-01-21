// import 'package:copy_with_extension/copy_with_extension.dart';
import 'dart:core';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/utils/extension/date_extension.dart';
import '../core/utils/extension/list_extension.dart';
import '../core/utils/extension/string_extension.dart';
import 'export/issue_export_row.dart';
import 'export/issue_priority.dart';
import 'interruption_range.dart';
import 'sync_gap.dart';

part 'user_cgm_data_row.g.dart';

@JsonSerializable(explicitToJson: true)
class UserCGMDataRow {
  UserCGMDataRow({
    required this.userId,
    required this.phoneNumber,
    required this.fullName,
    required this.platform,
    required this.isDeleted,
    required this.startedAt,
    required this.stoppedAt,
    required this.syncGaps,
    required this.syncGapCount,
    this.fileName,
    this.isVip = false,
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
  bool isVip;

  factory UserCGMDataRow.fromJson(Map<String, dynamic> json) =>
      _$UserCGMDataRowFromJson(json);

  Map<String, dynamic> toJson() => _$UserCGMDataRowToJson(this);

  static List<SyncGap> _syncGapsFromJson(List<dynamic> json) =>
      json.map((e) => SyncGap.fromJson(e as List<dynamic>)).toList();

  static List<List<String>> _syncGapsToJson(List<SyncGap> gaps) =>
      gaps.map((e) => e.toJson()).toList();

  @override
  String toString() => 'UserCGMDataRow('
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
    // int totalGap = 0;
    for(int i = 0; i < syncGaps.length; i++) {
      syncGapInMinute = syncGaps[i].duration.inMinutes;
      // totalGap += syncGapInMinute;
      if(longestGap < syncGapInMinute) {
        longestGapIndex = i;
        longestGap = syncGapInMinute;
      }

      result.add('${syncGaps[i]} ($syncGapInMinute phút)');
    }

    result[longestGapIndex] += ' (*)';
    return '- Tổng $totalGapTimeInMinute phút (${(totalGapTimeInMinute/60).toStringAsFixed(1)} giờ) (${interruptionPercentage.toStringAsFixed(1)}%)' //24 hour
        '\n- Gap dài nhất: $longestGapTimeInMinute phút (${(longestGapTimeInMinute/60).toStringAsFixed(2)} giờ)'
        '\n- $syncGapCount khoảng chậm:'
        '\n${result.join('\n')}'
        // '\n${syncGaps.inString()}'
    ;
    return '${syncGaps.length} lần chậm:\n${syncGaps.inString()}';
  }
}

extension EUserCGMDataRow on UserCGMDataRow {
  double get totalGapTimeInMinute {
    int totalGapTime = 0;
    for(int i = 0; i < syncGaps.length; i++) {
      totalGapTime += syncGaps[i].duration.inMinutes;
    }

    return totalGapTime.toDouble();
  }

  double get totalGapTimeInHour => (totalGapTimeInMinute/60);

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

  // double get longestGapTimeInHour {
  //   int syncGapInMinute = 0;
  //   int longestGapInMinute = syncGaps.firstOrNull?.duration.inMinutes ?? 0;
  //   for(int i = 0; i < syncGaps.length; i++) {
  //     syncGapInMinute = syncGaps[i].duration.inMinutes;
  //     if(longestGapInMinute < syncGapInMinute) {
  //       longestGapInMinute = syncGapInMinute;
  //     }
  //   }
  //
  //   return longestGapInMinute/60;
  // }

  double getCurrentSessionInHour({int? maxHour}) {
    final currentSessionDuration = this.currentSessionDuration.inMinutes/60;
    return ((maxHour != null && currentSessionDuration > maxHour) ? maxHour : currentSessionDuration).toDouble();
  }

  double getCurrentSessionInMinute({int? maxHour}) {
    double? maxMinute;
    if(maxHour != null) {
      maxMinute = maxHour*60;
    }
    return ((maxMinute != null && currentSessionDuration.inMinutes > maxMinute) ? maxMinute : currentSessionDuration.inMinutes).toDouble();
  }

  double get interruptionPercentage {
    return totalGapTimeInMinute*100/getCurrentSessionInMinute(maxHour: 24);
  }
}

extension EListUserCGMDataRow on List<UserCGMDataRow> {
  /// userId | phoneNumber | fullName | platform | startedAt | stoppedAt
  List<UserCGMDataRow> filter(String query) {
    if (query.isEmpty) return this;

    bool match(String? s) => (s ?? '').toLowerCase().contains(query);

    return where((f) {
      return match(f.userId) ||
          match(f.phoneNumber) ||
          match(f.fullName) ||
          match(f.platform) ||
          match(f.startedAt) ||
          match(f.stoppedAt);
    }).toList();
  }

  List<UserCGMDataRow> filterByRange(InterruptionRange? range) {
    if (range == null) return this;
    return where((e) => InterruptionRange.fromPercent(e.interruptionPercentage) == range).toList();
  }

  List<UserCGMDataRow> filterByRanges(Set<InterruptionRange> ranges) {
    if (ranges.isEmpty) return this;

    return where((row) {
      for (final r in ranges) {
        // reuse your existing single-range filter logic
        if ([row].filterByRange(r).isNotEmpty) return true;
      }
      return false;
    }).toList();
  }

  int countByPlatform(String platform) {
    var count = 0;
    forEach((d) {
      if(d.platform == platform) {
        count++;
      }
    });
    return count;
  }

  List<UserCGMDataRow> filterByPlatform(String platform) => where((d) => d.platform == platform).toList();

  double get longestGapTimeInMinute => map((f) => f.longestGapTimeInMinute).toList().reduce(max);

  double get longestGapTimeInHour => map((f) => longestGapTimeInMinute/60/*f.longestGapTimeInHour*/).toList().reduce(max);

  double get totalGapTimeInHour {
    double count = 0;
    for(int i = 0; i < length; i++) {
        count += this[i].totalGapTimeInHour;
    }
    return count;
  }

  double getTotalSessionInHour({int? maxHour}) {
    double count = 0;
    var sessionDurationInHour = 0.0;
    for(int i = 0; i < length; i++) {
        sessionDurationInHour = this[i].currentSessionDuration.inMinutes/60;
        if(maxHour != null && sessionDurationInHour > maxHour) {
          count += maxHour;
        } else {
          count += sessionDurationInHour;
        }
    }
    return count;
  }

  double get percentageInterruption {
    return ((totalGapTimeInHour / getTotalSessionInHour(maxHour: 24)) * 100).roundToDouble();
  }

  UserCGMDataRow getUserWithLongestGap() {
    return reduce((current, next) {
      return current.totalGapTimeInHour > next.totalGapTimeInHour ? current : next;
    });
  }

  String summarizeSyncGaps({int? totalUsersAndroid, int? totalUsersIos}) {
    int countAndroid = totalUsersAndroid ?? 0;
    Map<InterruptionRange, double> androidInterruptionRangeCount = {};

    int countIos = totalUsersIos ?? 0;
    Map<InterruptionRange, double> iosInterruptionRangeCount = {};

    for (var e in InterruptionRange.values) {
      androidInterruptionRangeCount[e] = 0;
      iosInterruptionRangeCount[e] = 0;
    }

    double interruptionPercentage = 0;
    for(int i = 0; i < length; i++) {
      interruptionPercentage = this[i].interruptionPercentage;
      if(this[i].platform == 'android') {
        if(totalUsersAndroid == null) {
          countAndroid++;
        }
        androidInterruptionRangeCount[InterruptionRange.fromPercent(interruptionPercentage)] = androidInterruptionRangeCount[InterruptionRange.fromPercent(interruptionPercentage)]! + 1;
      } else if(this[i].platform == 'ios') {
        if(totalUsersIos == null) {
          countIos++;
        }
        iosInterruptionRangeCount[InterruptionRange.fromPercent(interruptionPercentage)] = iosInterruptionRangeCount[InterruptionRange.fromPercent(interruptionPercentage)]! + 1;
      }
    }

    return InterruptionRange.values.map((e) => '${e.label}: ${
        androidInterruptionRangeCount[e] == 0 && iosInterruptionRangeCount[e] == 0
            ? '-'
            : '${androidInterruptionRangeCount[e]} ${androidInterruptionRangeCount[e] == 0 ? '' : '(${(androidInterruptionRangeCount[e]!/countAndroid*100).toStringAsFixed(1)}%)'} android, '
            '${iosInterruptionRangeCount[e]} ${iosInterruptionRangeCount[e] == 0 ? '' : '(${(iosInterruptionRangeCount[e]!/countIos*100).toStringAsFixed(1)}%)'} ios'
    }').join('\n');
  }

  List<double> filterUserByInterruptionRangeByPlatform(String platform) {
    Map<InterruptionRange, double> interruptionRangeCount = {};

    for (var e in InterruptionRange.values) {
      interruptionRangeCount[e] = 0;
    }

    double interruptionPercentage = 0;
    for(int i = 0; i < length; i++) {
      interruptionPercentage = this[i].interruptionPercentage;
      if(this[i].platform == platform) {
        interruptionRangeCount[InterruptionRange.fromPercent(interruptionPercentage)] = interruptionRangeCount[InterruptionRange.fromPercent(interruptionPercentage)]! + 1;
      }
    }

    return interruptionRangeCount.values.toList();
  }
}

extension EListListCgmDataRow on List<List<UserCGMDataRow>> {
  List<double> countByPlatform(String platform) => map((l) => l.countByPlatform(platform).toDouble()).toList();

  List<List<UserCGMDataRow>> splitByPlatform(String platform) => map((l) => l.filterByPlatform(platform)).toList();

  List<double> count() => map((l) => l.length.toDouble()).toList(growable: false);

  double? get maxX {
    return length <= 31 ? length.toDouble() : 31;
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
      final d = parseDdMmYyFilename(f.firstOrNull?.fileName ?? '')!;
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

  List<IssueExportRow> toCSVData({int lastNDays = 30}) {
    final rows = <IssueExportRow>[];

    final allDates = map((d) => d.firstOrNull?.dateTime)
        .whereType<DateTime>()
        .toList();
    if (allDates.isEmpty) return rows;

    final anchor = allDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final cutoff = anchor.subtract(Duration(days: lastNDays - 1)); // inclusive

    groupByUserIdKeepDays().forEach((userId, days) {
      final recentDays = days.where((dayList) {
        final dt = dayList.firstOrNull?.dateTime;
        if (dt == null) return false;
        return !dt.isBefore(cutoff) && !dt.isAfter(anchor);
      }).toList();

      if (recentDays.isEmpty) return;

      final allRecords = recentDays.expand((d) => d).toList();
      if (allRecords.isEmpty) return;

      final percentages = allRecords
          .map((e) => e.interruptionPercentage)
          .where((p) => p.isFinite)
          .toList();

      final avgPercent = percentages.isEmpty
          ? 0.0
          : percentages.reduce((a, b) => a + b) / percentages.length;

      final priority = IssuePriority.fromPercent(avgPercent);

      // latest record in window
      allRecords.sort((a, b) {
        final da = a.dateTime;
        final db = b.dateTime;
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
      final latest = allRecords.first;

      final issue = 'Chậm ${avgPercent.toStringAsFixed(1)}% trong $lastNDays ngày';

      rows.add(IssueExportRow(
        phone: latest.phoneNumber?.maskPhone() ?? '',
        name: latest.fullName ?? '',
        priority: priority,
        issue: issue,
        avgPercent: avgPercent,
      ));
    });

    // ✅ sort: priority DESC, then avgPercent DESC, then name ASC (optional)
    rows.sort((a, b) {
      final p = b.priority.rank.compareTo(a.priority.rank);
      if (p != 0) return p;

      final avg = b.avgPercent.compareTo(a.avgPercent);
      if (avg != 0) return avg;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return rows;
  }

  Map<String, List<UserCGMDataRow>> groupByUserIdSorted(List<List<UserCGMDataRow>> dataFiles) {
    final grouped = _groupByUserId(dataFiles);

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final da = a.dateTime;
        final db = b.dateTime;
        if (da == null || db == null) return 0;
        return da.compareTo(db); // ASC (old -> new). Use db.compareTo(da) for DESC
      });
    }

    return grouped;
  }

  Map<String, List<UserCGMDataRow>> _groupByUserId(List<List<UserCGMDataRow>> dataFiles) {
    final Map<String, List<UserCGMDataRow>> grouped = {};

    for (final dayList in dataFiles) {
      for (final item in dayList) {
        final id = item.userId;
        if (id == null || id.isEmpty) continue;

        (grouped[id] ??= []).add(item);
      }
    }

    return grouped;
  }

  Map<String, List<List<UserCGMDataRow>>> groupByUserIdKeepDays() {
    final Map<String, List<List<UserCGMDataRow>>> result = {};

    for (final dayList in this) {
      // group within this day by userId
      final Map<String, List<UserCGMDataRow>> dayGrouped = {};

      for (final item in dayList) {
        final id = item.userId;
        if (id == null || id.isEmpty) continue;
        (dayGrouped[id] ??= []).add(item);
      }

      // append this day-group to global result
      for (final e in dayGrouped.entries) {
        (result[e.key] ??= []).add(e.value);
      }
    }

    return result;
  }

  /// Keep day alignment:
  /// dataFiles[0] is newest day list, dataFiles[1] is older, ...
  /// For each userId we keep a list of day lists in that same order.
  Map<String, List<List<UserCGMDataRow>>> groupCgmByUserIdKeepDayIndex() {
    final dayCount = length;

    // userId -> List(dayCount) of nullable lists
    final tmp = <String, List<List<UserCGMDataRow>?>>{};

    for (int dayIndex = 0; dayIndex < length; dayIndex++) {
      final dayList = this[dayIndex];

      for (final row in dayList) {
        final uid = row.userId;
        if (uid == null || uid.isEmpty) continue;

        tmp.putIfAbsent(uid, () => List<List<UserCGMDataRow>?>.filled(dayCount, null));

        final slot = tmp[uid]![dayIndex] ?? <UserCGMDataRow>[];
        slot.add(row);
        tmp[uid]![dayIndex] = slot;
      }
    }

    // convert to non-null list-of-days per user
    return tmp.map((uid, daySlots) {
      final userDays = daySlots.whereType<List<UserCGMDataRow>>().toList();
      return MapEntry(uid, userDays);
    });
  }
}
