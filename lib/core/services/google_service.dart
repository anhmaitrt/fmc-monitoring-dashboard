import 'package:google_sign_in/google_sign_in.dart';

import 'env.dart';

class GoogleService {
  GoogleService._();

  static GoogleService instance = GoogleService._();

  // Initialize GoogleSignIn with required scopes
  final googleSignIn = GoogleSignIn.instance;
  // final _scopes = [drive.DriveApi.driveScope];

  GoogleSignInAccount? currentUser;

  // Authenticate and get the Google Drive API client
  Future<void> initialize() async {
    try {
      await googleSignIn.initialize(
        clientId: Env.googleClientKey,
      ).then((_) async {
        googleSignIn.authenticationEvents.listen((event) async  {
          print('Google service, authentication event: $event');
          currentUser = switch (event) {
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

  Future<GoogleSignInAccount?> signIn() async {
    try {
      // final account = await googleSignIn.attemptLightweightAuthentication();
      currentUser = await googleSignIn.attemptLightweightAuthentication(reportAllExceptions: true);
      print('Sign in result: $currentUser');
      return currentUser;
    } catch (error, stackTrace) {
      print('Failed to sign in: $error');
      return null;
    }
  }

  // Sign out the user
  Future<void> signOut() async {
    await googleSignIn.signOut();
  }
}
