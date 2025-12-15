

import 'dart:io' as drive;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/chart/line_chart_widget.dart';
import 'package:fmc_monitoring_dashboard/core/components/table/overview_table.dart';
import 'package:fmc_monitoring_dashboard/core/components/side_bar_widget.dart';
import 'package:fmc_monitoring_dashboard/core/services/analytic_service.dart';
import 'package:fmc_monitoring_dashboard/model/total_cgm_file.dart';
import 'package:sidebarx/sidebarx.dart';

import '../../core/services/google_service.dart';
import '../../core/style/app_colors.dart';
import '../file/total_cgm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleService _googleService = GoogleService.instance;
  // bool _isAuthenticated = false;
  bool _dataReady = false;

  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  final _key = GlobalKey<ScaffoldState>();

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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            // width: 100,
            child: _buildTotalCGM()
          )
        ],
      ),
    );
  }

  //#region UI
  Widget _buildTotalCGM() {
    return LineChartWidget(
      chartName: 'Số lượng khách dùng CGM',
      maxX: AnalyticService.instance.totalCGMFiles.maxX,
      maxY: AnalyticService.instance.totalCGMFiles.maxY,
      xTitle: AnalyticService.instance.totalCGMFiles.toDateList(),
      yTitle: [],
      lineData1: AnalyticService.instance.totalCGMFiles.splitByPlatform('android'),
      lineData2: AnalyticService.instance.totalCGMFiles.splitByPlatform('ios'),
    );
  }
  //#endregion
}