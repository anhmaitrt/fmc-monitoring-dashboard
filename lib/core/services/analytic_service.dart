import 'dart:convert';

import '../../model/total_cgm_file.dart';
import 'google_drive_service.dart';

class AnalyticService {
    AnalyticService._();

    static AnalyticService instance = AnalyticService._();

    final String TOTAL_CGM_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';
    final String SLOW_SYNC_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';
    final String CGM_DATA_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';

    List<List<TotalCgmFile>> totalCGMFiles = List.empty(growable: true);
    List<List<TotalCgmFile>> slowSyncFiles = List.empty(growable: true);
    List<List<TotalCgmFile>> cgmDataFiles = List.empty(growable: true);

    // Get list of files from the specified Google Drive folder
    Future<void> fetchDB() async {
        try {
            final result = await Future.wait([
                _fetchTotalCGM(),
                // _fetchSlowSync(),
                // _fetchCGMData(),
            ]);

        } catch (e, stackTrace) {
            print("Error getting files: $e\n$stackTrace");
            rethrow;
        }
    }

    Future<void> _fetchTotalCGM() async {
        try {
            totalCGMFiles.clear();
            var rawFiles = await GoogleDriveService.instance.readFolder(TOTAL_CGM_FOLDER);

            for(int i = 0; i < rawFiles.length; i++) {
                var content = await GoogleDriveService.instance.getFileContent(rawFiles[i]);

                final convertedModels = jsonDecode(content).map<TotalCgmFile>((data) {
                    var model = TotalCgmFile(
                        fileName: rawFiles[i].name,
                        id: data[0],
                        phoneNumber: data[1],
                        name: data[2],
                        platform: data[3],
                        isDeleted: data[4],
                        startDate: data[5],
                        endDate: data[6],
                    );
                    // print('Parse to model: $model');
                    return model;
                }).toList();

                print('Converted ${convertedModels.length} models for file ${rawFiles[i].name}');
                totalCGMFiles.add(convertedModels);
            }
            print('Fetched ${totalCGMFiles.length} files for total cgm data');
        } catch (error, stackTrace) {
            print("Failed to fetch total cgm data: $error");
        }
    }

    Future<void> _fetchSlowSync() async {
        try {
            var rawFiles = await GoogleDriveService.instance.readFolder(SLOW_SYNC_FOLDER);

            rawFiles.forEach((file) async {
                var content = await GoogleDriveService.instance.getFileContent(file);

                // Map the parsed data into a list of TotalCgmFile objects
                slowSyncFiles.add(jsonDecode(content).map<TotalCgmFile>((data) {
                    var model = TotalCgmFile(
                        fileName: data[0],  // File ID
                        id: data[0],        // File ID (same as fileName)
                        phoneNumber: data[1], // Phone number
                        name: data[2],      // Name
                        platform: data[3],  // Platform (ios/android)
                        isDeleted: data[4], // Deleted flag (true/false)
                        startDate: data[5], // Start date
                        endDate: data[6],   // End date
                    );
                    // print('Parse to model: $model');
                    return model;
                }).toList());
            });
        } catch (error, stackTrace) {
            print("Failed to fetch slow sync data: $error");
        }
    }

    Future<void> _fetchCGMData() async {
        try {
            var rawFiles = await GoogleDriveService.instance.readFolder(CGM_DATA_FOLDER);

            rawFiles.forEach((file) async {
                var content = await GoogleDriveService.instance.getFileContent(file);

                // Map the parsed data into a list of TotalCgmFile objects
                totalCGMFiles.add(jsonDecode(content).map<TotalCgmFile>((data) {
                    var model = TotalCgmFile(
                        fileName: data[0],  // File ID
                        id: data[0],        // File ID (same as fileName)
                        phoneNumber: data[1], // Phone number
                        name: data[2],      // Name
                        platform: data[3],  // Platform (ios/android)
                        isDeleted: data[4], // Deleted flag (true/false)
                        startDate: data[5], // Start date
                        endDate: data[6],   // End date
                    );
                    // print('Parse to model: $model');
                    return model;
                }).toList());
            });
        } catch (error, stackTrace) {
            print("Failed to fetch user cgm data: $error");
        }
    }
}