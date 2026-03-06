import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/scaffold_widget.dart';
import 'package:fmc_monitoring_dashboard/core/services/analytic_service.dart';
import 'package:fmc_monitoring_dashboard/core/services/toast_service.dart';
import 'package:fmc_monitoring_dashboard/core/routing/router.dart';
import 'package:fmc_monitoring_dashboard/core/services/google_drive_service.dart';
import 'package:fmc_monitoring_dashboard/feature/app_navigation_widget.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

import '../../core/services/google_service.dart';

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
    _googleService.googleSignIn.authenticationEvents.listen((event) async {
      final user = switch (event) {
        GoogleSignInAuthenticationEventSignIn() => event.user,
        _ => null,
      };

      // print("Authentication event: $event");

      if (user == null) {
        if (!mounted) return;
        ToastService.show(
          context: context,
          'Đăng nhập thất bại',
          type: ToastType.error,
        );
        return;
      } else {
        final authenticated = await GoogleDriveService.instance.authorizeUser(
          user,
        );
        if (!authenticated) {
          if (!mounted) return;
          ToastService.show(
            context: context,
            'Không xác thực được Google Drive',
            type: ToastType.error,
          );
          return;
        }

        unawaited(_onLoginSuccess());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final user = await GoogleService.instance.signIn();
      if (user != null) {
        // print('Log in to previous session');
        final authenticated = await GoogleDriveService.instance.authorizeUser(
          user,
        );
        if (!authenticated) {
          if (mounted) {
            ToastService.show(
              context: context,
              'Không xác thực được Google Drive (Tự động đăng nhập)',
              type: ToastType.error,
            );
          }
          return;
        }
        unawaited(_onLoginSuccess());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      title: 'Đăng Nhập',
      automaticallyImplyLeading: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [web.renderButton()],
        ),
      ),
    );
  }

  //#region ACTION
  Future<void> _onLoginSuccess() async {
    await AnalyticService.instance.fetchDB();
    if (!mounted) return;
    unawaited(context.navigateTo(const AppNavigationWidget(), replace: true));
  }

  //#endregion
}
