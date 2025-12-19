import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../style/app_colors.dart';

class LineChartWidget extends StatelessWidget {
  const LineChartWidget({
    super.key,
    this.chartName = '',
    required this.xTitle,
    required this.maxX,
    required this.yTitle,
    required this.maxY,
    required this.lineData1,
    required this.lineData2,
  });

  final String chartName;
  final List<double> lineData1;
  final List<double> lineData2;
  final List<String> xTitle;
  final double? maxX;
  final List<String> yTitle;
  final double maxY;
  final Color lineData1Color = Colors.purpleAccent;
  final Color lineData2Color = Colors.greenAccent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 16.0),
          child: Text(chartName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),),
        ),
        Expanded(
          child: LineChart(
              LineChartData(
                lineTouchData: lineTouchData1,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: bottomTitles,
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: leftTitles(),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2), width: 4),
                    left: const BorderSide(color: Colors.transparent),
                    right: const BorderSide(color: Colors.transparent),
                    top: const BorderSide(color: Colors.transparent),
                  ),
                ),
                lineBarsData: barsData,
                minX: 0,
                maxX: maxX,
                maxY: maxY,
                minY: 0,
              )
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18, top: 16.0),
          child: RichText(
            textAlign: TextAlign.start,
              text: TextSpan(
                text: 'android',
                style: TextStyle(color: lineData1Color),
                children: [
                  TextSpan(
                    text: ' - ',
                    style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: 'ios',
                    style: TextStyle(color: lineData2Color),
                  ),
                ],
              ),
          ),
        )
      ],
    );
  }

  //#region UI
  LineTouchData get lineTouchData1 => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (touchedSpot) =>
          Colors.blueGrey.withValues(alpha: 0.8),
    ),
  );

  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 22,
    interval: 1,
    getTitlesWidget: bottomTitleWidgets,
  );

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );

    String text = value.toString();

    return SideTitleWidget(
      meta: meta,
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  SideTitles leftTitles() => SideTitles(
    getTitlesWidget: leftTitleWidgets,
    showTitles: true,
    interval: 20,
    reservedSize: 35,
  );

  List<LineChartBarData> get barsData {
    final androidData = <FlSpot>[];
    for(int i = 0; i < lineData1.length; i++) {
      androidData.add(FlSpot(i+1, lineData1[i]));
    };

    final iosData = <FlSpot>[];
    for(int i = 0; i < lineData1.length; i++) {
      iosData.add(FlSpot(i+1, lineData2[i]));
    };

    return [
      _buildChartBar(spotList: androidData, color: lineData1Color),
      _buildChartBar(spotList: iosData, color: lineData2Color),
    ];
  }

  LineChartBarData _buildChartBar({
    required List<FlSpot> spotList,
    required Color color,
  }) => LineChartBarData(
    isCurved: true,
    color: color,
    barWidth: 4,
    isStrokeCapRound: true,
    dotData: FlDotData(show: true),
    belowBarData: BarAreaData(show: false),
    spots: spotList
  );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final i = value.toInt();
    // final sorted = [..._daily]..sort((a, b) => a.date.compareTo(b.date));
    // final sorted = ;

    if (i < 0 || i >= xTitle.length) return const SizedBox.shrink();

    final showEvery = (xTitle.length <= 7) ? 1 : (xTitle.length <= 14) ? 2 : 3;
    if (i % showEvery != 0 && i != xTitle.length - 1) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(xTitle[i],
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

//#endregion
}
