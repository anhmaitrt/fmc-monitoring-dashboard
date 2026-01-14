import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fmc_monitoring_dashboard/model/log/csv_log_model.dart';
import 'package:fmc_monitoring_dashboard/model/log/log_file.dart';
import 'package:fmc_monitoring_dashboard/model/user_model.dart';

import '../../model/user_cgm_data_row.dart';
import '../components/toast/model/loading_progress.dart';
import 'google_drive_service.dart';
import 'issue_tracker/issue_tracker.dart';

class AnalyticService {
    AnalyticService._();

    static AnalyticService instance = AnalyticService._();

    final String DATA_FOLDER = '1yMrZnw2BfQsICvu-Cfb44xsEMU3-w9fQ';
    final String LOGS_FOLDER = '1FgMblKF_Mz6Wg9Zl8xSJfKEpOnzfX-ox';

    // ⚠️ tune this: 3–10 is typical for web
    final _concurrency = 10;

    final _progressController = StreamController<LoadingProgress>.broadcast();
    Stream<LoadingProgress> get progressStream => _progressController.stream;

    List<UserModel> userList = List.empty(growable: true);
    List<List<UserCGMDataRow>> dataFiles = List.empty(growable: true);
    List<CSVLogModel> logList = List.empty(growable: true);

    void _emit(LoadingProgress p) {
        if (!_progressController.isClosed) _progressController.add(p);
    }

    Future<void> fetchDB() async {
        try {
            await Future.wait([
                _fetchLogs(),          // fills logList
                _fetchUsersCGMData(),  // fills dataFiles
            ]);

            _buildUserList(); // ✅ merge into userList
            analyzeSyncRecovery(window: const Duration(minutes: 10));
        } catch (e, stackTrace) {
            print("Error getting files: $e\n$stackTrace");
            rethrow;
        }
    }

    Future<void> _fetchUsersCGMData() async {
        try {
            dataFiles.clear();

            final rawFiles = await GoogleDriveService.instance.readFolder(DATA_FOLDER);

            final total = rawFiles.length;
            var completed = 0;

            _emit(LoadingProgress(isLoading: true, current: 0, total: total));

            // results holder with stable order
            final results = List<List<UserCGMDataRow>?>.filled(total, null);

            await _runPool(
                items: rawFiles,
                concurrency: _concurrency,
                task: (file, index) async {
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

                    completed++;
                    _emit(LoadingProgress(
                        isLoading: true,
                        current: completed,
                        total: total,
                        fileName: file.name,
                    ));
                },
            );

            dataFiles.addAll(results.whereType<List<UserCGMDataRow>>());

            // Sort by day DESC
            dataFiles.sort((a, b) {
                final da = a.firstOrNull?.dateTime;
                final db = b.firstOrNull?.dateTime;
                if (da == null || db == null) return 0;
                return db.compareTo(da);
            });

            print('Fetched ${dataFiles.length} files for CGM data');
        } catch (e, st) {
            print('Failed to fetch CGM data: $e\n$st');
        } finally {
            _emit(LoadingProgress.idle);
        }
    }

    Future<void> _fetchLogs() async {
        try {
            logList.clear();

            final files = await GoogleDriveService.instance.readFolder(LOGS_FOLDER);

            // Only csv files
            final csvFiles = files.where((f) => (f.name ?? '').endsWith('.csv')).toList();
            if (csvFiles.isEmpty) return;

            final results = List<List<CSVLogModel>?>.filled(csvFiles.length, null);

            await _runPool(
                items: csvFiles,
                concurrency: _concurrency,
                task: (file, index) async {
                    final content = await GoogleDriveService.instance.getFileContent(file);
                    final rows = GoogleDriveService.instance.getCsvContent(content);

                    if (rows.isEmpty) {
                        results[index] = <CSVLogModel>[];
                        return;
                    }

                    int createdAtColumnIndex = -1;
                    int userIdColumnIndex = -1;
                    int messageColumnIndex = -1;

                    for (int i = 0; i < rows[0].length; i++) {
                        final col = rows[0][i];
                        if (col == '@timestamp') createdAtColumnIndex = i;
                        if (col == 'request_body') messageColumnIndex = i;
                        if (col == 'user_id') userIdColumnIndex = i;
                    }

                    final fileLogs = <CSVLogModel>[];

                    for (int r = 1; r < rows.length; r++) {
                        final messageJsonString =
                        (messageColumnIndex != -1) ? rows[r][messageColumnIndex] : null;

                        if (messageJsonString == null || messageJsonString.isEmpty) continue;

                        LogFile? message;
                        try {
                            final json = jsonDecode(messageJsonString);
                            message = LogFile.fromJson(json);
                        } catch (_) {
                            // bad row, skip
                            continue;
                        }

                        final userId =
                        (userIdColumnIndex != -1) ? rows[r][userIdColumnIndex] : null;

                        fileLogs.add(CSVLogModel(
                            createdAt: (createdAtColumnIndex != -1) ? rows[r][createdAtColumnIndex] : null,
                            log: message.logs.firstOrNull,
                            userId: userId,
                        ));
                    }

                    results[index] = fileLogs;
                    print('Fetched ${fileLogs.length} row logs from ${file.name}');
                },
            );

            logList.addAll(results.expand((e) => e ?? const <CSVLogModel>[]));
            print('Total logs: ${logList.length}');
        } catch (e, st) {
            print('Failed to fetch logs: $e\n$st');
        }
    }

    /// ✅ Build userList by merging:
    /// - CGM data grouped by userId (keeps day alignment)
    /// - Logs grouped by userId
    void _buildUserList() {
        userList.clear();

        final dataByUser = _groupCgmByUserIdKeepDayIndex(dataFiles);
        final logsByUser = _groupLogsByUserId(logList);

        final allUserIds = <String>{
            ...dataByUser.keys,
            ...logsByUser.keys,
        };

        for (final userId in allUserIds) {
            final userDays = dataByUser[userId]; // List<List<UserCGMDataRow>>
            final userLogs = logsByUser[userId]; // List<CSVLogModel>

            // pick "latest" CGM record (from most recent day list)
            final latestData = (userDays == null || userDays.isEmpty)
                ? null
                : userDays.firstOrNull?.firstOrNull;

            final user = UserModel(
                userId: userId,
                phoneNumber: latestData?.phoneNumber,
                fullName: latestData?.fullName,
                platform: latestData?.platform,
                platformVersion: userLogs?.extractPlatformVersionLatest(),
                deviceModel: userLogs?.extractDeviceModelLatest(),
                appVersion: userLogs?.extractAppVersionLatest(),
                dataFiles: userDays,
                logList: userLogs,
            );
            // if(user.appVersion != null) {
            //     print('user ${user.userId} ${user.fullName} is using version ${user.appVersion}');
            // }
            userList.add(user);
        }

        // Optional: sort userList (example: users with more issues first / or by name)
        userList.sort((a, b) {
            final an = (a.fullName ?? '').toLowerCase();
            final bn = (b.fullName ?? '').toLowerCase();
            return an.compareTo(bn);
        });

        // print('Built userList: ${userList.length}');
    }

    /// Keep day alignment:
    /// dataFiles[0] is newest day list, dataFiles[1] is older, ...
    /// For each userId we keep a list of day lists in that same order.
    Map<String, List<List<UserCGMDataRow>>> _groupCgmByUserIdKeepDayIndex(
        List<List<UserCGMDataRow>> days,
        ) {
        final dayCount = days.length;

        // userId -> List(dayCount) of nullable lists
        final tmp = <String, List<List<UserCGMDataRow>?>>{};

        for (int dayIndex = 0; dayIndex < days.length; dayIndex++) {
            final dayList = days[dayIndex];

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

    Map<String, List<CSVLogModel>> _groupLogsByUserId(List<CSVLogModel> logs) {
        final map = <String, List<CSVLogModel>>{};
        for (final l in logs) {
            final uid = l.userId;
            if (uid == null || uid.isEmpty) continue;
            (map[uid] ??= <CSVLogModel>[]).add(l);
        }

        // Optional: sort logs newest first if you have a parseable createdAt
        // map.forEach((k, v) => v.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? '')));

        return map;
    }

    //#region TRACKING ISSUES
    List<ErrorIncident> errorIncidents = [];
    List<UserRecoverySummary> userRecoverySummaries = [];

    /// Call this AFTER logList is ready
    void analyzeSyncRecovery({Duration window = const Duration(minutes: 1440)}) {
        // 1) build incidents (error -> recovered or not)
        errorIncidents = IssueTracker.instance.analyzeRecoveryForAllUsers(
            logList,
            window: window,
        );

        // 2) summarize by user
        userRecoverySummaries = IssueTracker.instance.summarizeRecoveryByUser(errorIncidents);

        print('Analyze done: ${errorIncidents.length} incidents, '
            '${userRecoverySummaries.length} users');
    }
    //#endregion

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