import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/utils/app_size.dart';
import 'package:fmc_monitoring_dashboard/model/total_cgm_file.dart';

import '../../core/services/google_service.dart';
import '../../core/style/app_colors.dart';

class TotalCGMScreen extends StatefulWidget {
  const TotalCGMScreen({super.key});

  @override
  State<TotalCGMScreen> createState() => _TotalCGMScreenState();
}

class _TotalCGMScreenState extends State<TotalCGMScreen> {
  List<List<TotalCgmFile>> _totalCGMFiles = List.empty(growable: true);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _refresh();
    });
  }final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
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
      // body: ListView(
      //   children: [
      //     ..._totalCGMFiles.map((files) => _buildTable(files))
      //   ],
      // ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ..._totalCGMFiles.map((files) => _buildTable(_filterRows(files)))
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
          hintText: 'Search by id / phone / name / platform...',
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
            Padding(padding: EdgeInsets.all(8), child: Text("Id (${files.firstOrNull?.fileName})")),
            Padding(padding: EdgeInsets.all(8), child: Text("Số Điện Thoại")),
            Padding(padding: EdgeInsets.all(8), child: Text("Họ Tên")),
            Padding(padding: EdgeInsets.all(8), child: Text("Platform\n(${files.countPlatform('android')} android, ${files.countPlatform('ios')} ios)")),
            Padding(padding: EdgeInsets.all(8), child: Text("Đã xoá")),
            Padding(padding: EdgeInsets.all(8), child: Text("Ngày Bắt Đầu")),
            Padding(padding: EdgeInsets.all(8), child: Text("Ngày Kết Thúc")),
          ],
        ),
        // Data rows
        ...files.map((file) {
          return TableRow(
            children: [
              Padding(padding: EdgeInsets.all(8), child: Text(file.id ?? '')),
              Padding(padding: EdgeInsets.all(8), child: Text(file.phoneNumber ?? '')),
              Padding(padding: EdgeInsets.all(8), child: Text(file.name ?? '')),
              Padding(padding: EdgeInsets.all(8), child: Text(file.platform ?? '')),
              Padding(padding: EdgeInsets.all(8), child: Text((file.isDeleted ?? false) ? 'true' : 'false',)),
              Padding(padding: EdgeInsets.all(8), child: Text(file.startDate ?? '')),
              Padding(padding: EdgeInsets.all(8), child: Text(file.endDate ?? '')),
            ],
          );
        })
      ],
    );
    // return Column(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     Text(files.firstOrNull?.fileName ?? ''),
    //     Expanded(
    //       child: Table(
    //         border: TableBorder.all(color: Colors.black),
    //         columnWidths: {
    //           0: FlexColumnWidth(2),
    //         },
    //         children: [
    //           TableRow(
    //             decoration: BoxDecoration(color: Colors.grey[300]),
    //             children: [
    //               Padding(padding: EdgeInsets.all(8), child: Text("Id")),
    //               Padding(padding: EdgeInsets.all(8), child: Text("Số Điện Thoại")),
    //               Padding(padding: EdgeInsets.all(8), child: Text("Họ Tên")),
    //               Padding(padding: EdgeInsets.all(8), child: Text("Platform")),
    //               Padding(padding: EdgeInsets.all(8), child: Text("Đã Xóa")),
    //               Padding(padding: EdgeInsets.all(8), child: Text("Ngày Bắt Đầu")),
    //               Padding(padding: EdgeInsets.all(8), child: Text("Ngày Kết Thúc")),
    //             ],
    //           ),
    //           // Data rows
    //           ...files.map((file) {
    //             return TableRow(
    //               children: [
    //                 Padding(padding: EdgeInsets.all(8), child: Text(file.id ?? '')),
    //                 Padding(padding: EdgeInsets.all(8), child: Text(file.phoneNumber ?? '')),
    //                 Padding(padding: EdgeInsets.all(8), child: Text(file.name ?? '')),
    //                 Padding(padding: EdgeInsets.all(8), child: Text(file.platform ?? '')),
    //                 Padding(padding: EdgeInsets.all(8), child: Text((file.isDeleted ?? false) ? 'true' : 'false')),
    //                 Padding(padding: EdgeInsets.all(8), child: Text(file.startDate ?? '')),
    //                 Padding(padding: EdgeInsets.all(8), child: Text(file.endDate ?? '')),
    //               ],
    //             );
    //           })
    //         ],
    //       ),
    //     ),
    //   ],
    // );
  }
  //#endregion

  //#region ACTION
  Future<void> _refresh() async {
    try {
      setState(() {
        _isLoading = true;
        _totalCGMFiles.clear();
      });
      await GoogleService.instance.fetchDB();
      setState(() {
        _isLoading = false;
        _totalCGMFiles = GoogleService.instance.totalCGMFiles;
      });
    } catch (error, stackTrace) {
      print('Failed to refresh total cgm data: $error');
      setState(() {
        _isLoading = false;
        _totalCGMFiles.clear();
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

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _Cell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal),
      ),
    );
  }
}