


import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/chart/line_chart_widget.dart';
import 'package:fmc_monitoring_dashboard/core/services/analytic_service.dart';
import 'package:fmc_monitoring_dashboard/model/total_cgm_file.dart';
import 'package:sidebarx/sidebarx.dart';

import '../../core/services/google_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          SizedBox(
            height: 350,
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