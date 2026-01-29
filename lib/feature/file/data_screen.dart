import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/components/chart/line_chart_widget.dart';
import '../../core/components/copyable_widget.dart';
import '../../core/components/scaffold_widget.dart';
import '../../core/components/table/cell_widget.dart';
import '../../core/services/analytic_service.dart';
import '../../core/services/toast_service.dart';
import '../../core/style/app_colors.dart';
import '../../core/utils/extension/date_extension.dart';
import '../../core/utils/extension/string_extension.dart';
import '../../model/interruption_range.dart';
import '../../model/user_cgm_data_row.dart';
import '../../model/user_model.dart';
import '../user_details/user_info_card.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  bool _isLoading = false;

  final _searchCtrl = TextEditingController();
  String _query = '';

  // ✅ Pagination state
  int _rowsPerPage = 10;
  int _pageIndex = 0; // 0-based
  final List<int> _rowsPerPageOptions = const [5, 10, 20, 50, 100];

  // ✅ Multi-range filter (empty = All)
  final Set<InterruptionRange> _rangeFilters = <InterruptionRange>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // -----------------------
  // HELPERS
  // -----------------------

  void _resetPaging() => setState(() => _pageIndex = 0);

  void _goToPage(int newIndex) {
    setState(() {
      _pageIndex = newIndex.clamp(0, _totalPages - 1);
    });
  }

  void _toggleRange(InterruptionRange r) {
    setState(() {
      if (_rangeFilters.contains(r)) {
        _rangeFilters.remove(r);
      } else {
        _rangeFilters.add(r);
      }
      _pageIndex = 0;
    });
  }

  /// Keep two lists per day:
  /// - all: after SEARCH only
  /// - view: after SEARCH + RANGE FILTERS
  List<({List<UserCGMDataRow> all, List<UserCGMDataRow> view})> get _groupViews {
    final groups = AnalyticService.instance.dataFiles;

    return groups
        .map((g) {
      final searched = g.filter(_query); // ✅ search only
      final view = searched.filterByRanges(_rangeFilters); // ✅ multi-range
      return (all: searched, view: view);
    })
        .where((x) => x.view.isNotEmpty) // only days visible after filters
        .toList();
  }

  int get _totalItems => _groupViews.length;

  int get _totalPages {
    if (_totalItems == 0) return 1;
    return (_totalItems / _rowsPerPage).ceil();
  }

  List<({List<UserCGMDataRow> all, List<UserCGMDataRow> view})> get _pagedGroupViews {
    final list = _groupViews;
    if (list.isEmpty) return const [];

    final start = _pageIndex * _rowsPerPage;
    if (start >= list.length) return const [];

    final end = (start + _rowsPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  /// Find latest row that matches exactly phone or userId (from whole dataset)
  UserCGMDataRow? _findExactUserRow() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return null;

    // dataFiles is usually newest->oldest (based on your fetch sort)
    for (final day in AnalyticService.instance.dataFiles) {
      for (final row in day) {
        final phone = row.phoneNumber?.trim().toLowerCase();
        final uid = row.userId?.trim().toLowerCase();
        if ((phone?.contains(q) ?? false) || (uid?.contains(q) ?? false)) return row; // first hit = latest
      }
    }
    return null;
  }

  /// Build per-day list for that user (each day contains only that user's row(s))
  List<List<UserCGMDataRow>> _userHistoryDays(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final newestToOldest = <List<UserCGMDataRow>>[];

    for (final day in AnalyticService.instance.dataFiles) {
      final hits = day.where((r) {
        final phone = r.phoneNumber?.trim().toLowerCase();
        final uid = r.userId?.trim().toLowerCase();
        return phone == query || uid == query;
      }).toList();

      if (hits.isNotEmpty) newestToOldest.add(hits);
    }

    // chart usually wants oldest -> newest
    return newestToOldest.reversed.toList();
  }

  // -----------------------
  // UI
  // -----------------------

  @override
  Widget build(BuildContext context) {
    final paged = _pagedGroupViews;

    return ScaffoldWidget(
      title: 'Chi tiết',
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
        ),
      ],
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildUserDetails(),
                  const SizedBox(height: 16),
                  ...paged.map((g) => _buildTable(g.view, totalFiles: g.all)),
                ],
              ),
            ),
          ),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() => _query = v.trim().toLowerCase());
              _resetPaging();
            },
            decoration: InputDecoration(
              hintText: 'Nhập từ khóa để tìm kiếm id / phone / name / platform...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                  _resetPaging();
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // ✅ Multi-select chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: _rangeFilters.isEmpty,
                onSelected: (_) {
                  setState(() {
                    _rangeFilters.clear();
                    _pageIndex = 0;
                  });
                },
              ),
              ...InterruptionRange.values.map((r) {
                return FilterChip(
                  label: Text(r.label),
                  selected: _rangeFilters.contains(r),
                  onSelected: (_) => _toggleRange(r),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetails() {
    final row = _findExactUserRow();
    if (row == null) return const SizedBox.shrink();

    final user = AnalyticService.instance.userList.getUserById(row.userId ?? '');
    final history = _userHistoryDays(_query);

    return SizedBox(
      width: double.infinity,
      child: Card.filled(
        color: AppColors.white,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  _buildUserDetailsItem(
                    label: 'Họ Tên',
                    text: '${row.fullName}',
                    content: row.fullName ?? '',
                  ),
                  _buildUserDetailsItem(
                    label: 'SĐT',
                    text: row.phoneNumber.maskPhone(),
                    content: row.phoneNumber ?? '',
                  ),
                  _buildUserDetailsItem(
                    label: 'Id',
                    text: '${row.userId?.maskUuid()}',
                    content: row.userId ?? '',
                  ),
                  _buildUserDetailsItem(
                    label: 'Phiên bản app',
                    text: '${user?.appVersion}',
                    content: user?.appVersion ?? '',
                  ),
                  _buildUserDetailsItem(
                    label: 'Hệ Điều Hành',
                    text: '${row.platform} ${user?.platformVersion}',
                    content: '${row.platform} ${user?.platformVersion}',
                  ),
                  _buildUserDetailsItem(
                    label: 'Dòng điện thoại',
                    text: '${user?.deviceModel}',
                    content: user?.deviceModel ?? '',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 350,
              child: _buildInterruptionChart(history),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterruptionChart(List<List<UserCGMDataRow>> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final interruptionPercentageList = data.map((f) => f.percentageInterruption).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: LineChartWidget(
        chartName: 'Tỉ lệ chậm đồng bộ theo ngày',
        maxX: data.maxX,
        maxY: interruptionPercentageList.reduce(max),
        topTitles: const [],
        bottomTitles: data.toDateList(),
        leftTitles: const [],
        leftAxisName: '%',
        lineDataList: [interruptionPercentageList],
        lineTitleList: const [],
        subToolTipData: [
          data
              .map((f) =>
          '${f.getUserWithLongestGap().fullName} (${f.totalGapTimeInHour.toStringAsFixed(1)}h)')
              .toList(),
        ],
        unit: '%',
        lineColors: [Colors.lightBlue.shade400],
      ),
    );
  }

  Widget _buildUserDetailsItem({
    required String label,
    required String text,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          CopyableWidget(text: text, copyableContent: content),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    final total = _totalItems;
    final start = total == 0 ? 0 : (_pageIndex * _rowsPerPage) + 1;
    final end = total == 0 ? 0 : ((_pageIndex * _rowsPerPage) + _pagedGroupViews.length);

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('Trang ${_pageIndex + 1} / $_totalPages · Hiển thị $start–$end / $total'),
          const Spacer(),
          const Text('Rows/page: '),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _rowsPerPage,
            items: _rowsPerPageOptions
                .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _rowsPerPage = v;
                _pageIndex = 0;
              });
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'First',
            onPressed: (_pageIndex <= 0) ? null : () => _goToPage(0),
            icon: const Icon(Icons.first_page),
          ),
          IconButton(
            tooltip: 'Prev',
            onPressed: (_pageIndex <= 0) ? null : () => _goToPage(_pageIndex - 1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed: (_pageIndex >= _totalPages - 1) ? null : () => _goToPage(_pageIndex + 1),
            icon: const Icon(Icons.chevron_right),
          ),
          IconButton(
            tooltip: 'Last',
            onPressed: (_pageIndex >= _totalPages - 1) ? null : () => _goToPage(_totalPages - 1),
            icon: const Icon(Icons.last_page),
          ),
        ],
      ),
    );
  }

  /// files = filtered by (search + ranges)
  /// totalFiles = filtered by (search only)
  Widget _buildTable(List<UserCGMDataRow> files, {required List<UserCGMDataRow> totalFiles}) {
    if (files.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    // ✅ avoid mutating original list
    final sorted = [...files]
      ..sort((a, b) => a.interruptionPercentage < b.interruptionPercentage ? 1 : -1);

    // ✅ show filtered/total counts
    final totalCount = totalFiles.length;
    final filteredCount = files.length;

    final androidTotal = totalFiles.countByPlatform('android');
    final iosTotal = totalFiles.countByPlatform('ios');

    final androidFiltered = files.countByPlatform('android');
    final iosFiltered = files.countByPlatform('ios');

    final day = (totalFiles.firstOrNull ?? sorted.firstOrNull)?.dateTime?.formatddMMyyyy ?? '';

    return Card.filled(
      color: AppColors.white,
      child: ExpansionTile(
        title: Text(
          '$day: ${filteredCount == totalCount ? '$filteredCount' : '$filteredCount/$totalCount'} khách '
              '(${androidFiltered == androidTotal ? '$androidFiltered' : '$androidFiltered/$androidTotal'} android, ${iosFiltered == iosTotal ? '$iosFiltered' : '$iosFiltered/$iosTotal'} ios)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          sorted.summarizeSyncGaps(totalUsersAndroid: androidTotal, totalUsersIos: iosTotal),
          style: const TextStyle(fontSize: 14),
        ),
        children: [
          Table(
            border: TableBorder.all(color: Colors.black),
            columnWidths: const {
              0: FlexColumnWidth(0.8), //Id
              1: FlexColumnWidth(0.4), //SDT
              2: FlexColumnWidth(0.8), //Name
              3: FlexColumnWidth(0.1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey[300]),
                children: const [
                  CellWidget(text: "Khách", enableCopyOnTap: false),
                  CellWidget(text: 'Ngày Bắt Đầu - Kết Thúc', enableCopyOnTap: false),
                  CellWidget(text: 'Khoảng chậm', enableCopyOnTap: false),
                  CellWidget(text: '', enableCopyOnTap: false),
                ],
              ),
              ...sorted.map((file) {
                return TableRow(
                  decoration: (file.isDeleted ?? false)
                      ? const BoxDecoration(color: AppColors.disableText)
                      : null,
                  children: [
                    CellWidget(
                      content: UserInfoCard(user: AnalyticService.instance
                          .userList.getUserById(file.userId ?? ''),
                        showId: true,
                      ),
                    ),
                    CellWidget(
                      text:
                      'Đã dùng ${file.currentSessionDuration.inDays} ngày\n${file.startedAt} - ${file.stoppedAt}',
                      enableCopyOnTap: false,
                    ),
                    CellWidget(
                      text: file.summarizeSyncGaps(),
                      enableCopyOnTap: false,
                    ),
                    Column(
                      children: [
                        TextButton(
                          child: const Text('Lọc'),
                          onPressed: () => setState(() {
                            if (file.phoneNumber.isNullOrEmpty) return;
                            _query = file.phoneNumber!.trim().toLowerCase();
                            _searchCtrl.text = _query;
                            _pageIndex = 0;
                          }),
                        ),
                      ],
                    )
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------
  // ACTION
  // -----------------------

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);

      await AnalyticService.instance.fetchDB();

      setState(() {
        _isLoading = false;
        _pageIndex = 0;
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
}
