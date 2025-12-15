import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../utils/app_size.dart';

class OverviewTable extends StatelessWidget {
  const OverviewTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Table View
          Table(
            border: TableBorder.all(color: Colors.black),
            columnWidths: {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(2),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[300]),
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text("Date")),
                  Padding(padding: EdgeInsets.all(8), child: Text("Platform")),
                  Padding(padding: EdgeInsets.all(8), child: Text("Total Clients")),
                  Padding(padding: EdgeInsets.all(8), child: Text("Sync Failures")),
                  Padding(padding: EdgeInsets.all(8), child: Text("Longest Sync Time")),
                ],
              ),
              // Data rows
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text("25/11")),
                  Padding(padding: EdgeInsets.all(8), child: Text("Android")),
                  Padding(padding: EdgeInsets.all(8), child: Text("39")),
                  Padding(padding: EdgeInsets.all(8), child: Text("37")),
                  Padding(padding: EdgeInsets.all(8), child: Text("17 minutes")),
                ],
              ),
              TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text("25/11")),
                  Padding(padding: EdgeInsets.all(8), child: Text("iOS")),
                  Padding(padding: EdgeInsets.all(8), child: Text("77")),
                  Padding(padding: EdgeInsets.all(8), child: Text("75")),
                  Padding(padding: EdgeInsets.all(8), child: Text("28 minutes")),
                ],
              ),
              // Add more rows as needed...
            ],
          ),
          SizedBox(height: 20),
          // Chart View
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  //#region UI
  Widget _buildChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: 100,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 37, color: Colors.blue)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 75, color: Colors.red)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 36, color: Colors.blue)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 81, color: Colors.red)]),
          // Add more data points as needed
        ],
      ),
    );
  }
  //#endregion
}
