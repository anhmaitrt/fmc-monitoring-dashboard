import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/services/toast_service.dart';
import 'package:fmc_monitoring_dashboard/core/routing/router.dart';
import 'package:fmc_monitoring_dashboard/core/services/google_drive_service.dart';
import 'package:fmc_monitoring_dashboard/feature/home/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../../core/services/google_service.dart';
import '../file/total_cgm_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleService _googleService = GoogleService.instance;

  @override
  void initState() {
    super.initState();
    _googleService.googleSignIn.authenticationEvents.listen((event) async  {
      setState(() async {
        var user = switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          _ => null,
        };

        print("Authentication event: $event");

        if (user == null) {
          print('Login failed');
          ToastService.show(
            context, 'Đăng nhập thất bại', type: ToastType.error,);
          return;
        } else {
          final authenticated = await GoogleDriveService.instance.authorizeUser(user);
          if(!authenticated){
            ToastService.show(context, 'Không xác thực được Google Drive', type: ToastType.success);
            return;
          }

          // ToastWidget.instance.showSuccess('Welcome ${user.displayName}');
          context.navigateTo(TotalCGMScreen(), replace: true);
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (await GoogleService.instance.signIn() != null) {
        print('Log in to previous session');
        context.navigateTo(TotalCGMScreen(), replace: true);
      }
    },);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng Nhập'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            web.renderButton(),
          ],
        ),
      ),
    );
  }
}
