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
    return SizedBox(
      height: double.infinity,
      child: RefreshIndicator(
        onRefresh: () => fetchData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                height: 350,
                child: _buildTotalCGM()
              )
            ],
          ),
        ),
      ),
    );
  }

  //#region UI
  Widget _buildTotalCGM() {
    return LineChartWidget(
      chartName: 'Khách dùng CGM',
      maxX: AnalyticService.instance.dataFiles.maxX,
      maxY: AnalyticService.instance.dataFiles.maxY,
      xTitle: AnalyticService.instance.dataFiles.toDateList(),
      yTitle: [],
      lineData1: AnalyticService.instance.dataFiles.splitByPlatform('android'),
      lineData2: AnalyticService.instance.dataFiles.splitByPlatform('ios'),
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