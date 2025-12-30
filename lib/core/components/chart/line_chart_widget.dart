import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../style/app_colors.dart';

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
    required this.toolTipData,
    this.unit = '',
    this.lineColors = Colors.primaries,
  });

  final String chartName;
  final String unit;
  final List<List<double>> lineDataList;
  final List<String> lineTitleList;
  final List<String> topTitles;
  final List<String> bottomTitles;
  final List<List<String>> toolTipData;
  final double? maxX;
  final List<String> leftTitles;
  final double maxY;
  final List<Color> lineColors;

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
                    sideTitles: buildBottomTitles(),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: buildTopTitles(),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: buildLeftTitles(),
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
                text: lineTitleList[0],
                style: TextStyle(color: lineColors![0]),
                children: lineTitleList.skip(1).map((l) {
                  return TextSpan(
                      text: ' - ',
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: l,
                          style: TextStyle(color: lineColors![1]),
                        ),
                      ]
                  );
                }).toList()
              ),
          ),
        )
      ],
    );
  }

  //#region UI
  LineTouchData get lineTouchData1 =>
      LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              Colors.blueGrey.withValues(alpha: 0.4),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return toolTipData.isEmpty ? defaultLineTooltipItem(touchedBarSpots) : touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              // print('Spot tooltip: ${flSpot.x}, ${flSpot.barIndex}');
              // if (flSpot.x == 0 || flSpot.x == 6) {
              //   return null;
              // }

              return LineTooltipItem(
                '${flSpot.y}$unit\n',
                TextStyle(
                  color: lineColors![flSpot.barIndex],
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: toolTipData[flSpot.barIndex][flSpot.x.toInt()],
                    style: TextStyle(
                      color: lineColors![flSpot.barIndex],
                      fontSize: 9
                      // fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                textAlign: TextAlign.center,
              );
            }).toList();
          },
        ),
        // touchCallback: (event, lineTouch) {
        //   print('Touch: ${event.}, $lineTouch');
        //   // if (!event.isInterestedForInteractions ||
        //   //     lineTouch == null ||
        //   //     lineTouch.lineBarSpots == null) {
        //   //   setState(() {
        //   //     touchedValue = -1;
        //   //   });
        //   //   return;
        //   // }
        //   // final value = lineTouch.lineBarSpots![0].x;
        //   //
        //   // if (value == 0 || value == 6) {
        //   //   setState(() {
        //   //     touchedValue = -1;
        //   //   });
        //   //   return;
        //   // }
        //   //
        //   // setState(() {
        //   //   touchedValue = value;
        //   // });
        // },
      );

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

  SideTitles buildLeftTitles() => SideTitles(
    getTitlesWidget: buildHorizontalWidgets,
    showTitles: true,
    interval: (maxY/8).ceilToDouble()/* 20*/,
    reservedSize: 45,
  );

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
