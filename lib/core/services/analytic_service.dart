import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fmc_monitoring_dashboard/model/log/csv_log_model.dart';
import 'package:fmc_monitoring_dashboard/model/log/log_file.dart';

import '../../model/user_cgm_data_row.dart';
import '../components/toast/model/loading_progress.dart';
import 'google_drive_service.dart';

class AnalyticService {
    AnalyticService._();

    static AnalyticService instance = AnalyticService._();

    final String DATA_FOLDER = '1yMrZnw2BfQsICvu-Cfb44xsEMU3-w9fQ';
    final String LOGS_FOLDER = '1KRNCAsStiwA3IW1tCtsCCotbZeMNDlAl';

    // ⚠️ tune this: 3–10 is typical for web
    final _concurrency = 10;

    final _progressController = StreamController<LoadingProgress>.broadcast();
    Stream<LoadingProgress> get progressStream => _progressController.stream;

    List<List<UserCGMDataRow>> dataFiles = List.empty(growable: true);
    List<CSVLogModel> logList = List.empty(growable: true);

    void _emit(LoadingProgress p) {
        if (!_progressController.isClosed) _progressController.add(p);
    }

    Future<void> fetchDB() async {
        try {
            await Future.wait([
                _fetchLogs(),
                _fetchUsersCGMData(),
            ]);

        } catch (e, stackTrace) {
            print("Error getting files: $e\n$stackTrace");
            rethrow;
        }
    }

    Future<void> _fetchUsersCGMData() async {
        try {
            dataFiles.clear();

            final rawFiles = await GoogleDriveService.instance.readFolder(DATA_FOLDER);
            // rawFiles.removeRange(2, rawFiles.length);

            final total = rawFiles.length;
            var completed = 0;

            _emit(LoadingProgress(isLoading: true, current: 0, total: total));

            // results holder with stable order
            final results = List<List<UserCGMDataRow>?>.filled(total, null);

            await _runPool(
                items: rawFiles,
                concurrency: _concurrency,
                task: (file, index) async {
                    // Download
                    final jsonList = await GoogleDriveService.instance.getJsonContent(file);

                    final models = <UserCGMDataRow>[];

                    for (final j in jsonList) {
                        final model = UserCGMDataRow.fromJson(j);
                        model.fileName = file.name;

                        if (!(model.phoneNumber?.contains('demo') ?? false)) {
                            models.add(model);
                        }
                    }

                    results[index] = models;

                    // Progress update (completed count)
                    completed++;
                    _emit(LoadingProgress(
                        isLoading: true,
                        current: completed,
                        total: total,
                        fileName: file.name, // last completed file
                    ));
                },
            );

            // Collect results (keeping file order)
            dataFiles.addAll(results.whereType<List<UserCGMDataRow>>());

            // Your existing sort by file dateTime (if you still want)
            dataFiles.sort((a, b) {
                final da = a.firstOrNull?.dateTime;
                final db = b.firstOrNull?.dateTime;
                if (da == null || db == null) return 0;
                return db.compareTo(da);
            });

            print('Fetched ${dataFiles.length} files for CGM data');
        } catch (e, st) {
            print('Failed to fetch total cgm data: $e\n$st');
        } finally {
            _emit(LoadingProgress.idle);
        }
    }

    Future<void> _fetchLogs() async {
        final files = await GoogleDriveService.instance.readFolder(LOGS_FOLDER);

        for (final file in files) {
            if (!file.name!.endsWith('.csv')) continue;

            final content = await GoogleDriveService.instance.getFileContent(file);
            final rows = GoogleDriveService.instance.getCsvContent(content);

            if(rows.isEmpty) {
                return;
            }

            print('CSV ${file.name} has ${rows.length} rows');
            // rows.removeRange(2, rows.length);

            int createdAtColumnIndex = -1;
            int userIdColumnIndex = -1;
            int messageColumnIndex = -1;
            for(int i = 0; i < rows[0].length; i++) {
                createdAtColumnIndex = rows[0][i] == '@timestamp' ? i : createdAtColumnIndex;
                messageColumnIndex = rows[0][i] == 'request_body' ? i : messageColumnIndex;
                userIdColumnIndex = rows[0][i] == 'user_id' ? i : userIdColumnIndex;
            }

            // Start from 1, skip header row if needed
            for (int r = 1; r < rows.length; r++) {
                LogFile? message;
                final messageJsonString = messageColumnIndex != -1 ? rows[r][messageColumnIndex] : null;
                if(messageJsonString != null) {
                    final json = jsonDecode(messageJsonString);
                    // print('json: $json');
                    message = LogFile.fromJson(json);
                    // if(json is! Map<String, dynamic>) {
                    //     message = LogFile.fromJson(json);
                    // } else {
                    //     print('CSV ${file.name} missing logs at row $r, row data as json $messageJsonString, \n----message: $message');
                    // }
                }

                if(message == null) {
                    print('CSV ${file.name} missing message at row $r, row data as json $messageJsonString'
                        '\n---- Raw data: ${rows[r][messageColumnIndex]}'
                        '\n------ jsonString: ${jsonDecode(messageJsonString)}');
                    break;
                }

                logList.add(CSVLogModel(
                    createdAt: createdAtColumnIndex != -1 ? rows[r][createdAtColumnIndex] : null,
                    log: message?.logs.firstOrNull,
                    userId: userIdColumnIndex != -1 ? rows[r][userIdColumnIndex] : null,
                ),);
            }

            print('Fetched ${logList.length} row logs');
        }
    }

    Future<void> _runPool<T>({
        required List<T> items,
        required int concurrency,
        required Future<void> Function(T item, int index) task,
    }) async {
        var i = 0;
        final workers = List.generate(concurrency, (_) async {
            while (true) {
                final index = i++;
                if (index >= items.length) break;
                await task(items[index], index);
            }
        });
        await Future.wait(workers);
    }
}