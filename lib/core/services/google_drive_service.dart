import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:fmc_monitoring_dashboard/core/services/toast_service.dart';
import 'package:fmc_monitoring_dashboard/feature/app.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveService {
    GoogleDriveService._();

    static GoogleDriveService instance = GoogleDriveService._();
    drive.DriveApi? _driveApi;
    final _scopes = [drive.DriveApi.driveScope];

    Future<bool> authorizeUser(GoogleSignInAccount account) async {
        try {
            final authorization = await account!.authorizationClient
                .authorizeScopes(_scopes);
            print('Get file, authorization: $authorization');
            // if(authorization?.)
            _driveApi = drive.DriveApi(authorization.authClient(
                scopes: _scopes,
            ));
            if (_driveApi == null) {
                print('Not authenticated');
                // throw Exception("Not authenticated");
                return false;
            }
            return true;
        } catch (error, stackTrace) {
            print('Failed to authorize google drive for ${account.displayName}');
            return false;
        }
    }

    Future<List<drive.File>> readFolder(String folderId, {int pageSize = 30}) async {
        try {
            final result = (await _driveApi!.files.list(
                q: "'$folderId' in parents and trashed=false", // Query to get files from the folder
                $fields: "files(id,name)", // Fields to retrieve
                pageSize: pageSize
            )).files ?? [];
            print('Read ${result.length} files from folder $folderId');
            return result;
        } catch (error, stackTrace) {
            print('Failed to read folder $folderId: $error\nstackTrace: $stackTrace');
            return List.empty();
        }
    }
    // Google Sheets mime type

    Future<List<drive.File>> readFolderSheetsOnly(String folderId, {int pageSize = 60}) async {
        final sheetMime = 'application/vnd.google-apps.spreadsheet';
        final res = await _driveApi?.files.list(
            q: "'$folderId' in parents and trashed=false and mimeType='$sheetMime'",
            $fields: 'files(id,name,mimeType,modifiedTime)',
            pageSize: 1000,
            supportsAllDrives: true,
            includeItemsFromAllDrives: true,
        );
        return res?.files ?? <drive.File>[];
    }

    Future<String> getFileContent(drive.File file) async {
        if (_driveApi == null) throw Exception("Drive api have not been initialized");
        // print('Getting content for file ${file.name}: ${file.id}, ${file.description}');
        var response = await _driveApi!.files.get(
            file.id!,
            downloadOptions: drive.DownloadOptions.fullMedia,
        );
        if (response is! drive.Media) throw Exception("invalid response");
        var content = await utf8.decodeStream(response.stream);
        // print('File ${file.name} content: $content');
        return content;
    }

    Future<Iterable<Map<String, dynamic>>> getJsonContent(drive.File file) async {
        try {
            final content = await getFileContent(file);

            // Decode
            final decoded = jsonDecode(content);

            if (decoded is! List) {
                throw Exception('Invalid JSON in ${file.name}: ${decoded.runtimeType}');
            }

            return decoded.whereType<Map<String, dynamic>>();
        } catch (error, stackTrace) {
            ToastService.show('Lỗi đọc file json ${file.name} từ drive, vui lòng thử lại', type: ToastType.error);
            return List.empty();
        }
    }

    List<List<dynamic>> getCsvContent(String csvContent) {
        return const CsvToListConverter(
            eol: '\n',
            shouldParseNumbers: false,
        ).convert(csvContent);
    }

    Future<String> exportGoogleSheetAsCsv(String fileId) async {
        final api = _driveApi;
        if (api == null) throw StateError('Drive API not initialized');

        final drive.Media media = await api.files.export(
            fileId,
            'text/csv',
            downloadOptions: drive.DownloadOptions.fullMedia, // ✅ adds alt=media
        ) as drive.Media;

        // ✅ Stream -> String (UTF-8 safe)
        return await media.stream.transform(utf8.decoder).join();
    }
}