import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/table/cell_widget.dart';
import 'package:fmc_monitoring_dashboard/core/services/analytic_service.dart';
import 'package:fmc_monitoring_dashboard/model/user_cgm_file.dart';

import '../../core/services/toast_service.dart';
import '../../core/style/app_colors.dart';
import '../../core/utils/extension/date_extension.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  bool _isLoading = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Load total ${AnalyticService.instance.dataFiles.length} files for total cgm data');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng khách dùng CGM'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refresh,
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ...AnalyticService.instance.dataFiles.map((files) => _buildTable(_filterRows(files)))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //#region UI
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
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
            },
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTable(List<UserCGMFile> files) {
    return files.isEmpty ? const Center(child: Text('Không có dữ liệu')) : ExpansionTile(
      title: Text('${files.firstOrNull?.dateTime?.formatddMMyyyy}: ${files.length} khách'),
      children: [
        Table(
          border: TableBorder.all(color: Colors.black),
          columnWidths: {
            0: FlexColumnWidth(0.8), //Id
            1: FlexColumnWidth(0.4), //SDT
            2: FlexColumnWidth(0.4),
            3: FlexColumnWidth(0.4),
            4: FlexColumnWidth(0.8),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[300]),
              children: [
                CellWidget(
                  text: "Id",
                  enableCopyOnTap: false,
                ),
                CellWidget(text: "Số Điện Thoại",
                  enableCopyOnTap: false,),
                CellWidget(text: "Họ Tên",
                  enableCopyOnTap: false,),
                CellWidget(text: "Platform\n(${files.countByPlatform('android')} android, ${files.countByPlatform('ios')} ios)",
                  enableCopyOnTap: false,),
                CellWidget(text: 'Ngày Bắt Đầu - Kết Thúc',
                  enableCopyOnTap: false,),
                CellWidget(text: 'Khoảng chậm',
                  enableCopyOnTap: false,),
              ],
            ),
            // Data rows
            ...files.map((file) {
              return TableRow(
                decoration: (file.isDeleted ?? false) ? BoxDecoration(color: AppColors.disableText) : null,
                children: [
                  CellWidget(
                    text: file.userId ?? '',
                  ),
                  CellWidget(
                    text: file.phoneNumber ?? '',
                  ),
                  CellWidget(
                    text: file.fullName ?? '',
                  ),
                  CellWidget(
                    text: file.platform ?? '',
                    enableCopyOnTap: false,
                  ),
                  CellWidget(
                    text: 'Đã dùng ${file.currentSessionDuration.inDays} ngày\n${file.startedAt} - ${file.stoppedAt}',
                    enableCopyOnTap: false,
                  ),
                  CellWidget(
                    text: file.summarizeSyncGaps(),
                    enableCopyOnTap: false,
                  ),
                ],
              );
            })
          ],
        )
      ],
    );
  }

  // Widget _buildPaginatedDataTable() {
  //   return PaginatedDataTable(
  //     header: const Text('Tổng khách dùng CGM'),
  //     rowsPerPage: 50,
  //     availableRowsPerPage: const [10, 25, 50, 100],
  //     onRowsPerPageChanged: (v) {
  //       if (v == null) return;
  //       // setState(() => _rowsPerPage = v);
  //     },
  //     columns: const [
  //       DataColumn(label: Text('User ID')),
  //       DataColumn(label: Text('Số Điện Thoại')),
  //       DataColumn(label: Text('Họ Tên')),
  //       DataColumn(label: Text('Platform')),
  //       DataColumn(label: Text('Đã Xóa')),
  //       DataColumn(label: Text('Bắt đầu')),
  //       DataColumn(label: Text('Kết thúc')),
  //       DataColumn(label: Text('Sync gaps')),
  //     ],
  //     source: source,
  //   );
  // }
  //#endregion

  //#region ACTION
  Future<void> _refresh() async {
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

  List<UserCGMFile> _filterRows(List<UserCGMFile> files) {
    if (_query.isEmpty) return files;

    bool match(String? s) => (s ?? '').toLowerCase().contains(_query);

    return files.where((f) {
      return match(f.userId) ||
          match(f.phoneNumber) ||
          match(f.fullName) ||
          match(f.platform) ||
          match(f.startedAt) ||
          match(f.stoppedAt);
    }).toList();
  }
  //#endregion
}