import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/feature/file/data_screen.dart';
import 'package:fmc_monitoring_dashboard/feature/home/home_screen.dart';
import 'package:fmc_monitoring_dashboard/feature/user_details/user_details_screen.dart';
import 'package:sidebarx/sidebarx.dart';

import '../core/components/side_bar_widget.dart';
import '../core/components/toast/loading_widget.dart';
import '../core/services/analytic_service.dart';
import 'log/log_screen.dart';
import 'log_report/import_log_report_screen.dart';

class AppNavigationWidget extends StatefulWidget {
  const AppNavigationWidget({super.key});

  @override
  State<AppNavigationWidget> createState() => _AppNavigationWidgetState();
}

class _AppNavigationWidgetState extends State<AppNavigationWidget> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);

  // ✅ Keep ONE instance per page (don’t recreate in build)
  late final List<Widget> pages = const [
    HomeScreen(),
    DataScreen(),
    UserDetailsScreen(),
    LogScreen(),
    ImportLogReportScreen(),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              SideBarWidget(
                controller: _controller,
                items: [
                  SidebarXItem(
                    icon: Icons.home,
                    label: 'Tổng quan',
                    onTap: () => debugPrint('Tổng quan'),
                  ),
                  const SidebarXItem(
                    icon: Icons.summarize,
                    label: 'Chi tiết',
                  ),
                  const SidebarXItem(
                    icon: Icons.summarize,
                    label: 'Chi tiết khách',
                  ),
                  const SidebarXItem(
                    icon: Icons.analytics,
                    label: 'Log kỹ thuật',
                  ),
                  const SidebarXItem(
                    icon: Icons.upload_file,
                    label: 'Import Log',
                  ),
                  SidebarXItem(
                    icon: Icons.settings,
                    label: 'Cài đặt',
                    selectable: false,
                    onTap: () => _showDisabledAlert(context),
                  ),
                ],
              ),
              _buildBody(),
            ],
          ),
          LoadingOverlay(
            progressStream: AnalyticService.instance.progressStream,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Expanded(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return IndexedStack(
            index: _controller.selectedIndex,
            children: pages,
          );
        },
      ),
    );
  }

  void _showDisabledAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Item disabled for selecting',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
}

