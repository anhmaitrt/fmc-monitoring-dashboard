import 'dart:async';
import 'dart:io' as drive;

import 'package:flutter/material.dart';
import 'core/services/google_service.dart';
import 'feature/app.dart';

void main() {
  unawaited(
    runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();
      GoogleService.instance.initialize();
      runApp(MyApp());
    }, (error, stackTrace) async {
      print('Error when init App : $error');
      // Logger.e(
      //   'Error when init App : $error',
      //   stackTrace: stackTrace,
      // );
    }),
  );
}