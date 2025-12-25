import 'dart:async';
import 'dart:convert';

import '../../model/user_cgm_file.dart';
import '../components/toast/model/loading_progress.dart';
import 'google_drive_service.dart';

class AnalyticService {
    AnalyticService._();

    static AnalyticService instance = AnalyticService._();

    final String DATA_FOLDER = '1yMrZnw2BfQsICvu-Cfb44xsEMU3-w9fQ';

    final _progressController = StreamController<LoadingProgress>.broadcast();
    Stream<LoadingProgress> get progressStream => _progressController.stream;

    List<List<UserCGMFile>> dataFiles = List.empty(growable: true);

    void _emit(LoadingProgress p) {
        if (!_progressController.isClosed) _progressController.add(p);
    }

    Future<void> fetchDB() async {
        try {
            final result = await Future.wait([
                _fetchData(),
                // _fetchSlowSync(),
                // _fetchCGMData(),
            ]);

        } catch (e, stackTrace) {
            print("Error getting files: $e\n$stackTrace");
            rethrow;
        }
    }

    // Future<void> _fetchData() async {
    //     try {
    //         dataFiles.clear();
    //
    //         var rawFiles = await GoogleDriveService.instance.readFolder(DATA_FOLDER);
    //
    //         _emit(LoadingProgress(isLoading: true, current: 0, total: rawFiles.length));
    //
    //         for(int i = 0; i < rawFiles.length; i++) {
    //             final file = rawFiles[i];
    //             _emit(LoadingProgress(
    //                 isLoading: true,
    //                 current: i + 1,
    //                 total: rawFiles.length,
    //                 fileName: file.name,
    //             ));
    //
    //             final content = await GoogleDriveService.instance.getFileContent(file);
    //
    //             final decoded = jsonDecode(content);
    //
    //             // Case 1: file is a LIST of user objects
    //             if (decoded is List) {
    //                 final jsonList = decoded
    //                     .whereType<Map<String, dynamic>>();
    //                 final models = <UserCGMFile>[];
    //                 jsonList.forEach((j) {
    //                     final model = UserCGMFile.fromJson(j);
    //                     model.fileName = file.name;
    //                     if(!(model.phoneNumber?.contains('demo') ?? false)) {
    //                         models.add(model);
    //                     }/* else {
    //                         print('Detect demo user: ${model.fullName}, skip adding');
    //                     }*/
    //                 });
    //
    //                 dataFiles.add(models);
    //                 // print('Converted ${models.length} users from ${file.name}');
    //                 continue;
    //             }
    //
    //             throw Exception('Invalid JSON in ${file.name}: ${decoded.runtimeType}');
    //         }
    //         dataFiles.sort((a, b) {
    //             final da = a.firstOrNull!.dateTime;
    //             final db = b.firstOrNull!.dateTime;
    //             if (da == null || db == null) return 0;
    //             return db.compareTo(da); // DESC
    //         });
    //         print('Fetched ${dataFiles.length} files for CGM data');
    //     } catch (e, st) {
    //         print('Failed to fetch total cgm data: $e\n$st');
    //     } finally {
    //         _emit(LoadingProgress.idle);
    //     }
    // }

    Future<void> _fetchData() async {
        try {
            dataFiles.clear();

            final rawFiles = await GoogleDriveService.instance.readFolder(DATA_FOLDER);

            // sort files first (optional): newest first by filename date
            // rawFiles.sort((a, b) {
            //     final da = _dateFromFileName(a.name);
            //     final db = _dateFromFileName(b.name);
            //     if (da == null || db == null) return 0;
            //     return db.compareTo(da);
            // });

            final total = rawFiles.length;
            var completed = 0;

            _emit(LoadingProgress(isLoading: true, current: 0, total: total));

            // results holder with stable order
            final results = List<List<UserCGMFile>?>.filled(total, null);

            // ⚠️ tune this: 3–8 is typical for web
            const concurrency = 5;

            await _runPool(
                items: rawFiles,
                concurrency: concurrency,
                task: (file, index) async {
                    // Download
                    final content = await GoogleDriveService.instance.getFileContent(file);

                    // Decode
                    final decoded = jsonDecode(content);

                    if (decoded is! List) {
                        throw Exception('Invalid JSON in ${file.name}: ${decoded.runtimeType}');
                    }

                    // Map
                    final jsonList = decoded.whereType<Map<String, dynamic>>();
                    final models = <UserCGMFile>[];

                    for (final j in jsonList) {
                        final model = UserCGMFile.fromJson(j);

                        // If fileName is final in your model, use copyWith instead:
                        // final model2 = model.copyWith(fileName: file.name);
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
            dataFiles.addAll(results.whereType<List<UserCGMFile>>());

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



    Future<void> _convertUserCGMFiles() async {
        try {
        } catch (error, stackTrace) {
            print('Failed to convert user cgm files: $error\n$stackTrace');
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