import 'package:fmc_monitoring_dashboard/model/log/log_file.dart';

class CSVLogModel {
  final String? userId;
  final String? createdAt;
  // final String? genTime;
  final LogEntry? log;

  CSVLogModel({
    required this.userId,
    required this.createdAt,
    required this.log,
  });

  DateTime? get genTime => log?.genDateTime;
  String? get message => log?.message;
}