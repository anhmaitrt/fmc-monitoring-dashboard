import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'env.dart';

class GoogleService {
  GoogleService._();

  static GoogleService instance = GoogleService._();

  // Initialize GoogleSignIn with required scopes
  final googleSignIn = GoogleSignIn.instance;
  final _scopes = [drive.DriveApi.driveScope];

  final String TOTAL_CGM_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';
  final String SLOW_SYNC_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';
  final String CGM_DATA_FOLDER = '1Xvo65poc6a8zNy5puFrInk6xZL-z_5NR';

  List<drive.File> _totalCGMFiles = List.empty();
  List<drive.File> _slowSyncFiles = List.empty();
  List<drive.File> _cgmDataFiles = List.empty();

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;


  // Authenticate and get the Google Drive API client
  Future<void> initialize() async {
    try {
      await googleSignIn.initialize(
        clientId: Env.googleClientKey,
      ).then((_) async {
        googleSignIn.authenticationEvents.listen((event) async  {
          _currentUser = switch (event) {
            GoogleSignInAuthenticationEventSignIn() => event.user,
            _ => null,
          };
        });
      });
    } catch (e) {
      print("Failed to initialize google service: $e");
      rethrow;
    }
  }

  Future<void> signIn() async {
    try {
      // print('Request sign in');
      // final account = await _googleSignIn.attemptLightweightAuthentication();
      // print('Sign in result: $account');
      final retryAccount = await googleSignIn.authenticate();
      print('Sign in result: $retryAccount');
    } catch (error, stackTrace) {
      print('Failed to sign in: $error');
    }
  }

  // Sign out the user
  Future<void> signOut() async {
    await googleSignIn.signOut();
  }

  Future<void> _checkAuthorization() async {
    // Check if the required scopes are already granted
    final GoogleSignInClientAuthorization? authorization = await _currentUser
        ?.authorizationClient
        .authorizationForScopes(_scopes);

    if (authorization == null) {
      // Scopes not granted, prompt the user to authorize
      _authorizeScopes();
    } else {
      print('Scopes already authorized. Access token available.');
      // You can now proceed to use the Drive API with the obtained credentials
      // _accessDriveApi();
    }
  }

  Future<void> _authorizeScopes() async {
    try {
      // This method will display a UI consent screen to the user
      final authorization = await _currentUser?.authorizationClient.authorizeScopes(_scopes);
      print('Scopes authorized via user interaction: $authorization');
      // _accessDriveApi();
    } catch (error) {
      print('Authorization failed: $error');
    }
  }

  // Get list of files from the specified Google Drive folder
  Future<void> fetchDB() async {
    try {
      final authorization = await _currentUser!.authorizationClient
          .authorizeScopes(_scopes);
      print('Get file, authorization: $authorization');
      // if(authorization?.)
      _driveApi = drive.DriveApi(authorization.authClient(
        scopes: _scopes,
      ));
      if (_driveApi == null) {
        throw Exception("Not authenticated");
      }

      _totalCGMFiles = (await _driveApi!.files.list(
        q: "'$TOTAL_CGM_FOLDER' in parents", // Query to get files from the folder
        $fields: "files(id,name)", // Fields to retrieve
      )).files ?? [];

      _slowSyncFiles = (await _driveApi!.files.list(
        q: "'$SLOW_SYNC_FOLDER' in parents", // Query to get files from the folder
        $fields: "files(id,name)", // Fields to retrieve
      )).files ?? [];

      _cgmDataFiles = (await _driveApi!.files.list(
        q: "'$CGM_DATA_FOLDER' in parents", // Query to get files from the folder
        $fields: "files(id,name)", // Fields to retrieve
      )).files ?? [];

    } catch (e, stackTrace) {
      print("Error getting files: $e\n$stackTrace");
      rethrow;
    }
  }

  // Extract folder ID from the Google Drive folder URL
  String extractFolderId(String url) {
    final regex = RegExp(r'\/folders\/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(url);
    if (match != null) {
      return match.group(1)!;
    }
    return '';
  }
}
