import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../style/app_colors.dart';
import '../../utils/extension/list_extension.dart';
import '../../utils/extension/string_extension.dart';

class LineChartWidget extends StatefulWidget {
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
  final List<List<String>>? tooltipData;     // tooltipData[lineIndex][x]
  final List<List<String>>? subToolTipData;  // subToolTipData[lineIndex][x]
  final String? topAxisName;
  final double? maxX;
  final String? leftAxisName;
  final List<String> leftTitles;
  final String? bottomAxisName;
  final double maxY;
  final List<Color> lineColors;

  @override
  State<LineChartWidget> createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  /// Multi-select: keep which lines are visible
  final Set<int> _selected = <int>{};

  /// Mapping: visible barIndex -> original lineIndex
  List<int> get _visibleLineIndexes => _selected.toList()..sort();

  @override
  void initState() {
    super.initState();
    // default: show all
    for (int i = 0; i < widget.lineTitleList.length; i++) {
      _selected.add(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleLineIndexes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 16),
          child: Text(
            widget.chartName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),

        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: widget.leftAxisName.isNullOrEmpty ? 0 : 8),
            child: Stack(
              children: [
                LineChart(
                  LineChartData(
                    lineTouchData: _lineTouchData,
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: buildAxis(
                        titles: const SideTitles(showTitles: false),
                      ),
                      topTitles: buildAxis(
                        axisName: widget.topAxisName,
                        titles: buildTopTitles(),
                      ),
                      leftTitles: buildAxis(
                        titles: buildLeftTitles(),
                        axisName: widget.leftAxisName,
                      ),
                      bottomTitles: buildAxis(
                        titles: buildBottomTitles(),
                        axisName: widget.bottomAxisName,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 4,
                        ),
                        left: const BorderSide(color: Colors.transparent),
                        right: const BorderSide(color: Colors.transparent),
                        top: const BorderSide(color: Colors.transparent),
                      ),
                    ),
                    lineBarsData: barsData,
                    minX: 0,
                    maxX: widget.maxX,
                    maxY: _maxYForVisibleOrWidget(),
                    minY: 0,
                  ),
                ),

                if (visible.isEmpty)
                  const Center(
                    child: Text(
                      'Chọn ít nhất 1 đường để hiển thị',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (widget.lineTitleList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 16.0, right: 12, bottom: 8),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: widget.lineTitleList.mapIndexed((i, title) {
                final checked = _selected.contains(i);
                return InkWell(
                  onTap: () => _toggleLine(i, !checked),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: checked,
                        onChanged: (v) => _toggleLine(i, v ?? false),
                      ),
                      Text(
                        title,
                        style: TextStyle(
                          color: widget.lineColors[i],
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _toggleLine(int index, bool show) {
    setState(() {
      if (show) {
        _selected.add(index);
      } else {
        _selected.remove(index);
      }
    });
  }

  double _maxYForVisibleOrWidget() {
    final visible = _visibleLineIndexes;
    if (visible.isEmpty) return widget.maxY;

    double maxVal = 0;
    for (final lineIndex in visible) {
      final series = widget.lineDataList[lineIndex];
      for (final v in series) {
        if (v.isFinite && v > maxVal) maxVal = v;
      }
    }
    // keep at least a tiny >0 range
    return maxVal > 0 ? maxVal : widget.maxY;
  }

  //#region UI
  AxisTitles buildAxis({
    required SideTitles titles,
    String? axisName,
  }) {
    return AxisTitles(
      axisNameWidget: axisName != null
          ? Text(
        axisName,
        style: const TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
        ),
      )
          : Container(),
      sideTitles: titles,
    );
  }

  LineTouchData get _lineTouchData => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (touchedSpot) => Colors.blueGrey.withValues(alpha: 0.4),
      getTooltipItems: _buildToolTip,
    ),
  );

  List<LineTooltipItem?> _buildToolTip(List<LineBarSpot> touchedBarSpots) {
    final visible = _visibleLineIndexes;

    // If nothing special, still map color correctly
    return touchedBarSpots.map((barSpot) {
      final xIndex = barSpot.x.toInt();

      // barSpot.barIndex = index in *visible* list
      final visibleBarIndex = barSpot.barIndex;
      if (visibleBarIndex < 0 || visibleBarIndex >= visible.length) {
        return null;
      }

      final originalLineIndex = visible[visibleBarIndex];

      final color = widget.lineColors[originalLineIndex];

      final tooltipText = _safeTooltipText(
        lineIndex: originalLineIndex,
        xIndex: xIndex,
        yValue: barSpot.y,
      );

      final sub = _safeSubTooltipText(
        lineIndex: originalLineIndex,
        xIndex: xIndex,
      );

      return LineTooltipItem(
        tooltipText,
        TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        children: (sub == null)
            ? null
            : [
          TextSpan(
            text: '\n$sub',
            style: TextStyle(color: color, fontSize: 10),
          ),
        ],
      );
    }).toList();
  }

  String _safeTooltipText({
    required int lineIndex,
    required int xIndex,
    required double yValue,
  }) {
    // If tooltipData exists, use tooltipData[lineIndex][xIndex]
    final td = widget.tooltipData;
    if (td != null &&
        lineIndex >= 0 &&
        lineIndex < td.length &&
        xIndex >= 0 &&
        xIndex < td[lineIndex].length) {
      return td[lineIndex][xIndex];
    }

    // fallback
    return '${yValue}${widget.unit}';
  }

  String? _safeSubTooltipText({
    required int lineIndex,
    required int xIndex,
  }) {
    final sd = widget.subToolTipData;
    if (sd == null) return null;
    if (lineIndex < 0 || lineIndex >= sd.length) return null;
    if (xIndex < 0 || xIndex >= sd[lineIndex].length) return null;
    return sd[lineIndex][xIndex];
  }

  SideTitles buildTopTitles() => widget.topTitles.isEmpty
      ? const SideTitles()
      : SideTitles(
    showTitles: true,
    reservedSize: 22,
    interval: 1,
    getTitlesWidget: buildTopTitleWidgets,
  );

  Widget buildTopTitleWidgets(double value, TitleMeta meta) {
    final i = value.toInt();
    if (i < 0 || i >= widget.topTitles.length) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        widget.topTitles[i],
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
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
    if (i < 0 || i >= widget.bottomTitles.length) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        widget.bottomTitles[i],
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  SideTitles buildLeftTitles() {
    return SideTitles(
      getTitlesWidget: buildHorizontalWidgets,
      showTitles: true,
      interval: (widget.maxY / 8).ceilToDouble() < 7
          ? (widget.maxY / 8).ceilToDouble()
          : 10,
      reservedSize: 35,
    );
  }

  Widget buildHorizontalWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    return SideTitleWidget(
      meta: meta,
      child: Text(value.toString(), style: style, textAlign: TextAlign.center),
    );
  }

  List<LineChartBarData> get barsData {
    final visible = _visibleLineIndexes;
    if (visible.isEmpty) return [];

    final lineBarDataList = <LineChartBarData>[];

    for (final originalLineIndex in visible) {
      final series = widget.lineDataList[originalLineIndex];

      final spots = <FlSpot>[];
      for (int j = 0; j < series.length; j++) {
        spots.add(FlSpot(j.toDouble(), series[j]));
      }

      lineBarDataList.add(
        _buildChartBar(
          spotList: spots,
          color: widget.lineColors[originalLineIndex],
        ),
      );
    }

    return lineBarDataList;
  }

  LineChartBarData _buildChartBar({
    required List<FlSpot> spotList,
    required Color color,
  }) =>
      LineChartBarData(
        isCurved: true,
        color: color,
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        spots: spotList,
      );
//#endregion
}
