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

    Future<void> _fetchData() async {
        try {
            dataFiles.clear();

            var rawFiles = await GoogleDriveService.instance.readFolder(DATA_FOLDER);

            _emit(LoadingProgress(isLoading: true, current: 0, total: rawFiles.length));

            // final result = Future.wait(
            //     rawFiles.map((file) async {
            //
            //     }
            // ));
            for(int i = 0; i < rawFiles.length; i++) {
                final file = rawFiles[i];
                _emit(LoadingProgress(
                    isLoading: true,
                    current: i + 1,
                    total: rawFiles.length,
                    fileName: file.name,
                ));

                final content = await GoogleDriveService.instance.getFileContent(file);

                final decoded = jsonDecode(content);

                // Case 1: file is a LIST of user objects
                if (decoded is List) {
                    final jsonList = decoded
                        .whereType<Map<String, dynamic>>();
                    final models = <UserCGMFile>[];
                    jsonList.forEach((j) {
                        final model = UserCGMFile.fromJson(j);
                        model.fileName = file.name;
                        if(!(model.phoneNumber?.contains('demo') ?? false)) {
                            models.add(model);
                        }/* else {
                            print('Detect demo user: ${model.fullName}, skip adding');
                        }*/
                    });

                    dataFiles.add(models);
                    print('Converted ${models.length} users from ${file.name}');
                    continue;
                }

                // Case 2: file is a single user object
                // if (decoded is Map<String, dynamic>) {
                //     final model = UserCGMFile.fromJson(decoded);
                //     model.fileName = file.name;
                //
                //     dataFiles.add([model]);
                //     print('Converted 1 user from ${file.name}');
                //     continue;
                // }

                // Unknown format
                throw Exception('Invalid JSON in ${file.name}: ${decoded.runtimeType}');
            }
            dataFiles.sort((a, b) {
                final da = a.firstOrNull!.dateTime;
                final db = b.firstOrNull!.dateTime;
                if (da == null || db == null) return 0;
                return db.compareTo(da); // DESC
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
}