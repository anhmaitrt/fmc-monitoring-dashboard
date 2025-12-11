

import 'dart:io' as drive;

import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/data_table_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:googleapis/admob/v1.dart';

import '../../services/drive_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleService _googleService = GoogleService.instance;
  // bool _isAuthenticated = false;
  List<drive.File> _files = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Monitoring Board'),),
      body: _buildBody(),
    );
  }

  //#region UI
  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Files in your folder:"),
        // for (var file in _files)
        //   ListTile(
        //     title: Text(file.path ?? 'No Name'),
        //     subtitle: Text(file.path ?? 'No ID'),
        //   ),
        Expanded(child: DataTableChartPage())
      ],
    );
  }
  //#endregion
}