import 'package:collection/collection.dart';
import 'package:fmc_monitoring_dashboard/model/log/csv_log_model.dart';
import 'package:fmc_monitoring_dashboard/model/user_cgm_data_row.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  UserModel({
    this.userId,
    this.phoneNumber,
    this.fullName,
    this.platform,
    this.platformVersion,
    this.deviceModel,
    this.appVersion,
    this.dataFiles,
    this.logList,
    this.isVIP = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  final String? userId;
  final String? phoneNumber;
  final String? fullName;
  final String? platform;
  final String? platformVersion;
  final String? deviceModel;
  final String? appVersion;
  final bool isVIP;
  List<List<UserCGMDataRow>>? dataFiles;
  List<CSVLogModel>? logList;
}

extension EListUserModel on List<UserModel> {
  UserModel? getUserById(String id) {
    return firstWhereOrNull((e) => e.userId == id);
  }

  List<UserModel> getAndroidUsers() {
    // if(hasDuplicateUserId()) {
    //   print('User list has duplicates');
    // }
    // final result = uniqueByUserId();
    return /*result.*/where((e) => e.platform == 'android').toList();
  }

  bool hasDuplicateUserId() {
    final ids = map((e) => e.userId).whereType<String>().toList();
    return ids.length != ids.toSet().length;
  }

  List<UserModel> uniqueByUserId() {
    final seen = <String>{};
    return where((u) {
      final id = u.userId;
      if (id == null) return true; // or false if you want to drop null ids
      return seen.add(id); // add() returns false if already exists
    }).toList();
  }
}