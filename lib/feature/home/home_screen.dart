import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/chart/line_chart_widget.dart';
import 'package:fmc_monitoring_dashboard/core/services/analytic_service.dart';
import 'package:fmc_monitoring_dashboard/core/services/toast_service.dart';
import 'package:fmc_monitoring_dashboard/core/style/app_colors.dart';
import 'package:fmc_monitoring_dashboard/core/style/app_text_styles.dart';
import 'package:fmc_monitoring_dashboard/model/user_cgm_file.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final data = AnalyticService.instance.dataFiles.reversed.toList();
    final androidUsers = data.splitByPlatform('android');
    final iosUsers = data.splitByPlatform('ios');

    return Scaffold(
      appBar: AppBar(
        title: Text('Tổng quan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
        backgroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _fetchData,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              transitionBuilder: (child, animation) {
                return RotationTransition(turns: animation, child: child);
              },
              child: Icon(
                _isLoading ? Icons.autorenew : Icons.refresh_rounded,
                key: ValueKey(_isLoading),
              ),
            ),
          )
        ],
      ),
      body: Container(
        color: AppColors.backgroundDisable,
        height: double.infinity,
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
              ),
              Container(
                height: 380,
                margin: EdgeInsets.only(top: 24),
                child: _buildInterruptionByPercentageRange(data, androidUsers, iosUsers)
              )
            ],
          ),
        ),
      ),
    );
  }

  //#region UI
  Widget _buildChart({required Widget chart}) {
    return Card.filled(
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: chart,
      ),
    );
  }

  Widget _buildTotalCGMChart(
      List<List<UserCGMFile>> data,
      List<List<UserCGMFile>> androidUsers,
      List<List<UserCGMFile>> iosUser,
  ) {
    int limit = 30;
    if(data.length >= limit) {
      data.removeRange(0, data.length-limit);
      androidUsers.removeRange(0, androidUsers.length-limit);
      iosUser.removeRange(0, iosUser.length-limit);
    }

    final topTitles = <String>[];
    for(int i = 0; i < data.length; i++) {
      topTitles.add((androidUsers.count()[i] + iosUser.count()[i]).toString());
    }
    return _buildChart(
      chart: LineChartWidget(
        chartName: 'Số lượng khách dùng CGM',
        maxX: data.maxX,
        maxY: data.maxY,
        topTitles: topTitles,
        bottomTitles: data.toDateList(),
        leftTitles: [],
        lineDataList: [androidUsers.count(), iosUser.count()],
        lineTitleList: ['android', 'ios'],
        subToolTipData: [],
        lineColors: [Colors.lightBlue.shade400, Colors.pinkAccent.shade100],
      ),
    );
  }

  Widget _buildInterruptionChart(
      List<List<UserCGMFile>> data,
      List<List<UserCGMFile>> androidUsers,
      List<List<UserCGMFile>> iosUser,
  ) {
    int limit = 30;
    if(data.length >= limit) {
      data.removeRange(0, data.length-limit);
      androidUsers.removeRange(0, androidUsers.length-limit);
      iosUser.removeRange(0, iosUser.length-limit);
    }
    final androidPercentageInterruptionList = androidUsers.map((f) => f.percentageInterruption).toList();
    final iosPercentageInterruptionList = iosUser.map((f) => f.percentageInterruption).toList();

    // print('android user: ${androidUsers.length} - $androidPercentageInterruptionList'
    //     '\nios user: ${iosUser.length} - $iosPercentageInterruptionList');
    return _buildChart(
        chart: LineChartWidget(
          chartName: 'Tỉ lệ chậm đồng bộ theo ngày (%)',
          maxX: data.maxX,
          maxY: [...androidPercentageInterruptionList, ...iosPercentageInterruptionList].reduce(max),
          topTitles: [],
          bottomTitles: data.toDateList(),
          leftTitles: [],
          lineDataList: [androidPercentageInterruptionList, iosPercentageInterruptionList],
          lineTitleList: ['android', 'ios'],
          subToolTipData: [
            androidUsers.map((f) => '${f.getUserWithLongestGap().fullName} (${f.getUserWithLongestGap().totalGapTimeInHour.toStringAsFixed(1)}h)').toList(),
            iosUser.map((f) => '${f.getUserWithLongestGap().fullName} (${f.getUserWithLongestGap().totalGapTimeInHour.toStringAsFixed(1)}h)').toList()
          ],
          unit: '%',
          lineColors: [Colors.lightBlue.shade400, Colors.pinkAccent.shade100],
        )
    );
  }

  Widget _buildInterruptionByPercentageRange(
      List<List<UserCGMFile>> data,
      List<List<UserCGMFile>> androidUsers,
      List<List<UserCGMFile>> iosUsers,
  ) {
    int limit = 14;
    if(data.length >= limit) {
      data.removeRange(0, data.length-limit);
      androidUsers.removeRange(0, androidUsers.length-limit);
      iosUsers.removeRange(0, iosUsers.length-limit);
    }
    final androidPercentageInterruptionRangeList = androidUsers.map((f) => f.getPercentageRange('android')).toList();
    final iosPercentageInterruptionRangeList = iosUsers.map((f) => f.getPercentageRange('ios')).toList();

    final lineColors = [Colors.red.shade200, Colors.red.shade400, Colors.red.shade600, Colors.red.shade900,];
    // androidUsers.map((f) {
    //   print('android user: ${f.length} - ${f.getPercentageRange('android')[0]}&');
    //   return '${f.getPercentageRange('android')[0]}%';
    // }).toList();
    return Row(
      children: [
        Expanded(
          child: _buildChart(
            chart: LineChartWidget(
              chartName: 'Mật độ chậm đồng bộ Android',
              maxX: limit.toDouble(),
              maxY: androidPercentageInterruptionRangeList.map((a) => a.reduce(max)).toList().reduce(max),
              topAxisName: 'Số lượng khách',
              topTitles: androidUsers.map((f) => '${f.length}').toList(),
              bottomTitles: data.toDateList(),
              // leftAxisName: '%',
              leftTitles: [],
              lineDataList: [
                androidPercentageInterruptionRangeList
                    .map((a) => a[0])
                    .toList(),
                androidPercentageInterruptionRangeList
                    .map((a) => a[1])
                    .toList(),
                androidPercentageInterruptionRangeList
                    .map((a) => a[2])
                    .toList(),
                androidPercentageInterruptionRangeList
                    .map((a) => a[3])
                    .toList(),
              ],
              lineTitleList: ['<20%', '≥20%', '≥50%', '≥80%'],
              subToolTipData: [
                // androidUsers.map((f) => '${f.getPercentageRange('android')[0]}').toList(),
                // androidUsers.map((f) => '${f.getPercentageRange('android')[1]}%').toList(),
                // androidUsers.map((f) => '${f.getPercentageRange('android')[2]}%').toList(),
                // androidUsers.map((f) => '${f.getPercentageRange('android')[3]}%').toList(),
                // androidPercentageInterruptionRangeList
                //     .map((a) => '${a[0]}')
                //     .toList()
                // iosUser.map((f) => '${f.getUserWithLongestGap().fullName} (${f.getUserWithLongestGap().totalGapTimeInHour}h)').toList()
              ],
              unit: ' khách',
              lineColors: lineColors,
            ),
          ),
        ),
        Expanded(
          child: _buildChart(
            chart: LineChartWidget(
              chartName: 'Mật độ chậm đồng bộ iOS',
              maxX: limit.toDouble(),
              maxY: iosPercentageInterruptionRangeList.map((a) => a.reduce(max)).toList().reduce(max),
              topTitles: iosUsers.map((f) => '${f.length}').toList(),
              topAxisName: 'Số lượng khách',
              bottomTitles: data.toDateList(),
              // leftAxisName: '%',
              leftTitles: [],
              lineDataList: [
                iosPercentageInterruptionRangeList
                    .map((a) => a[0])
                    .toList(),
                iosPercentageInterruptionRangeList
                    .map((a) => a[1])
                    .toList(),
                iosPercentageInterruptionRangeList
                    .map((a) => a[2])
                    .toList(),
                iosPercentageInterruptionRangeList
                    .map((a) => a[3])
                    .toList(),
              ],
              lineTitleList: ['<20%', '≥20%', '≥50%', '≥80%'],
              subToolTipData: [
                // androidUsers.map((f) => '${f.getUserWithLongestGap().fullName} (${f.getUserWithLongestGap().totalGapTimeInHour}h)').toList(),
                // iosUser.map((f) => '${f.getUserWithLongestGap().fullName} (${f.getUserWithLongestGap().totalGapTimeInHour}h)').toList()
              ],
              unit: ' khách',
              lineColors: lineColors,
            ),
          ),
        ),
      ],
    );
  }
  //#endregion

  //#region ACTION
  Future<void> _fetchData() async {
    try {
      print('Loading total cgm data');
      setState(() {
        // ToastService.show(context, 'Đang tải...', type: ToastType.info, duration: null,);
        _isLoading = true;
      });
      await AnalyticService.instance.fetchDB();
      setState(() {
        _isLoading = false;
        // ToastService.show(context, 'Tải xong ${AnalyticService.instance.dataFiles.length} file(s)', type: ToastType.success);
      });
    } catch (error, stackTrace) {
      print('Failed to refresh total cgm data: $error');
      ToastService.show(context, 'Đã có lỗi xảy ra, vui lòng thử lại', type: ToastType.error);
      setState(() {
        _isLoading = false;
      });
    }
  }
  //#endregion
}