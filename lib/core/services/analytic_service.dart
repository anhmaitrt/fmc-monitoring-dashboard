import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';

import '../../model/log/csv_log_model.dart';
import '../../model/log/log_file.dart';
import '../../model/user_cgm_data_row.dart';
import '../../model/user_model.dart';
import '../components/toast/model/loading_progress.dart';
import 'google_drive_service.dart';
import 'issue_tracker/issue_tracker.dart';

class AnalyticService {
    AnalyticService._();
    static AnalyticService instance = AnalyticService._();

    final String DATA_FOLDER = '1yMrZnw2BfQsICvu-Cfb44xsEMU3-w9fQ';
    final String DAILY_REPORT_FOLDER = '1XhM2MQI1Ezk5ppEMaf1znyXc10mfIrHP';
    final String LOGS_FOLDER = '1FgMblKF_Mz6Wg9Zl8xSJfKEpOnzfX-ox';
    // final String LOGS_FOLDER = '1S8iU2jcafvDI-VHf_Oz7b2ZLyQjfzhjN'; //Test log folder
    final String CONFIGS_FOLDER = '13AEi0JRNteZIhkF7q8T9_YN07UTp_jhP';

    // ⚠️ tune this: 3–10 is typical for web
    final _concurrency = 10;

    final _progressController = StreamController<LoadingProgress>.broadcast();
    Stream<LoadingProgress> get progressStream => _progressController.stream;

    final userList = List<UserModel>.empty(growable: true);
    final dataFiles = List<List<UserCGMDataRow>>.empty(growable: true);
    final dailyReportFiles = List<List<UserCGMDataRow>>.empty(growable: true);
    final logList = List<CSVLogModel>.empty(growable: true);

    // (optional) other configs, not VIP
    final configs = <String, String>{};

    void _emit(LoadingProgress p) {
        if (!_progressController.isClosed) _progressController.add(p);
    }

    // -----------------------
    // PHONE NORMALIZE (for VIP matching)
    // -----------------------
    String? _normalizePhone(String? input) {
        if (input == null) return null;
        var d = input.replaceAll(RegExp(r'[^0-9]'), '');
        if (d.isEmpty) return null;

        // +84xxxxxxxxx / 84xxxxxxxxx -> 0xxxxxxxxx
        if (d.startsWith('84') && d.length >= 10) {
            d = '0${d.substring(2)}';
        }
        return d;
    }

    // -----------------------
    // FETCH ALL
    // -----------------------
    Future<void> fetchDB() async {
        try {
            // ✅ do configs first and keep VIP map in-memory ONLY during this fetch
            final vipNoteByPhone = await _fetchConfigsVipNoteByPhone();

            await Future.wait([
                _fetchLogs(),
                _fetchUsersCGMData(),
                _fetchDailyReport(),
            ]);

            _buildUserList(vipNoteByPhone: vipNoteByPhone);

            // optional: mark rows.isVip using built userList (no vip list stored in service)
            _applyVipFlagToRows();

            analyzeSyncRecovery(window: const Duration(minutes: 1440));
        } catch (e, stackTrace) {
            print('Error getting files: $e\n$stackTrace');
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

                        if (!(model.phoneNumber?.contains('demo') ?? false) && !(model.phoneNumber?.contains('deleted') ?? false)) {
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

    Future<void> _fetchDailyReport() async {
        try {
            dailyReportFiles.clear();

            final rawFiles = await GoogleDriveService.instance.readFolder(DAILY_REPORT_FOLDER);
            final total = rawFiles.length;
            var completed = 0;

            _emit(LoadingProgress(isLoading: true, current: 0, total: total));

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

            dailyReportFiles.addAll(results.whereType<List<UserCGMDataRow>>());

            // Sort by day DESC
            dailyReportFiles.sort((a, b) {
                final da = a.firstOrNull?.dateTime;
                final db = b.firstOrNull?.dateTime;
                if (da == null || db == null) return 0;
                return db.compareTo(da);
            });

            print('Fetched ${dailyReportFiles.firstOrNull?.length} files for daily report');
        } catch (e, st) {
            print('Failed to fetch daily report: $e\n$st');
        } finally {
            _emit(LoadingProgress.idle);
        }
    }

    Future<void> _fetchLogs() async {
        try {
            logList.clear();

            final files = await GoogleDriveService.instance.readFolder(LOGS_FOLDER);

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

                    print('Fetching ${rows.length} raw logs from ${file.name}...');
                    for (int i = 0; i < rows[0].length; i++) {
                        final col = rows[0][i];
                        // print('Col $i: $col, ${col.contains('gen_time')}, ${col.contains('message')}, ${col.contains('user_id')}');
                        if (col.contains('@timestamp')) createdAtColumnIndex = i;
                        if (col.contains('request_body')) messageColumnIndex = i;
                        if (col.contains('user_id')) userIdColumnIndex = i;
                        // if (col.contains('gen_time')) createdAtColumnIndex = i;
                        // if (col.contains('message')) messageColumnIndex = i;
                        // if (col.contains('user_id')) userIdColumnIndex = i;
                    }

                    print('Col index createdAt: $createdAtColumnIndex, userId: $userIdColumnIndex, message: $messageColumnIndex');
                    final fileLogs = <CSVLogModel>[];

                    for (int r = 1; r < rows.length; r++) {
                        final messageJsonString =
                        (messageColumnIndex != -1) ? rows[r][messageColumnIndex] : null;

                        // print('Message: $messageJsonString');
                        if (messageJsonString == null || messageJsonString.isEmpty) continue;

                        LogFile? message;
                        try {
                            final json = jsonDecode(messageJsonString);

                            // print('Message json: $json');
                            message = LogFile.fromJson(json);
                        } catch (e, stackTrace) {
                            print('Failed to parse messageJString: $messageJsonString\n--Error: $e\nstackTrace: $stackTrace');
                            continue;
                        }

                        final userId = (userIdColumnIndex != -1) ? rows[r][userIdColumnIndex] : null;

                        fileLogs.add(CSVLogModel(
                            createdAt: (createdAtColumnIndex != -1) ? rows[r][createdAtColumnIndex] : null,
                            log: message.logs.firstOrNull,
                            userId: userId,
                        ));
                        // await Future.delayed(const Duration(milliseconds: 50));
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

    /// ✅ Read configs folder (Google Sheets), and return only VIP lookup map:
    /// key = normalized phone, value = note (can be '')
    ///
    /// No vipPhoneList / vipNote stored on service anymore.
    Future<Map<String, String>> _fetchConfigsVipNoteByPhone() async {
        final vipNoteByPhone = <String, String>{};

        try {
            final files = await GoogleDriveService.instance.readFolderSheetsOnly(CONFIGS_FOLDER);
            if (files.isEmpty) return vipNoteByPhone;

            configs.clear();

            await _runPool(
                items: files,
                concurrency: _concurrency,
                task: (file, index) async {
                    final fileId = file.id;
                    if (fileId == null) return;

                    final csvText = await GoogleDriveService.instance.exportGoogleSheetAsCsv(fileId);
                    final rows = GoogleDriveService.instance.getCsvContent(csvText);
                    if (rows.isEmpty) return;

                    final name = (file.name ?? '').trim().toLowerCase();

                    // ---- VIP sheet: col A phone, col B note (optional)
                    if (name == 'vip') {
                        for (int r = 0; r < rows.length; r++) {
                            final row = rows[r];
                            if (row.isEmpty) continue;

                            final phoneRaw = row[0].trim();
                            if (phoneRaw.isEmpty) continue;

                            // header skip
                            final lower = phoneRaw.toLowerCase();
                            if (r == 0 &&
                                (lower.contains('phone') ||
                                    lower.contains('sdt') ||
                                    lower.contains('số') ||
                                    lower.contains('so'))) {
                                continue;
                            }

                            final note = (row.length > 1) ? row[1].trim() : '';
                            final key = _normalizePhone(phoneRaw) ?? phoneRaw;

                            vipNoteByPhone[key] = note;
                        }
                        return;
                    }

                    // ---- Config sheet (optional): key/value col A/B
                    if (name == 'cấu hình' || name == 'cau hinh') {
                        for (int r = 0; r < rows.length; r++) {
                            final row = rows[r];
                            if (row.length < 2) continue;

                            final key = row[0].trim();
                            final value = row[1].trim();

                            if (key.isEmpty) continue;
                            if (r == 0 && key.toLowerCase().contains('key')) continue;

                            configs[key] = value;
                        }
                        return;
                    }
                },
            );

            print('Done fetching VIP: ${vipNoteByPhone.length} items');
        } catch (e, st) {
            print('Failed to fetch configs: $e\n$st');
        }

        return vipNoteByPhone;
    }

    // -----------------------
    // BUILD USERS + APPLY VIP
    // -----------------------
    void _buildUserList({required Map<String, String> vipNoteByPhone}) {
        userList.clear();

        final dataByUser = dataFiles.groupCgmByUserIdKeepDayIndex(); // Map<uid, List<List<Row>>>
        final logsByUser = logList.groupLogsByUserId();

        // ✅ Precompute a fallback platform per userId (scan dataFiles ONCE, not inside loop)
        final fallbackPlatformByUserId = <String, String>{};
        for (final day in dataFiles) {
            for (final row in day) {
                final uid = row.userId;
                if (uid == null) continue;

                // prefer first non-null platform we see (can switch to "latest" if you want)
                final p = row.platform;
                if (p != null && p.isNotEmpty && !fallbackPlatformByUserId.containsKey(uid)) {
                    fallbackPlatformByUserId[uid] = p;
                }
            }
        }

        final allUserIds = <String>{
            ...dataByUser.keys,
            ...logsByUser.keys,
        };

        for (final userId in allUserIds) {
            final userDays = dataByUser[userId];
            final userLogs = logsByUser[userId];

            final latestData =
            (userDays == null || userDays.isEmpty) ? null : userDays.firstOrNull?.firstOrNull;

            // ✅ platform fallback
            final platform = (latestData?.platform != null && latestData!.platform!.isNotEmpty)
                ? latestData.platform
                : fallbackPlatformByUserId[userId];

            // ✅ VIP now lives in UserModel
            final phoneKey = _normalizePhone(latestData?.phoneNumber);
            final note = (phoneKey == null) ? null : vipNoteByPhone[phoneKey];
            final isVip = note != null;

            final user = UserModel(
                userId: userId,
                phoneNumber: latestData?.phoneNumber,
                fullName: latestData?.fullName,
                platform: platform,
                platformVersion: userLogs?.extractPlatformVersionLatest(),
                deviceModel: userLogs?.extractDeviceModelLatest(),
                appVersion: userLogs?.extractAppVersionLatest(),
                dataFiles: userDays,
                logList: userLogs,
                isVIP: isVip,
                vipNote: note,
            );

            userList.add(user);
        }

        userList.sort((a, b) {
            final an = (a.fullName ?? '').toLowerCase();
            final bn = (b.fullName ?? '').toLowerCase();
            return an.compareTo(bn);
        });
    }

    /// Optional: if your UserCGMDataRow has `isVip` mutable, set it from userList
    void _applyVipFlagToRows() {
        final vipByUserId = <String, bool>{
            for (final u in userList)
                if (u.userId != null) u.userId!: u.isVIP,
        };

        for (final day in dataFiles) {
            for (final row in day) {
                final uid = row.userId;
                if (uid == null) continue;
                row.isVip = vipByUserId[uid] == true;
            }
        }

        for (final day in dailyReportFiles) {
            for (final row in day) {
                final uid = row.userId;
                if (uid == null) continue;
                row.isVip = vipByUserId[uid] == true;
            }
        }
    }

    // -----------------------
    // ISSUES
    // -----------------------
    List<ErrorIncident> errorIncidents = [];
    List<UserRecoverySummary> userRecoverySummaries = [];

    void analyzeSyncRecovery({Duration window = const Duration(minutes: 10)}) {
        errorIncidents = IssueTracker.instance.analyzeRecoveryForAllUsers(
            logList,
            window: window,
        );

        userRecoverySummaries = IssueTracker.instance.summarizeRecoveryByUser(errorIncidents);

        print('Analyze done: ${errorIncidents.length} incidents, ${userRecoverySummaries.length} users');
    }

    // -----------------------
    // POOL
    // -----------------------
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
                await Future<void>.delayed(const Duration(milliseconds: 150));
            }
        });
        await Future.wait(workers);
    }
}