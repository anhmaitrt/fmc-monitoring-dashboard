import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmc_monitoring_dashboard/core/components/scaffold_widget.dart';
import 'package:fmc_monitoring_dashboard/core/utils/extension/string_extension.dart';
import 'package:fmc_monitoring_dashboard/model/user_cgm_data_row.dart';
import 'package:get/get_navigation/src/root/parse_route.dart';

import '../../core/components/chart/line_chart_widget.dart';
import '../../core/services/analytic_service.dart';
import '../../core/services/toast_service.dart';
import '../../core/style/app_colors.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({
    super.key,
  });

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
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
    var data = _query.isNullOrEmpty ? List<List<UserCGMDataRow>>.empty() : AnalyticService.instance.dataFiles.map((files) => files.filter(_query)).toList();
    data = data.reversed.toList();

    int limit = 30;
    if(data.length >= limit) {
      data.removeRange(0, data.length-limit);
      data.removeWhere((e) => e.isEmpty);
    }

    UserCGMDataRow? user;
    if(data.every((e) => e.every((f) => f.phoneNumber == _query))) {
      user = data.firstOrNull?.firstOrNull;
    }

    return ScaffoldWidget(
      title: 'Chi tiết khách',
      body: SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _buildUserDetails(user),
                    Container(
                        height: 350,
                        margin: EdgeInsets.only(top: 16),
                        child: _buildInterruptionChart(user != null ? data : [])
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //#region UI
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Nhập sđt để tìm kiếm',
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

  Widget _buildUserDetails(UserCGMDataRow? user) {
    return SizedBox(
      width: double.infinity,
      child: Card.filled(
        color: AppColors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: user == null ? Center(child: Text('Không có dữ liệu')) : Column(
            children: [
              _buildUserDetailsItem(
                label: 'Họ Tên',
                text: '${user.fullName}',
                content: user.fullName ?? ''
              ),
              _buildUserDetailsItem(
                label: 'SĐT',
                text: '${user.phoneNumber}',
                content: user.phoneNumber ?? ''
              ),
              _buildUserDetailsItem(
                label: 'Id',
                text: '${user.userId?.replaceRange(0, user.userId!.length - 12, 'xxxxx-xxxxx-')}',
                content: user.userId ?? '',
              ),
              _buildUserDetailsItem(
                label: 'Hệ Điều Hành',
                text: '${user.platform}',
                content: user.platform ?? '',
              ),
            ],
          ),
        ),
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
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold),),
          InkWell(
            onTap: () => onTap(context, content),
            hoverColor: Colors.blue.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SelectableText(text),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildChart({required Widget chart}) {
    return Card.filled(
      color: AppColors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: chart,
      ),
    );
  }

  Widget _buildInterruptionChart(
      List<List<UserCGMDataRow>> data,
  ) {
    if(data.isEmpty) {
      return Center(
        child: Text('Không có dữ liệu'),
      );
    }
    final interruptionPercentageList = data.map((f) => f.percentageInterruption).toList();

    // print('android user: ${androidUsers.length} - $androidPercentageInterruptionList'
    //     '\nios user: ${iosUser.length} - $iosPercentageInterruptionList');
    return _buildChart(
      chart: LineChartWidget(
        chartName: 'Tỉ lệ chậm đồng bộ theo ngày',
        maxX: data.maxX,
        maxY: [...interruptionPercentageList,].reduce(max),
        topTitles: [],
        bottomTitles: data.toDateList(),
        leftTitles: [],
        leftAxisName: '%',
        lineDataList: [interruptionPercentageList],
        lineTitleList: [],
        subToolTipData: [
          data.map((f) => '${f.getUserWithLongestGap().fullName} (${f.totalGapTimeInHour.toStringAsFixed(1)}h)').toList(),
        ],
        unit: '%',
        lineColors: [Colors.lightBlue.shade400],
      )
    );
  }
  //#endregion

  //#region ACTION
  Future<void> onTap(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ToastService.show(context: context, 'Đã copy $text', type: ToastType.info);
    } catch (error, stackTrace) {
      ToastService.show(context: context, 'Đã có lỗi xảy ra, vui lòng thử lại', type: ToastType.error);
    }
  }
  //#endregion
}
