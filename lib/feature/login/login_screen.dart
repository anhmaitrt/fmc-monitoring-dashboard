import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/toast/toast_widget.dart';
import 'package:fmc_monitoring_dashboard/core/routing/router.dart';
import 'package:fmc_monitoring_dashboard/feature/home/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../../services/drive_service.dart';

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
      setState(() {

        var user = switch (event) {
          GoogleSignInAuthenticationEventSignIn() => event.user,
          _ => null,
        };

        print("Authentication event: $event");

        if (user == null) {
          print('Login failed');
          ToastWidget.instance.showError('Đăng nhập thất bại');
          return;
        } else {
          context.navigateTo(HomeScreen(), replace: true);
          print('Login success: $user');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoring Dashboard'),
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
