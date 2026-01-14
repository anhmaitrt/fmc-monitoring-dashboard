import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/chart/line_chart_widget.dart';
import 'package:fmc_monitoring_dashboard/core/components/copyable_widget.dart';
import 'package:fmc_monitoring_dashboard/core/routing/router.dart';
import 'package:fmc_monitoring_dashboard/core/services/analytic_service.dart';
import 'package:fmc_monitoring_dashboard/core/services/file/file_service.dart';
import 'package:fmc_monitoring_dashboard/core/services/toast_service.dart';
import 'package:fmc_monitoring_dashboard/core/style/app_colors.dart';
import 'package:fmc_monitoring_dashboard/core/style/app_text_styles.dart';
import 'package:fmc_monitoring_dashboard/core/utils/extension/string_extension.dart';
import 'package:fmc_monitoring_dashboard/feature/user_details/user_details_screen.dart';
import 'package:fmc_monitoring_dashboard/model/user_cgm_data_row.dart';
import 'package:fmc_monitoring_dashboard/model/user_model.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  // ✅ Pagination for charts (by DAY / FILE)
  int _perPage = 30; // how many days shown per page
  int _pageIndex = 0; // 0-based
  final List<int> _perPageOptions = const [7, 14, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    // Keep original data stable (do not mutate)
    final all = List<List<UserCGMDataRow>>.from(AnalyticService.instance.dataFiles);

    // In your old code you used reversed(). That means you want oldest->newest for the chart.
    // We'll keep that behavior AFTER paging.
    final asc = all.reversed.toList(); // oldest -> newest

    final page = _paginate(asc);

    // For platform splits, do it based on *paged data*
    final androidUsers = page.splitByPlatform('android');
    final iosUsers = page.splitByPlatform('ios');

    final summariesIssues = [...AnalyticService.instance.userRecoverySummaries]
      ..sort((a, b) => (a.recoveredRate * 100).compareTo(b.recoveredRate * 100));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tổng quan',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _exportCSV,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              transitionBuilder: (child, animation) {
                return RotationTransition(turns: animation, child: child);
              },
              child: Icon(
                (_isLoading ? Icons.autorenew : Icons.share),
                color: AppColors.primary,
                key: ValueKey(_isLoading),
              ),
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _fetchData,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              transitionBuilder: (child, animation) {
                return RotationTransition(turns: animation, child: child);
              },
              child: Icon(
                (_isLoading ? Icons.autorenew : Icons.refresh_rounded),
                color: AppColors.primary,
                key: ValueKey(_isLoading),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundDisable,
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        children: [
          _buildChartPagingBar(totalItems: asc.length),
          const SizedBox(height: 12),

          SizedBox(height: 350, child: _buildTotalCGMChart(page, androidUsers, iosUsers)),
          Container(height: 350, margin: const EdgeInsets.only(top: 16), child: _buildInterruptionChart(page, androidUsers, iosUsers)),
          Container(height: 380, margin: const EdgeInsets.only(top: 16), child: _buildInterruptionByPercentageRange(page, androidUsers, iosUsers)),

          const SizedBox(height: 16),

          RichText(
              text: TextSpan(
                text: 'Thống kê khách gặp sự cố trong khoảng 09:00 - 15:00 13/01/2026',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(
                    text: '\n${summariesIssues.length}/${AnalyticService.instance.userList.length} khách gặp sự cố'
                        '\n${summariesIssues.where((e) => e.recoveredRate * 100 != 0).length} khôi phục lại được',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summariesIssues.length,
            itemBuilder: (_, i) {
              final s = summariesIssues[i];
              final user = AnalyticService.instance.userList.getUserById(s.userId);
              final rate = (s.recoveredRate * 100).toStringAsFixed(0);
              final avg = s.avgRecoveryTime == null ? '-' : '${s.avgRecoveryTime!.inMinutes}m';

              return ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i+1}. ${user?.fullName}', style: TextStyle(fontWeight: FontWeight.bold),),
                    CopyableWidget(text: s.userId.maskUuid(), copyableContent: s.userId),
                  ],
                ),
                subtitle: Text(
                  'Recovered: $rate% | Avg recover: $avg | Errors: ${s.totalErrors}'
                      '\n${user?.platformVersion} | ${user?.deviceModel} | ${user?.appVersion}',
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    s.latestError?.errorCode != null
                        ? Text('code=${s.latestError!.errorCode}') : const SizedBox.shrink(),
                    TextButton(
                      onPressed: () => context.navigateTo(
                        UserDetailsScreen(phoneNumber: user?.phoneNumber ?? ''),
                      ),
                      child: const Text('Chi tiết'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -----------------------
  // PAGINATION CORE
  // -----------------------

  int _totalPages(int totalItems) {
    if (totalItems == 0) return 1;
    return (totalItems / _perPage).ceil();
  }

  List<List<UserCGMDataRow>> _paginate(List<List<UserCGMDataRow>> ascOldestToNewest) {
    if (ascOldestToNewest.isEmpty) return const [];

    final total = ascOldestToNewest.length;
    final pages = _totalPages(total);

    // clamp current page to valid range
    final pageIndex = _pageIndex.clamp(0, pages - 1);
    if (pageIndex != _pageIndex) {
      // keep state consistent if data size changed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pageIndex = pageIndex);
      });
    }

    final start = pageIndex * _perPage;
    if (start >= total) return const [];

    final end = min(start + _perPage, total);
    return ascOldestToNewest.sublist(start, end);
  }

  Widget _buildChartPagingBar({required int totalItems}) {
    final pages = _totalPages(totalItems);

    final start = totalItems == 0 ? 0 : (_pageIndex * _perPage) + 1;
    final end = totalItems == 0
        ? 0
        : min((_pageIndex * _perPage) + _perPage, totalItems);

    return Card.filled(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text('Trang ${_pageIndex + 1} / $pages · Hiển thị $start–$end / $totalItems ngày'),
            const Spacer(),
            const Text('Days/page: '),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _perPage,
              items: _perPageOptions
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _perPage = v;
                  _pageIndex = 0; // reset to first page
                });
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'First',
              onPressed: (_pageIndex <= 0) ? null : () => setState(() => _pageIndex = 0),
              icon: const Icon(Icons.first_page),
            ),
            IconButton(
              tooltip: 'Prev',
              onPressed: (_pageIndex <= 0) ? null : () => setState(() => _pageIndex--),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: 'Next',
              onPressed: (_pageIndex >= pages - 1) ? null : () => setState(() => _pageIndex++),
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: 'Last',
              onPressed: (_pageIndex >= pages - 1) ? null : () => setState(() => _pageIndex = pages - 1),
              icon: const Icon(Icons.last_page),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------
  // CHART CONTAINERS
  // -----------------------

  Widget _buildChart({required Widget chart}) {
    return Card.filled(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: chart,
      ),
    );
  }

  Widget _buildTotalCGMChart(
      List<List<UserCGMDataRow>> data,
      List<List<UserCGMDataRow>> androidUsers,
      List<List<UserCGMDataRow>> iosUser,
      ) {
    if (data.isEmpty) {
      return _buildChart(
        chart: const Center(child: Text('Không có dữ liệu')),
      );
    }

    final topTitles = <String>[];
    for (int i = 0; i < data.length; i++) {
      topTitles.add((androidUsers.count()[i] + iosUser.count()[i]).toString());
    }

    return _buildChart(
      chart: LineChartWidget(
        chartName: 'Số lượng khách dùng CGM',
        maxX: data.maxX,
        maxY: data.maxY,
        topTitles: topTitles,
        topAxisName: 'Tổng khách',
        bottomTitles: data.toDateList(),
        leftTitles: const [],
        leftAxisName: 'Số lượng theo platform',
        lineDataList: [androidUsers.count(), iosUser.count()],
        lineTitleList: const ['android', 'ios'],
        subToolTipData: const [],
        lineColors: [Colors.lightBlue, Colors.pinkAccent],
      ),
    );
  }

  Widget _buildInterruptionChart(
      List<List<UserCGMDataRow>> data,
      List<List<UserCGMDataRow>> androidUsers,
      List<List<UserCGMDataRow>> iosUser,
      ) {
    if (data.isEmpty) {
      return _buildChart(
        chart: const Center(child: Text('Không có dữ liệu')),
      );
    }

    final androidPercentageInterruptionList =
    androidUsers.map((f) => f.percentageInterruption).toList();
    final iosPercentageInterruptionList =
    iosUser.map((f) => f.percentageInterruption).toList();

    final maxY = [...androidPercentageInterruptionList, ...iosPercentageInterruptionList].isEmpty
        ? 0.0
        : [...androidPercentageInterruptionList, ...iosPercentageInterruptionList].reduce(max);

    return _buildChart(
      chart: LineChartWidget(
        chartName: 'Tỉ lệ chậm đồng bộ theo ngày',
        maxX: data.maxX,
        maxY: maxY,
        topTitles: const [],
        bottomTitles: data.toDateList(),
        leftTitles: const [],
        leftAxisName: '%',
        lineDataList: [androidPercentageInterruptionList, iosPercentageInterruptionList],
        lineTitleList: const ['android', 'ios'],
        subToolTipData: [
          androidUsers
              .map((f) => '${f.getUserWithLongestGap().fullName} '
              '(${f.getUserWithLongestGap().totalGapTimeInHour.toStringAsFixed(1)}h)')
              .toList(),
          iosUser
              .map((f) => '${f.getUserWithLongestGap().fullName} '
              '(${f.getUserWithLongestGap().totalGapTimeInHour.toStringAsFixed(1)}h)')
              .toList(),
        ],
        unit: '%',
        lineColors: [Colors.lightBlue, Colors.pinkAccent],
      ),
    );
  }

  Widget _buildInterruptionByPercentageRange(
      List<List<UserCGMDataRow>> data,
      List<List<UserCGMDataRow>> androidUsers,
      List<List<UserCGMDataRow>> iosUsers,
      ) {
    if (data.isEmpty) {
      return _buildChart(
        chart: const Center(child: Text('Không có dữ liệu')),
      );
    }

    // NOTE: This chart previously forced limit=14. With paging, you can just rely on _perPage.
    // If you still want to force at most 14 points for readability, keep this:
    const hardCap = 14;
    final cappedData = data.length > hardCap ? data.sublist(data.length - hardCap) : data;
    final cappedAndroid = androidUsers.length > hardCap ? androidUsers.sublist(androidUsers.length - hardCap) : androidUsers;
    final cappedIos = iosUsers.length > hardCap ? iosUsers.sublist(iosUsers.length - hardCap) : iosUsers;

    final androidRanges = cappedAndroid.map((f) => f.getPercentageRange('android')).toList();
    final iosRanges = cappedIos.map((f) => f.getPercentageRange('ios')).toList();

    double maxAndroid = 0;
    if (androidRanges.isNotEmpty) {
      maxAndroid = androidRanges.map((a) => a.reduce(max)).reduce(max).toDouble();
    }

    double maxIos = 0;
    if (iosRanges.isNotEmpty) {
      maxIos = iosRanges.map((a) => a.reduce(max)).reduce(max).toDouble();
    }

    final lineColors = [
      Colors.grey.shade200,
      Colors.grey.shade400,
      Colors.red.shade200,
      Colors.red.shade400,
      Colors.red.shade900,
    ];

    return Row(
      children: [
        Expanded(
          child: _buildChart(
            chart: LineChartWidget(
              chartName: 'Mật độ chậm đồng bộ Android',
              maxX: cappedData.length.toDouble(),
              maxY: maxAndroid,
              topAxisName: 'Số lượng khách',
              topTitles: cappedAndroid.map((f) => '${f.length}').toList(),
              bottomTitles: cappedData.toDateList(),
              leftTitles: const [],
              lineDataList: [
                androidRanges.map((a) => a[0].toDouble()).toList(),
                androidRanges.map((a) => a[1].toDouble()).toList(),
                androidRanges.map((a) => a[2].toDouble()).toList(),
                androidRanges.map((a) => a[3].toDouble()).toList(),
                androidRanges.map((a) => a[4].toDouble()).toList(),
              ],
              lineTitleList: const ['<20%', '≥20%', '≥50%', '≥80%', 'Ngưng đồng bộ'],
              subToolTipData: const [],
              unit: ' khách',
              lineColors: lineColors,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildChart(
            chart: LineChartWidget(
              chartName: 'Mật độ chậm đồng bộ iOS',
              maxX: cappedData.length.toDouble(),
              maxY: maxIos,
              topTitles: cappedIos.map((f) => '${f.length}').toList(),
              topAxisName: 'Số lượng khách',
              bottomTitles: cappedData.toDateList(),
              leftTitles: const [],
              lineDataList: [
                iosRanges.map((a) => a[0].toDouble()).toList(),
                iosRanges.map((a) => a[1].toDouble()).toList(),
                iosRanges.map((a) => a[2].toDouble()).toList(),
                iosRanges.map((a) => a[3].toDouble()).toList(),
                iosRanges.map((a) => a[4].toDouble()).toList(),
              ],
              lineTitleList: const ['<20%', '≥20%', '≥50%', '≥80%', 'Ngưng đồng bộ'],
              subToolTipData: const [],
              unit: ' khách',
              lineColors: lineColors,
            ),
          ),
        ),
      ],
    );
  }

  //#region ACTION
  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      await AnalyticService.instance.fetchDB();
      setState(() {
        _isLoading = false;
        _pageIndex = 0; // reset chart paging after refresh
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh total cgm data: $error\n$stackTrace');
      ToastService.show(
        context: context,
        'Đã có lỗi xảy ra, vui lòng thử lại',
        type: ToastType.error,
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportCSV() async {
    try {
      setState(() => _isLoading = true);
      await FileService.instance.exportCsv(
        AnalyticService.instance.dataFiles.toCSVData(lastNDays: _perPage)
      );
      setState(() {
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh total cgm data: $error\n$stackTrace');
      ToastService.show(
        context: context,
        'Đã có lỗi xảy ra, vui lòng thử lại',
        type: ToastType.error,
      );
      setState(() => _isLoading = false);
    }
  }
  //#endregion
}