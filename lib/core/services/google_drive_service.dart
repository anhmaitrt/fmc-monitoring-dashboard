import 'dart:convert';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
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

    Future<List<drive.File>> readFolder(String folderId) async {
        try {
            final result = (await _driveApi!.files.list(
                q: "'$folderId' in parents", // Query to get files from the folder
                $fields: "files(id,name)", // Fields to retrieve
            )).files ?? [];
            print('Read ${result.length} files from folder $folderId');
            return result;
        } catch (error, stackTrace) {
            print('Failed to read folder $folderId: $error\nstackTrace: $stackTrace');
            return List.empty();
        }
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
}