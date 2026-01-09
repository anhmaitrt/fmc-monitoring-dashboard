import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/services/settings/settings.dart';

import '../../style/app_colors.dart';

class SettingsOverlay extends StatefulWidget {
  const SettingsOverlay({
    super.key,
  });

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Card(
          elevation: 12,
          color: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ToggleButtons(
                    isSelected: [Settings.filterStopSync],
                    onPressed: (int index) {
                      setState(() {});

                    },
                    children: const <Widget>[
                      Icon(Icons.filter_alt_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _fetchData() async {
  //   try {
  //     print('Loading total cgm data');
  //     await AnalyticService.instance.fetchDB();
  //   } catch (error, stackTrace) {
  //     print('Failed to refresh total cgm data: $error');
  //     ToastService.show(context, 'Đã có lỗi xảy ra, vui lòng thử lại', type: ToastType.error);
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }
}
