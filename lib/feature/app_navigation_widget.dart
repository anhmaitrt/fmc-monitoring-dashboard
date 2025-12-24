import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/feature/file/data_screen.dart';
import 'package:fmc_monitoring_dashboard/feature/home/home_screen.dart';
import 'package:sidebarx/sidebarx.dart';

import '../core/components/side_bar_widget.dart';
import '../core/components/toast/loading_widget.dart';
import '../core/services/analytic_service.dart';

class AppNavigationWidget extends StatefulWidget {
  const AppNavigationWidget({super.key});

  @override
  State<AppNavigationWidget> createState() => _AppNavigationWidgetState();
}

class _AppNavigationWidgetState extends State<AppNavigationWidget> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);

  final pages = [
    HomeScreen(),
    DataScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              SideBarWidget(controller: _controller),
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
          return pages[_controller.selectedIndex];
        },
      ),
    );
  }
}
