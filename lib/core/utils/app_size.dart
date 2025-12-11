import 'package:flutter/material.dart';

class AppSize {
  AppSize._();

  factory AppSize.init(BuildContext context, {Size? size}) {
    deviceSize = MediaQuery.of(context).size;
    AppSize.sizeDefault = size ?? const Size(375, 812);
    return AppSize._();
  }

  static AppSize instance = AppSize._();

  static late Size deviceSize;
  static late Size sizeDefault;

  static final view = WidgetsBinding.instance.platformDispatcher.implicitView;
  static final Size pS = view?.physicalSize ?? sizeDefault;
  static final dR = view?.devicePixelRatio ?? 1;
  static final Size _size = pS / dR;
  static Size get size => _size;

  static double get defaultRadiusValue => 40;
  static BorderRadius get defaultRadius => EBorderRadius.circular(defaultRadiusValue);
  static double get componentRadiusValue => 12;
  static BorderRadius get componentRadius => EBorderRadius.circular(componentRadiusValue);

  //#region MARGIN/PADDING
  /// |-> [widget] <-|
  static double get edgeHorizontalMarginValue => 12;
  static Widget get edgeHorizontalMarginSpace => edgeHorizontalMarginValue.hSpace;
  static EdgeInsets get edgeHorizontalMargin => EEdgeInsets.symmetric(horizontal: edgeHorizontalMarginValue);

  /// [widget] -> [widget]
  static double get horizontalMarginValue => 16;
  static Widget get horizontalMarginSpace => horizontalMarginValue.hSpace;
  static EdgeInsets get horizontalMargin => EEdgeInsets.symmetric(horizontal: horizontalMarginValue);

  /// ____________
  ///   [widget]
  ///      ↓
  ///   [widget]
  /// ____________
  static double get verticalMarginValue => 24;
  static Widget get verticalMarginSpace => verticalMarginValue.vSpace;
  static EdgeInsets get verticalMargin => EEdgeInsets.symmetric(vertical: verticalMarginValue);

  /// ____________
  ///      ↓
  ///  [content]
  ///      ↑
  /// ____________
  static double get verticalPaddingValue => 16;
  static Widget get verticalPaddingSpace => verticalPaddingValue.vSpace;
  static EdgeInsets get verticalPadding =>
      EEdgeInsets.symmetric(vertical: verticalPaddingValue);

  /// |-> [content] <-|
  static double get horizontalPaddingValue => 16;
  static Widget get horizontalPaddingSpace => horizontalPaddingValue.hSpace;
  static EdgeInsets get horizontalPadding =>
      EEdgeInsets.symmetric(horizontal: horizontalPaddingValue);

  ///Apply all vertical and horizontal padding for screen content
  static get screenContentPadding => EEdgeInsets.symmetric(
        vertical: verticalPaddingValue,
        horizontal: horizontalPaddingValue,
      );
  //#endregion

  static double _getShortestSide(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide;

  static bool isSpecialDevice(BuildContext context) =>
      _getShortestSide(context) <= 375;

  static bool isSmallDevice(BuildContext context) =>
      _getShortestSide(context) < 400;

  static bool isNormalDevice(BuildContext context) =>
      _getShortestSide(context) > 380 && _getShortestSide(context) < 400;

  static bool isMediumDevice(BuildContext context) =>
      _getShortestSide(context) > 400 && _getShortestSide(context) < 600;

  static bool isIpad(BuildContext context) => _getShortestSide(context) > 600;

  static bool isBigIpad(BuildContext context) =>
      _getShortestSide(context) > 900;
}

extension ENumAppSize on num {
  double get width => _sf;
  double get height => _sf;
  double get radius => _sf;

  ///0.2.widthPercentage => 0.2 times the screen width
  double get widthPercentage => AppSize.deviceSize.width * this;
  ///0.2.heightPercentage => 0.2 times the screen height
  double get heightPercentage => AppSize.deviceSize.height * this;

  Widget get vSpace => SizedBox(height: _sf);
  Widget get hSpace => SizedBox(width: _sf);

  double get fontSize => _sf;
  double textHeight(num fontSize) => this / (fontSize.fontSize);

  double get _sf => AppSize.size.f(AppSize.sizeDefault) * this;
}

/// without size default [sizeDefault]
extension ENumAppSizeWithoutSizeDefault on Size {
  double h(Size size) => height / size.height;

  double w(Size size) => width / size.width;

  double f(Size size) =>
      width < height ? width / size.width : height / size.height;
}

extension EEdgeInsets on EdgeInsets {
  EdgeInsets get _width => copyWith(
    top: top.width,
    bottom: bottom.width,
    right: right.width,
    left: left.width,
  );

  EdgeInsets get radius => copyWith(
    top: top.radius,
    bottom: bottom.radius,
    right: right.radius,
    left: left.radius,
  );

  /// If use with [copyWith], do like this:
  ///
  /// EEdgeInsets.all(10).copyWith(top: 15.width)
  static EdgeInsets all(double value) => EdgeInsets.all(value)._width;

  /// If use with [copyWith], do like this:
  ///
  /// EEdgeInsets.symmetric(vertical: 10, horizontal: 15).copyWith(top: 15.width)
  static EdgeInsets symmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  }) => EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal)._width;

  /// If use with [copyWith], do like this:
  ///
  /// EEdgeInsets.only(top: 10).copyWith(bottom: 15.width)
  static EdgeInsets only({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) => EdgeInsets.only(left: left, top: top, right: right, bottom: bottom).radius;
}

extension ERadius on Radius {
  Radius get width => Radius.elliptical(x.width, y.width);

  static Radius circular(double value) => Radius.circular(value).width;
}

extension EBorderRadius on BorderRadius {
  BorderRadius get width => copyWith(
    bottomLeft: bottomLeft.width,
    bottomRight: bottomRight.width,
    topLeft: topLeft.width,
    topRight: topRight.width,
  );

  /// If use with [copyWith], do like this:
  ///
  /// BorderRadius.all(top: 10).copyWith(topLeft: Radius.circular(15).width)
  static BorderRadius all(double value) => BorderRadius.all(Radius.circular(value)).width;

  static BorderRadius circular(double value) => BorderRadius.circular(value).width;

  static BorderRadius only({
    double? topLeft,
    double? topRight,
    double? bottomLeft,
    double? bottomRight,
  }) => BorderRadius.only(
    topLeft: topLeft != null ? ERadius.circular(topLeft) : Radius.zero,
    topRight: topRight != null ? ERadius.circular(topRight) : Radius.zero,
    bottomLeft: bottomLeft != null ? ERadius.circular(bottomLeft) : Radius.zero,
    bottomRight: bottomRight != null ? ERadius.circular(bottomRight) : Radius.zero,
  ).width;

  static BorderRadius vertical({
    double? top,
    double? bottom,
  }) => BorderRadius.vertical(
    top: top != null ? ERadius.circular(top) : Radius.zero,
    bottom: bottom != null ? ERadius.circular(bottom) : Radius.zero,
  ).width;
}