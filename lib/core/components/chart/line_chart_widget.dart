import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/utils/extension/string_extension.dart';

import '../../style/app_colors.dart';
import '../../utils/extension/list_extension.dart';

class LineChartWidget extends StatelessWidget {
  const LineChartWidget({
    super.key,
    this.chartName = '',
    required this.topTitles,
    required this.bottomTitles,
    required this.maxX,
    required this.leftTitles,
    required this.maxY,
    required this.lineDataList,
    required this.lineTitleList,
    this.tooltipData,
    this.subToolTipData,
    this.topAxisName,
    this.leftAxisName,
    this.bottomAxisName,
    this.unit = '',
    this.lineColors = Colors.primaries,
  });

  final String chartName;
  final String unit;
  final List<List<double>> lineDataList;
  final List<String> lineTitleList;
  final List<String> topTitles;
  final List<String> bottomTitles;
  final List<List<String>>? tooltipData;
  final List<List<String>>? subToolTipData;
  final String? topAxisName;
  final double? maxX;
  final String? leftAxisName;
  final List<String> leftTitles;
  final String? bottomAxisName;
  final double maxY;
  final List<Color> lineColors;

  @override
  Widget build(BuildContext context) {
    final lineTitleWidget = <TextSpan>[];
    if(lineTitleList.length > 1) {
      for (int i = 1; i < lineTitleList.length; i++) {
        lineTitleWidget.add(TextSpan(
            text: ' - ',
            style: TextStyle(color: Colors.black),
            children: [
              TextSpan(
                text: lineTitleList[i],
                style: TextStyle(color: lineColors[i]),
              ),
            ]
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 16.0),
          child: Text(chartName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: leftAxisName.isNullOrEmpty ? 0 : 8),
            child: LineChart(
                LineChartData(
                  lineTouchData: lineTouchData1,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: buildAxis(
                      titles: SideTitles(showTitles: false),
                    ),
                    topTitles:buildAxis(
                      axisName: topAxisName,
                      titles: buildTopTitles(),
                    ),
                    leftTitles: buildAxis(
                      titles: buildLeftTitles(),
                      axisName: leftAxisName,
                    ),
                    bottomTitles: buildAxis(
                      titles: buildBottomTitles(),
                      axisName: bottomAxisName,
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
        ),
        if(lineTitleList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 16.0),
            child: RichText(
              textAlign: TextAlign.start,
                text: TextSpan(
                  text: lineTitleList[0],
                  style: TextStyle(color: lineColors[0]),
                  children: lineTitleWidget
                ),
            ),
          )
      ],
    );
  }

  //#region UI
  AxisTitles buildAxis({
    required SideTitles titles,
    String? axisName,
  }) {
    return AxisTitles(
      axisNameWidget: axisName != null ? Text(axisName, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900)) : Container(),
      // axisNameSize: 14,
      sideTitles: titles,
    );
  }

  LineTouchData get lineTouchData1 =>
      LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              Colors.blueGrey.withValues(alpha: 0.4),
          getTooltipItems: (touchedBarSpots) => _buildToolTip(touchedBarSpots),
        ),
        touchCallback: (event, lineTouch) {
          if(event is FlTapUpEvent) {
            // lineTouch.lineBarSpots?.
            print('Touch: ${event.isInterestedForInteractions} ${event}, $lineTouch');
          }
          // if (!event.isInterestedForInteractions ||
          //     lineTouch == null ||
          //     lineTouch.lineBarSpots == null) {
          //   setState(() {
          //     touchedValue = -1;
          //   });
          //   return;
          // }
          // final value = lineTouch.lineBarSpots![0].x;
          //
          // if (value == 0 || value == 6) {
          //   setState(() {
          //     touchedValue = -1;
          //   });
          //   return;
          // }
          //
          // setState(() {
          //   touchedValue = value;
          // });
        },
      );

  List<LineTooltipItem?> _buildToolTip(List<LineBarSpot> touchedBarSpots) {
    if(tooltipData.isNullOrEmpty() && subToolTipData.isNullOrEmpty() && unit.isEmpty) {
      return defaultLineTooltipItem(touchedBarSpots);
    }

    return touchedBarSpots.map((barSpot) {
      final flSpot = barSpot;
      // print('Spot tooltip: ${flSpot.x}, ${flSpot.barIndex}');
      // if (flSpot.x == 0 || flSpot.x == 6) {
      //   return null;
      // }
      return LineTooltipItem(
        tooltipData.isNullOrEmpty() ? '${flSpot.y}$unit${subToolTipData.isNullOrEmpty() ? '' : '\n'}' : '${tooltipData![flSpot.barIndex]}',
        textAlign: TextAlign.center,
        TextStyle(
          color: lineColors[flSpot.barIndex],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        children: subToolTipData.isNullOrEmpty() ? null : [
          TextSpan(
            text: subToolTipData![flSpot.barIndex][flSpot.x.toInt()],
            style: TextStyle(
                color: lineColors[flSpot.barIndex],
                fontSize: 10
              // fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }).toList();
  }

  SideTitles buildTopTitles() => topTitles.isEmpty ? SideTitles(showTitles: false) : SideTitles(
    showTitles: true,
    reservedSize: 22,
    interval: 1,
    getTitlesWidget: buildTopTitleWidgets,
  );

  Widget buildTopTitleWidgets(double value, TitleMeta meta) {
    final i = value.toInt();

    if (i < 0 || i >= topTitles.length) return const SizedBox.shrink();

    // final showEvery = (xTitle.length <= 7) ? 1 : (xTitle.length <= 14) ? 2 : 3;
    // if (i % showEvery != 0 && i != xTitle.length - 1) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(topTitles[i],
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  SideTitles buildBottomTitles() => SideTitles(
    showTitles: true,
    reservedSize: 22,
    interval: 1,
    getTitlesWidget: bottomTitleWidgets,
  );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final i = value.toInt();

    if (i < 0 || i >= bottomTitles.length) return const SizedBox.shrink();

    // final showEvery = (xTitle.length <= 7) ? 1 : (xTitle.length <= 14) ? 2 : 3;
    // if (i % showEvery != 0 && i != xTitle.length - 1) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(bottomTitles[i],
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  SideTitles buildLeftTitles() {
    return SideTitles(
    getTitlesWidget: buildHorizontalWidgets,
    showTitles: true,
    interval: (maxY/8).ceilToDouble() < 7 ? (maxY/8).ceilToDouble() : 10,
    reservedSize: 35,
  );
  }

  Widget buildHorizontalWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
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

  List<LineChartBarData> get barsData {
    List<LineChartBarData> lineBarDataList = <LineChartBarData>[];
    for(int i = 0; i < lineDataList.length; i++) {
      final spotData = <FlSpot>[];
      for(int j = 0; j < lineDataList[i].length; j++) {
        spotData.add(FlSpot(j.toDouble(), lineDataList[i][j]));
      }
      lineBarDataList.add(_buildChartBar(spotList: spotData, color: lineColors![i]));
    }
    return lineBarDataList;
  }

  LineChartBarData _buildChartBar({
    required List<FlSpot> spotList,
    required Color color,
  }) => LineChartBarData(
    isCurved: true,
    color: color,
    barWidth: 4,
    isStrokeCapRound: true,
    dotData: FlDotData(show: true,/* getDotPainter: (spot, percent, barData, index) {
      if (index.isEven) {
        return FlDotCirclePainter(
          radius: 8,
          color: Colors.white,
          strokeWidth: 5,
          strokeColor: lineColors[0],
        );
      } else {
        return FlDotSquarePainter(
          size: 16,
          color: Colors.white,
          strokeWidth: 5,
          strokeColor: lineColors[1],
        );
      }
    },*/),
    belowBarData: BarAreaData(show: false),
    spots: spotList
  );
  //#endregion
}
