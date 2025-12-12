import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/feature/home/home_screen.dart';
import 'package:fmc_monitoring_dashboard/feature/login/login_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Center(child:
        LoginScreen()
      ),
    );
  }
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();