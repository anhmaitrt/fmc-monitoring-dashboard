import 'dart:convert';

import '../../model/user_cgm_file.dart';
import 'google_drive_service.dart';

class AnalyticService {
    AnalyticService._();

    static AnalyticService instance = AnalyticService._();

    final String DATA_FOLDER = '1yMrZnw2BfQsICvu-Cfb44xsEMU3-w9fQ';
    // final String TOTAL_CGM_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';
    // final String SLOW_SYNC_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';
    // final String CGM_DATA_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';

    List<List<UserCGMFile>> dataFiles = List.empty(growable: true);
    // List<List<TotalCgmFile>> slowSyncFiles = List.empty(growable: true);
    // List<List<TotalCgmFile>> cgmDataFiles = List.empty(growable: true);

    // Get list of files from the specified Google Drive folder
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

            // rawFiles = rawFiles.reversed.toList();
            for (final file in rawFiles) {
                final content =
                await GoogleDriveService.instance.getFileContent(file);

                final decoded = jsonDecode(content);

                // Case 1: file is a LIST of user objects
                if (decoded is List) {
                    final models = decoded
                        .whereType<Map<String, dynamic>>()
                        .map((m) {
                          var model = UserCGMFile.fromJson(m);
                          model.fileName = file.name;
                          return model;
                        })
                        .toList();

                    dataFiles.add(models);
                    print('Converted ${models.length} users from ${file.name}');
                    continue;
                }

                // Case 2: file is a single user object
                if (decoded is Map<String, dynamic>) {
                    final model = UserCGMFile.fromJson(decoded);
                    model.fileName = file.name;

                    dataFiles.add([model]);
                    print('Converted 1 user from ${file.name}');
                    continue;
                }

                // Unknown format
                throw Exception('Invalid JSON in ${file.name}: ${decoded.runtimeType}');
            }

            print('Fetched ${dataFiles.length} files for CGM data');
        } catch (e, st) {
            print('Failed to fetch total cgm data: $e\n$st');
        }
    }



        // Future<void> _fetchSlowSync() async {
    //     try {
    //         var rawFiles = await GoogleDriveService.instance.readFolder(SLOW_SYNC_FOLDER);
    //
    //         rawFiles.forEach((file) async {
    //             var content = await GoogleDriveService.instance.getFileContent(file);
    //
    //             // Map the parsed data into a list of TotalCgmFile objects
    //             slowSyncFiles.add(jsonDecode(content).map<TotalCgmFile>((data) {
    //                 var model = TotalCgmFile(
    //                     fileName: data[0],  // File ID
    //                     id: data[0],        // File ID (same as fileName)
    //                     phoneNumber: data[1], // Phone number
    //                     name: data[2],      // Name
    //                     platform: data[3],  // Platform (ios/android)
    //                     isDeleted: data[4], // Deleted flag (true/false)
    //                     startDate: data[5], // Start date
    //                     endDate: data[6],   // End date
    //                 );
    //                 // print('Parse to model: $model');
    //                 return model;
    //             }).toList());
    //         });
    //     } catch (error, stackTrace) {
    //         print("Failed to fetch slow sync data: $error");
    //     }
    // }
    //
    // Future<void> _fetchCGMData() async {
    //     try {
    //         var rawFiles = await GoogleDriveService.instance.readFolder(CGM_DATA_FOLDER);
    //
    //         rawFiles.forEach((file) async {
    //             var content = await GoogleDriveService.instance.getFileContent(file);
    //
    //             // Map the parsed data into a list of TotalCgmFile objects
    //             totalCGMFiles.add(jsonDecode(content).map<TotalCgmFile>((data) {
    //                 var model = TotalCgmFile(
    //                     fileName: data[0],  // File ID
    //                     id: data[0],        // File ID (same as fileName)
    //                     phoneNumber: data[1], // Phone number
    //                     name: data[2],      // Name
    //                     platform: data[3],  // Platform (ios/android)
    //                     isDeleted: data[4], // Deleted flag (true/false)
    //                     startDate: data[5], // Start date
    //                     endDate: data[6],   // End date
    //                 );
    //                 // print('Parse to model: $model');
    //                 return model;
    //             }).toList());
    //         });
    //     } catch (error, stackTrace) {
    //         print("Failed to fetch user cgm data: $error");
    //     }
    // }
}