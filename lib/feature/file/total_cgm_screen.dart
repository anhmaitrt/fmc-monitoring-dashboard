import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/table/cell_widget.dart';
import 'package:fmc_monitoring_dashboard/core/services/analytic_service.dart';
import 'package:fmc_monitoring_dashboard/model/total_cgm_file.dart';

import '../../core/services/toast_service.dart';

class TotalCGMScreen extends StatefulWidget {
  const TotalCGMScreen({super.key});

  @override
  State<TotalCGMScreen> createState() => _TotalCGMScreenState();
}

class _TotalCGMScreenState extends State<TotalCGMScreen> {
  // List<List<TotalCgmFile>> _totalCGMFiles = List.empty(growable: true);
  bool _isLoading = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   _refresh();
    // });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Load total ${AnalyticService.instance.totalCGMFiles.length} files for total cgm data');
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
                  ...AnalyticService.instance.totalCGMFiles.map((files) => _buildTable(_filterRows(files)))
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


  Widget _buildTable(List<TotalCgmFile> files) {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: {
        0: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[300]),
          children: [
            CellWidget(
              text: "Id (${files.firstOrNull?.fileName})",
              enableCopyOnTap: false,
            ),
            CellWidget(text: "Số Điện Thoại",
              enableCopyOnTap: false,),
            CellWidget(text: "Họ Tên",
              enableCopyOnTap: false,),
            CellWidget(text: "Platform\n(${files.countPlatform('android')} android, ${files.countPlatform('ios')} ios)",
              enableCopyOnTap: false,),
            CellWidget(text: "Đã xoá",
              enableCopyOnTap: false,),
            CellWidget(text: "Ngày Bắt Đầu",
              enableCopyOnTap: false,),
            CellWidget(text: "Ngày Kết Thúc",
              enableCopyOnTap: false,),
          ],
        ),
        // Data rows
        ...files.map((file) {
          return TableRow(
            children: [
              CellWidget(
                text: file.id ?? '',
              ),
              CellWidget(
                text: file.phoneNumber ?? '',
              ),
              CellWidget(
                text: file.name ?? '',
              ),
              CellWidget(
                text: file.platform ?? '',
                enableCopyOnTap: false,
              ),
              CellWidget(
                text: (file.isDeleted ?? false) ? 'true' : 'false',
                enableCopyOnTap: false,
              ),
              CellWidget(
                text: file.startDate ?? '',
                enableCopyOnTap: false,
              ),
              CellWidget(
                text: file.endDate ?? '',
                enableCopyOnTap: false,
              ),
            ],
          );
        })
      ],
    );
  }
  //#endregion

  //#region ACTION
  Future<void> _refresh() async {
    try {
      print('Loading total cgm data');
      setState(() {
        ToastService.show(context, 'Đang tải...', type: ToastType.info, duration: null,);
        _isLoading = true;
      });
      await AnalyticService.instance.fetchDB();
      setState(() {
        _isLoading = false;
        ToastService.show(context, 'Tải xong ${AnalyticService.instance.totalCGMFiles.length} file(s)', type: ToastType.success);
      });
    } catch (error, stackTrace) {
      print('Failed to refresh total cgm data: $error');
      ToastService.show(context, 'Đã có lỗi xảy ra, vui lòng thử lại', type: ToastType.error);
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<TotalCgmFile> _filterRows(List<TotalCgmFile> files) {
    if (_query.isEmpty) return files;

    bool match(String? s) => (s ?? '').toLowerCase().contains(_query);

    return files.where((f) {
      return match(f.id) ||
          match(f.phoneNumber) ||
          match(f.name) ||
          match(f.platform) ||
          match(f.startDate) ||
          match(f.endDate);
    }).toList();
  }
  //#endregion
}