import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/feature/home/home_screen.dart';
import 'package:fmc_monitoring_dashboard/feature/login/login_screen.dart';

import '../core/components/toast/loading_widget.dart';
import '../core/services/analytic_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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