// part of '../base_button_widget.dart';

import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/utils/app_size.dart';

import '../../style/app_text_styles.dart';

enum ButtonSizeType {
  large,
  medium,
  normal,
  small,
}

extension EButtonSizeType on ButtonSizeType {
  double get height {
    var height = 0;
    switch(this) {
      case ButtonSizeType.large:
        height = 48;
        break;
      case ButtonSizeType.medium:
        height = 40;
        break;
      case ButtonSizeType.normal:
        height = 32;
        break;
      case ButtonSizeType.small:
        height = 24;
        break;
    }

    return height.height;
  }

  TextStyle get textStyle {
    var style = const TextStyle();

    switch(this) {
      case ButtonSizeType.large:
      case ButtonSizeType.medium:
      case ButtonSizeType.normal:
      case ButtonSizeType.small:
        style = AppTextStyle.bu16Primary;
        break;
    }

    style = style.copyWith(height: 0);
    return style;
  }

  EdgeInsets get padding {
    switch(this) {
      case ButtonSizeType.large:
        return EEdgeInsets.symmetric(
          // vertical: 12,
          horizontal: 24,
        );
      case ButtonSizeType.medium:
        return EEdgeInsets.symmetric(
          // vertical: 8,
          horizontal: 16,
        );
      case ButtonSizeType.normal:
        return EEdgeInsets.symmetric(
          // vertical: 4,
          horizontal: 12,
        );
      case ButtonSizeType.small:
        return EEdgeInsets.symmetric(
          horizontal: 8,
        );
    }
  }

  ///For leading and trailing widget
  double get addOnWidgetSize {
    var size = 0;
    switch(this) {
      case ButtonSizeType.large:
        size = 32;
        break;
      case ButtonSizeType.medium:
        size = 24;
        break;
      case ButtonSizeType.normal:
        size = 20;
        break;
      case ButtonSizeType.small:
        size = 16;
        break;
    }

    return size.height;
  }
}