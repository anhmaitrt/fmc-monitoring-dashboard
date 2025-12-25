import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/chart/line_chart_widget.dart';
import 'package:fmc_monitoring_dashboard/core/services/analytic_service.dart';
import 'package:fmc_monitoring_dashboard/core/services/toast_service.dart';
import 'package:fmc_monitoring_dashboard/model/user_cgm_file.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final data = AnalyticService.instance.dataFiles.reversed.toList();
    final androidUsers = data.splitByPlatform('android');
    final iosUsers = data.splitByPlatform('ios');

    return SizedBox(
      height: double.infinity,
      child: RefreshIndicator(
        onRefresh: () => fetchData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: 350,
                child: _buildTotalCGMChart(data, androidUsers, iosUsers)
              ),
              Container(
                height: 350,
                margin: EdgeInsets.only(top: 24),
                child: _buildInterruptionChart(data, androidUsers, iosUsers)
              )
            ],
          ),
        ),
      ),
    );
  }

  //#region UI
  Widget _buildTotalCGMChart(
      List<List<UserCGMFile>> data,
      List<List<UserCGMFile>> androidUsers,
      List<List<UserCGMFile>> iosUser,
  ) {
    final topTitles = <String>[];
    for(int i = 0; i < data.length; i++) {
      topTitles.add((androidUsers.count()[i] + iosUser.count()[i]).toString());
    }
    return LineChartWidget(
      chartName: 'Số lượng khách dùng CGM',
      maxX: data.maxX,
      maxY: data.maxY,
      topTitles: topTitles,
      bottomTitles: data.toDateList(),
      leftTitles: [],
      lineDataList: [androidUsers.count(), iosUser.count()],
      lineTitleList: ['android', 'ios'],
    );
  }

  Widget _buildInterruptionChart(
      List<List<UserCGMFile>> data,
      List<List<UserCGMFile>> androidUsers,
      List<List<UserCGMFile>> iosUser,
  ) {
    final androidPercentageInterruptionList = androidUsers.map((f) => f.percentageInterruption).toList();
    final iosPercentageInterruptionList = iosUser.map((f) => f.percentageInterruption).toList();

    // print('android user: ${androidUsers.length} - $androidPercentageInterruptionList'
    //     '\nios user: ${iosUser.length} - $iosPercentageInterruptionList');
    return LineChartWidget(
      chartName: 'Tỉ lệ chậm đồng bộ theo ngày (%)',
      maxX: data.maxX,
      maxY: [...androidPercentageInterruptionList, ...iosPercentageInterruptionList].reduce(max),
      topTitles: [],
      bottomTitles: data.toDateList(),
      leftTitles: [],
      lineDataList: [androidPercentageInterruptionList, iosPercentageInterruptionList],
      lineTitleList: ['android', 'ios'],
    );
  }
  //#endregion

  //#region ACTION
  Future<void> fetchData() async {
    try {
      ToastService.show(context, 'Đang tải dữ liệu...');
      await AnalyticService.instance.fetchDB();
      ToastService.hide();
    } catch (error, stackTrace) {
      ToastService.show(context, 'Tải dữ liệu không thành công: $error');
    }
  }
  //#endregion
}