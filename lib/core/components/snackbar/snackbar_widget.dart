import 'package:flutter/material.dart';

import '../../style/app_colors.dart';
import '../../style/app_text_styles.dart';
import '../../utils/app_size.dart';

class SnackBarWidget {
  SnackBarWidget._();

  static SnackBarWidget instance = SnackBarWidget._();
  // OverlayEntry? _overlay;

  ScaffoldFeatureController show({
    required BuildContext context,
    String? message,
    SnackBar? snackBar,
    Widget? child,
    Duration? duration,
    TextStyle? textStyle,
    Color? background,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? contentPadding,
    double? radius,
    DismissDirection? dismissDirection
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return ScaffoldMessenger.of(context).showSnackBar(snackBar ?? _buildSnackBar(message, margin, contentPadding, radius, child, duration, textStyle, background, dismissDirection));
  }

  void hide({required BuildContext context}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  SnackBar _buildSnackBar(String? message, EdgeInsetsGeometry? margin, EdgeInsetsGeometry? contentPadding, double? radius, Widget? child, Duration? duration, TextStyle? textStyle, Color? background, DismissDirection? dismissDirection) {
    return SnackBar(
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        margin: margin,
        elevation: 0,
        dismissDirection: dismissDirection ?? DismissDirection.none,
        content: AbsorbPointer(
          child: Center(
            child: Wrap(
              children: [
                Container(
                    alignment: Alignment.center,
                    padding: contentPadding ?? EEdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: ShapeDecoration(
                      color: background ?? AppColors.textIconPrimary,
                      shape: RoundedRectangleBorder(borderRadius: EBorderRadius.circular((radius ?? 8))),
                    ),
                    child: child ?? Text(message ?? '', textAlign: TextAlign.center, style: textStyle ?? AppTextStyle.bo16Primary)
                ),
              ],
            ),
          ),
        )
    );
  }
}