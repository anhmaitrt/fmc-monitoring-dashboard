import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/feature/home/home_screen.dart';
import 'package:fmc_monitoring_dashboard/feature/login/login_screen.dart';

import '../core/components/toast/loading_widget.dart';
import '../core/services/analytic_service.dart';
import '../core/style/app_colors.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, // primary seed
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      home: Center(child:
          Stack(
            children: [
              LoginScreen(),
              LoadingOverlay(
                progressStream: AnalyticService.instance.progressStream,
              )
            ],
          )
      ),
    );
  }
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();