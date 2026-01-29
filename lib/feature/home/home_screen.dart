import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../core/components/chart/line_chart_widget.dart';
import '../../core/components/copyable_widget.dart';
import '../../core/components/export_options_dialog.dart';
import '../../core/components/scaffold_widget.dart';
import '../../core/routing/router.dart';
import '../../core/services/analytic_service.dart';
import '../../core/services/file/file_service.dart';
import '../../core/services/toast_service.dart';
import '../../core/style/app_colors.dart';
import '../../core/utils/extension/date_extension.dart';
import '../../core/utils/extension/string_extension.dart';
import '../../model/interruption_range.dart';
import '../../model/user_cgm_data_row.dart';
import '../../model/user_model.dart';
import '../user_details/user_details_screen.dart';
import '../user_details/user_info_card.dart';


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

    return ScaffoldWidget(
      title: 'Tổng quan',
      actions: [
        IconButton(
          onPressed: _isLoading ? null : _exportCSVCustom /*_exportCSV*/,
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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        children: [
          _buildAnalyticsSection(asc),
          _buildChartPagingBar(totalItems: asc.length),
          Container(
            height: 350,
            margin: const EdgeInsets.only(top: 12),
            child: _buildTotalCGMChart(page, androidUsers, iosUsers,),
          ),
          Container(
            height: 350,
            margin: const EdgeInsets.only(top: 16),
            child: _buildInterruptionChart(page, androidUsers, iosUsers,),
          ),
          Container(
            height: 380,
            margin: const EdgeInsets.only(top: 16),
            child: _buildInterruptionByPercentageRange(page, androidUsers, iosUsers,),
          ),

          // const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({
    required Widget body,
    String? title,
    String? subTitle,
  }) {
    return Card.filled(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              RichText(
                text: TextSpan(
                  text: title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  children: [
                    TextSpan(
                      text: subTitle,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(List<List<UserCGMDataRow>> asc) {
    final summariesIssues = [...AnalyticService.instance.userRecoverySummaries]
      ..sort((a, b) => (a.recoveredRate * 100).compareTo(b.recoveredRate * 100));

    return Container(
        height: 350,
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildVIPTable(asc)),
            Expanded(
              child: _buildSection(
                title: 'Khách gặp sự cố trong khoảng 01:00 - 09:00 27/01/2026',
                subTitle: '\n${summariesIssues.length}/${AnalyticService
                    .instance.userList
                    .getAndroidUsers()
                    .length} khách gặp sự cố'
                    '\n${summariesIssues
                    .where((e) => e.recoveredRate * 100 != 0)
                    .length} khôi phục lại được',
                body: Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    // physics: const NeverScrollableScrollPhysics(),
                    itemCount: summariesIssues.length,
                    itemBuilder: (_, i) {
                      final s = summariesIssues[i];
                      final user = AnalyticService.instance.userList
                          .getUserById(s.userId);
                      final rate = (s.recoveredRate * 100).toStringAsFixed(0);
                      final avg = s.avgRecoveryTime == null ? '-' : '${s
                          .avgRecoveryTime!.inMinutes}m';

                      return UserInfoCard(
                          user: user,
                          customizeFullName: '${i + 1}. ${user?.fullName}',
                        note: 'Tỉ lệ khôi phục: $rate% | T/g khôi phục trung bình: $avg | Số lần: ${s.totalErrors}',
                        actionTitle: 'Chi tiết',
                        onActionPressed: () => () =>
                            context.navigateTo(
                              UserDetailsScreen(
                                  phoneNumber: user?.phoneNumber ?? ''),
                            ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildVIPTable(List<List<UserCGMDataRow>> asc) {
    final files = <String, UserCGMDataRow>{};

    for (final day in asc.reversed) {
      for (final row in day.reversed) {
        final phone = row.phoneNumber;

        if (phone.isNullOrEmpty) continue;

        if (AnalyticService.instance.userList.firstWhereOrNull((e) => phone!.contains(e.phoneNumber ?? '') && e.isVIP) == null) continue;

        files.putIfAbsent(phone!, () => row);
      }
    }

    final vipLatestRows = files.values.toList()
      ..sort((a, b) {
        final da = a.dateTime;
        final db = b.dateTime;
        if (da == null || db == null) return 0;
        return db.compareTo(da); // newest first
      });

    final sorted = [...vipLatestRows]
      ..sort((a, b) => a.interruptionPercentage < b.interruptionPercentage ? 1 : -1);
    return _buildSection(
      title: 'Khách VIP',
      subTitle: '\n${sorted.length} khách',
      body: ListView.builder(
        shrinkWrap: true,
        // physics: const NeverScrollableScrollPhysics(),
        itemCount: sorted.length,
        itemBuilder: (_, i) {
          // final s = summariesIssues[i];
          final user = AnalyticService.instance.userList
              .getUserById(sorted[i].userId ?? '');
          // final rate = (s.recoveredRate * 100).toStringAsFixed(0);
          // final avg = s.avgRecoveryTime == null ? '-' : '${s
          //     .avgRecoveryTime!.inMinutes}m';

          return UserInfoCard(
            user: user,
            enableVIPTag: false,
            customizeFullName: '${i + 1}. ${user?.fullName}',
            note: 'Ngày ${sorted[i].dateTime.onlyDDMMYYYY()} chậm đồng bộ ${sorted[i].totalGapTimeInHour.toStringAsFixed(1)} giờ',
            actionTitle: 'Chi tiết',
            onActionPressed: () => context.navigateTo(
              UserDetailsScreen(
                  phoneNumber: user?.phoneNumber ?? ''),
            ),
          );
        },
      ),
    );
  }

  //#region PAGINATION CORE
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
  //#endregion

  //#region CHART CONTAINERS
  Widget _buildChart({required Widget chart}) {
    return _buildSection(
      body: Padding(
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
        lineColors: const [Colors.lightBlue, Colors.pinkAccent],
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

  //TODO: optimize calculation
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

    final androidUserInterruptionByRange = cappedAndroid.map((f) => f.filterUserByInterruptionRangeByPlatform('android')).toList();
    final iosUserInterruptionByRange = cappedIos.map((f) => f.filterUserByInterruptionRangeByPlatform('ios')).toList();

    double maxAndroid = 0;
    if (androidUserInterruptionByRange.isNotEmpty) {
      maxAndroid = androidUserInterruptionByRange.map((a) => a.reduce(max)).reduce(max).toDouble();
    }

    double maxIos = 0;
    if (iosUserInterruptionByRange.isNotEmpty) {
      maxIos = iosUserInterruptionByRange.map((a) => a.reduce(max)).reduce(max).toDouble();
    }

    final lineColors = [
      Colors.grey.shade200,
      Colors.grey.shade400,
      Colors.red.shade200,
      Colors.red.shade400,
      Colors.red.shade900,
    ];

    final androidLineDataList = <List<double>>[];
    final iosLineDataList = <List<double>>[];
    InterruptionRange.values.forEachIndexed((i, e) {
      androidLineDataList.add(androidUserInterruptionByRange.map((a) => a[i]).toList());
      iosLineDataList.add(iosUserInterruptionByRange.map((a) => a[i]).toList());
    });

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
              lineDataList: androidLineDataList,
              lineTitleList: InterruptionRange.values.map((e) => e.label).toList(),
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
              lineDataList: iosLineDataList,
              lineTitleList: InterruptionRange.values.map((e) => e.label).toList(),
              subToolTipData: const [],
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

  // Future<void> _exportCSV({InterruptionRange? range}) async {
  //   try {
  //     final dateTime = (range != null ? AnalyticService.instance.dailyReportFiles.filterByRange(range) : AnalyticService.instance.dailyReportFiles).toDateTimeRangeLabels();
  //     setState(() => _isLoading = true);
  //     await FileService.instance.exportCsv(
  //       AnalyticService.instance.dailyReportFiles.toCSVData(),
  //       dateRange: dateTime.toString(),
  //       // startTime: DateTime.now().subtract(const Duration(days: 1)),
  //       // endTime: DateTime.now(),
  //     );
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   } catch (error, stackTrace) {
  //     debugPrint('Failed to refresh total cgm data: $error\n$stackTrace');
  //     ToastService.show(
  //       context: context,
  //       'Đã có lỗi xảy ra, vui lòng thử lại',
  //       type: ToastType.error,
  //     );
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _exportCSV() async {
    // Show the export options dialog
    final selectedRanges = await ExportDialogPresets.showInterruptionRangeDialog(
      context: context,
      title: 'Xuất dữ liệu CSV',
      subtitle: 'Chọn các mức độ chậm đồng bộ bạn muốn xuất',
    );

    // User cancelled the dialog
    if (selectedRanges == null) return;

    try {
      setState(() => _isLoading = true);

      // Filter data by selected ranges
      final filteredData = selectedRanges.isEmpty
          ? AnalyticService.instance.dailyReportFiles
          : AnalyticService.instance.dailyReportFiles.filterByRanges(selectedRanges);

      final dateTime = filteredData.toDateTimeRangeLabels();

      await FileService.instance.exportCsv(
        filteredData.toCSVData(),
        dateRange: dateTime.toString(),
      );

      setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      debugPrint('Failed to export CSV: $error\n$stackTrace');
      ToastService.show(
        context: context,
        'Đã có lỗi xảy ra, vui lòng thử lại',
        type: ToastType.error,
      );
      setState(() => _isLoading = false);
    }
  }

// ============================================================================
// OR use the full export dialog with more options:
// ============================================================================

  /// Full version - InterruptionRange + VIP filter
  Future<void> _exportCSVFull() async {
    // Show the full export options dialog
    final settings = await ExportDialogPresets.showFullExportDialog(
      context: context,
      title: 'Xuất dữ liệu CSV',
    );

    // User cancelled the dialog
    if (settings == null) return;

    try {
      setState(() => _isLoading = true);

      // Start with all data
      var data = AnalyticService.instance.dailyReportFiles;

      // Filter by selected ranges
      if (settings.ranges.isNotEmpty) {
        data = data.filterByRanges(settings.ranges);
      }

      // Filter by VIP if enabled
      // Note: You may need to add a filterByVip method to your extension
      // if (settings.vipOnly) {
      //   data = data.filterByVip();
      // }

      final dateTime = data.toDateTimeRangeLabels();

      await FileService.instance.exportCsv(
        data.toCSVData(),
        dateRange: dateTime.toString(),
      );

      setState(() => _isLoading = false);

      ToastService.show(
        context: context,
        'Xuất dữ liệu thành công',
        type: ToastType.success,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to export CSV: $error\n$stackTrace');
      ToastService.show(
        context: context,
        'Đã có lỗi xảy ra, vui lòng thử lại',
        type: ToastType.error,
      );
      setState(() => _isLoading = false);
    }
  }

// ============================================================================
// If you need to use the dialog directly with custom options:
// ============================================================================

  Future<void> _exportCSVCustom() async {
    final result = await ExportOptionsDialog.show(
      context: context,
      title: 'Tùy chọn xuất dữ liệu',
      subtitle: 'Cấu hình các tùy chọn xuất',
      options: [
        // Multi-select for interruption ranges
        ExportOption(
          id: 'ranges',
          label: 'Mức độ chậm đồng bộ',
          description: 'Chọn một hoặc nhiều mức độ',
          type: ExportOptionType.multiSelect,
          choices: InterruptionRange.values
              .map((e) => ExportChoice(id: e.name, label: e.label, value: e))
              .toList(),
          defaultValues: InterruptionRange.values, // All selected by default
        ),

        // Single-select for platform
        const ExportOption(
          id: 'platform',
          label: 'Nền tảng',
          type: ExportOptionType.singleSelect,
          choices: [
            ExportChoice(id: 'all', label: 'Tất cả', value: 'all'),
            ExportChoice(id: 'android', label: 'Android', value: 'android'),
            ExportChoice(id: 'ios', label: 'iOS', value: 'ios'),
          ],
          defaultValue: 'all',
        ),

        // Toggle for VIP only
        const ExportOption(
          id: 'vip_only',
          label: 'Lọc VIP',
          type: ExportOptionType.toggle,
          choices: [
            ExportChoice(id: 'vip', label: 'Chỉ xuất khách VIP', value: true),
          ],
          defaultValue: false,
        ),
      ],
    );

    if (result == null) return; // User cancelled

    try {
      setState(() => _isLoading = true);

      // Extract values from result
      final selectedRanges = (result['ranges'] as Set<dynamic>?)?.cast<InterruptionRange>() ?? {};
      final platform = result['platform'] as String? ?? 'all';
      final vipOnly = result['vip_only'] as bool? ?? false;

      debugPrint('Selected ranges: $selectedRanges');
      debugPrint('Platform: $platform');
      debugPrint('VIP only: $vipOnly');

      // Start with all data
      var filteredData = AnalyticService.instance.dailyReportFiles;

      // Filter by selected ranges
      if (selectedRanges.isNotEmpty) {
        filteredData = filteredData.filterByRanges(selectedRanges);
      }

      // Filter by platform
      if (platform != 'all') {
        filteredData = filteredData.filterByPlatform(platform);
      }

      // Filter by VIP
      if (vipOnly) {
        filteredData = filteredData.filterByVip();
      }

      // Remove empty days after filtering
      filteredData = filteredData.removeEmptyDays();

      final dateTime = filteredData.toDateTimeRangeLabels();

      await FileService.instance.exportCsv(
        filteredData.toCSVData(),
        dateRange: dateTime.toString(),
      );

      setState(() => _isLoading = false);
    } catch (error, stackTrace) {
      debugPrint('Failed to export CSV: $error\n$stackTrace');
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