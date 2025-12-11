import 'dart:async';

// import 'package:fhc_component/core/common/widget/bar/snackbar/toast_content_widget.dart';
// import 'package:fhc_component/core/common/widget/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/components/toast/toast_content_widget.dart';
import 'package:fmc_monitoring_dashboard/core/components/toast/toast_type.dart';

import '../../../feature/app.dart';

class ToastWidget {
  ToastWidget._();

  static ToastWidget instance = ToastWidget._();
  OverlayEntry? _overlay;
  Timer? _lifeTimeTimer;

  void showWarning(String message) => _show(
      message: message,
      type: ToastType.warning,
    );

  void showError(String message) => _show(
      message: message,
      type: ToastType.error,
    );

  void showSuccess(String message, {int lifeTimeInSeconds = 4,}) => _show(
      message: message,
      type: ToastType.success,
      lifeTimeInSeconds: lifeTimeInSeconds,
    );

  void showDefault(
    String message, {
    Color? messageColor,
    Color? backgroundColor,
    Widget? icon,
    TextStyle? style,
    Widget? textWidget,
    bool hideLoading = false,
    bool hideOnTap = true,
    int lifeTimeInSeconds = 4,
  }) => _show(
      message: message,
      type: ToastType.simple,
      messageColor: messageColor,
      backgroundColor: backgroundColor,
      icon: icon,
      style: style,
      textWidget: textWidget,
      hideLoading: hideLoading,
      hideOnTap: hideOnTap,
      lifeTimeInSeconds: lifeTimeInSeconds,
    );

  void _show({
    required ToastType type,
    String? message,
    Color? messageColor,
    Color? backgroundColor,
    Widget? icon,
    TextStyle? style,
    Widget? textWidget,
    bool hideLoading = false,
    bool hideOnTap = true,
    int lifeTimeInSeconds = 4,
  }) {
    if (hideLoading) {
      // LoadingDialog.instance.hide();
    }

    if (_overlay == null) {
      startTimer(seconds: lifeTimeInSeconds);
      _overlay = OverlayEntry(
        builder: (context) => GestureDetector(
          onTap: () => hideOnTap ? hideToastV2() : null,
          child: Material(
            type: MaterialType.transparency,
            child: ToastContentWidget(
              message: message,
              messageColor: messageColor ?? type.color,
              backgroundColor: backgroundColor ?? type.backgroundColor,
              icon: icon ?? type.icon,
              style: style,
              messageWidget: textWidget,
            ),
          ),
        ),
      );
      Overlay.of(navigatorKey.currentState!.context).insert(_overlay!);
    } else {
      // hideToastV2();
      // showToastV2(message,
      //     messageColor: messageColor, backgroundColor: backgroundColor);
    }
  }

  void hideToastV2() {
    _overlay?.remove();
    _overlay = null;
  }

  void startTimer({int seconds = 4}) {
    _lifeTimeTimer?.cancel();
    _lifeTimeTimer = Timer(Duration(seconds: seconds), hideToastV2);
  }
}
