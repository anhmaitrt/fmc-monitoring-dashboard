import 'package:flutter/material.dart';

import '../components/button/button_size_type.dart';

///
/// This class is for all app widget's style and must follow the UI design system
///
class AppWidgetStyles {
  AppWidgetStyles._();

  //#region BUTTONS
  static double buttonRadius = 40;

  //NOTE: Create other button type if needed (TextButton, IconButton,...)

  static ButtonStyle getButtonStyle({
    ButtonSizeType sizeType = ButtonSizeType.medium,
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? disableColor,
    double elevation = 0,
    // double? radius,
    // BorderSide borderSide = BorderSide.none,
    Size? minimumSize,
    EdgeInsetsGeometry? padding,
    bool enable = true,
  }) {
    return ElevatedButton.styleFrom(
      // textStyle: textStyle ?? sizeType.textStyle,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Colors.transparent,
      disabledBackgroundColor: disableColor ?? Colors.transparent,
      shadowColor: Colors.transparent,
      // shape: RoundedRectangleBorder(
      //   borderRadius: EBorderRadius.all(radius ?? buttonRadius),
      //   side: borderSide,
      // ),
      minimumSize: minimumSize ?? Size.zero,
      padding: padding ?? EdgeInsets.zero,
    );
  }
  //#endregion
}