

import 'dart:io' as drive;

import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/overview_table.dart';

import '../../core/services/google_service.dart';
import '../file/total_cgm_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleService _googleService = GoogleService.instance;
  // bool _isAuthenticated = false;
  bool _dataReady = false;

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   try {
    //     await GoogleService.instance.fetchDB();
    //     setState(() {
    //       _dataReady = true;
    //     });
    //   } catch (error, stackTrace) {
    //     print('Failed to fetch DB: $error');
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoring Board'),
      ),
      body: _buildBody(),
    );
  }

  //#region UI
  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Text('Menu'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Overview'),
              // selected: selected == 0,
              // onTap: () {
              //   Navigator.pop(context);
              //   context.go('/overview');
              // },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Tổng CGM'),
              // selected: selected == 1,
              // onTap: () {
              //   Navigator.pop(context);
              //   context.go('/files');
              // },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              // selected: selected == 2,
              // onTap: () {
              //   Navigator.pop(context);
              //   context.go('/settings');
              // },
            ),
          ],
        ),
      ),
    );
  }

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
        Expanded(child: TotalCGMScreen())
      ],
    );
  }
  //#endregion
}