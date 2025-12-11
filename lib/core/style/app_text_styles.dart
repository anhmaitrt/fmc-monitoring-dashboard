import 'package:flutter/material.dart';
import 'package:fmc_monitoring_dashboard/core/utils/app_size.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_colors.dart';

class AppTextStyle {
  AppTextStyle._internal();

  static FontWeight get normalWeight => FontWeight.w400;
  static FontWeight get medWeight =>
      FontWeight.lerp(FontWeight.w500, FontWeight.w600, 0.10) ??
          FontWeight.w500; //w510
  static FontWeight get boldWeight => FontWeight.w700;

  static TextStyle get _baseTextStyle => TextStyle(
        // fontFamily: FontFamily.sFPro,
        color: AppColors.textIconPrimary,
        fontStyle: FontStyle.normal,
        fontSize: 16.fontSize,
        fontWeight: normalWeight,
        height: _getLineHeight(fontSize: 16.fontSize, lineHeight: 24),
        letterSpacing: _getLetterSpacing(10),
      );

  ///Default: color - primaryColor, size: 16, weight: w400, lineHeight: 24
  static TextStyle getCustom(
      {TextDecoration? decoration,
      String? fontFamily,
      Color? color,
      FontStyle? fontStyle,
      TextOverflow? overflow,
      double? fontSize,
      FontWeight? fontWeight,
      double lineHeight = 24,
      double? letterSpacing}) {
    final double size = fontSize ?? 16;
    return _baseTextStyle.copyWith(
        decoration: decoration ?? TextDecoration.none,
        // fontFamily: fontFamily ??
        //     (fontWeight == boldWeight ? FontFamily.sFPro : FontFamily.sFPro),
        color: color,
        fontStyle: fontStyle,
        fontSize: size.fontSize,
        fontWeight: fontWeight,
        height: lineHeight.textHeight(size),
        overflow: overflow,
        letterSpacing: _getLetterSpacing(letterSpacing ?? 10));
  }

  //#region HEADER

  static TextStyle get h64Large => _baseTextStyle.copyWith(
        fontSize: 64.fontSize,
        fontWeight: boldWeight,
        height: 76.textHeight(64),
      );

  static TextStyle get h48Large => _baseTextStyle.copyWith(
    fontSize: 48.fontSize,
    fontWeight: boldWeight,
    height: 72.textHeight(48),
  );

  static TextStyle get h32Large => _baseTextStyle.copyWith(
    fontSize: 32.fontSize,
    fontWeight: boldWeight,
    height: 48.textHeight(32).height,
  );

  static TextStyle get h28Large => _baseTextStyle.copyWith(
    fontSize: 28.fontSize,
    fontWeight: boldWeight,
    height: 42.textHeight(28),
  );

  static TextStyle get h24Large => _baseTextStyle.copyWith(
    fontSize: 24.fontSize,
    fontWeight: boldWeight,
    height: 36.textHeight(24),
  );

  static TextStyle get h20Large => _baseTextStyle.copyWith(
    fontSize: 20.fontSize,
    fontWeight: boldWeight,
    height: 30.textHeight(20),
  );

  static TextStyle get h18Medium => _baseTextStyle.copyWith(
    fontSize: 18.fontSize,
    fontWeight: boldWeight,
    height: 27.textHeight(18).height,
  );
  //#endregion

  //#region BODY
  static TextStyle get bo18Large => _baseTextStyle.copyWith(
    fontSize: 18.fontSize,
    height: 27.textHeight(18),
  );

  static TextStyle get bo16Primary => _baseTextStyle.copyWith(
    fontSize: 16.fontSize,
    height: 24.textHeight(16).height,
  );

  static TextStyle get bo16Header => bo16Primary.copyWith(
    fontWeight: boldWeight,
  );
  //#endregion

  //#region CAPTION
  static TextStyle get c14Primary => _baseTextStyle.copyWith(
    fontSize: 14.fontSize,
    height: 21.textHeight(14).height,
  );

  static TextStyle get c14Header => c14Primary.copyWith(
    fontWeight: boldWeight,
  );

  static TextStyle get c12Primary => _baseTextStyle.copyWith(
    fontSize: 12.fontSize,
    height: 18.textHeight(12),
  );

  static TextStyle get c12Header => c12Primary.copyWith(
    fontWeight: boldWeight,
  );

  static TextStyle get c10Primary => _baseTextStyle.copyWith(
    fontSize: 10.fontSize,
    height: 15.textHeight(10),
  );

  static TextStyle get c10Header => c10Primary.copyWith(
    fontWeight: boldWeight,
  );
  //#endregion

  //#region BUTTON
  static TextStyle get bu16Primary => _baseTextStyle.copyWith(
    fontSize: 16.fontSize,
    fontWeight: medWeight,
    height: 24.textHeight(16).height,
  );
  static TextStyle get bu14Secondary => _baseTextStyle.copyWith(
    fontSize: 14.fontSize,
    fontWeight: medWeight,
    height: 21.textHeight(14),
  );
  static TextStyle get bu12Small => _baseTextStyle.copyWith(
    fontSize: 12.fontSize,
    fontWeight: medWeight,
    height: 18.textHeight(12),
  );
  //#endregion

  //#region LINK
  static TextStyle get link16 => _baseTextStyle.copyWith(
    fontSize: 16.fontSize,
    fontWeight: medWeight,
    decoration: TextDecoration.underline,
    height: 24.textHeight(16),
  );

  static TextStyle get link14 => _baseTextStyle.copyWith(
    fontSize: 14.fontSize,
    fontWeight: medWeight,
    decoration: TextDecoration.underline,
    height: 21.textHeight(14),
  );
  //#endregion
}

double _getLetterSpacing(double number) {
  const double spacing = 0.5;
  return (number * spacing) / 100;
}

double _getLineHeight({required double lineHeight, required double fontSize}) {
  return ((lineHeight * 100) / fontSize) / 100;
}

extension VTextStyle on TextStyle {
  TextStyle cp({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    // ui.TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    // List<ui.Shadow>? shadows,
    // List<ui.FontFeature>? fontFeatures,
    // List<ui.FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) =>
      copyWith(
        inherit: inherit,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height:
            height != null ? height.textHeight(fontSize ?? 14) : height,
        leadingDistribution: leadingDistribution,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        fontVariations: fontVariations,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        debugLabel: debugLabel,
        // fontFamily: fontFamily ??
        //     ((fontWeight ?? this.fontWeight) == AppTextStyle.boldWeight
        //         ? FontFamily.sFPro
        //         : FontFamily.sFPro),
        fontFamilyFallback: fontFamilyFallback,
        package: package,
        overflow: overflow,
      );
}

enum TextStyleType {
  @JsonValue('h64Large')
  h64Large,
  @JsonValue('h48Large')
  h48Large,
  @JsonValue('h32Large')
  h32Large,
  @JsonValue('h28Large')
  h28Large,
  @JsonValue('h24Large')
  h24Large,
  @JsonValue('h20Large')
  h20Large,
  @JsonValue('h18Medium')
  h18Medium,

  @JsonValue('bo18Large')
  bo18Large,
  @JsonValue('bo16Primary')
  bo16Primary,
  @JsonValue('bo16Header')
  bo16Header,

  @JsonValue('c14Primary')
  c14Primary,
  @JsonValue('c14Header')
  c14Header,
  @JsonValue('c12Primary')
  c12Primary,
  @JsonValue('c12Header')
  c12Header,
  @JsonValue('c10Primary')
  c10Primary,
  @JsonValue('c10Header')
  c10Header,

  @JsonValue('bu16Primary')
  bu16Primary,
  @JsonValue('bu14Secondary')
  bu14Secondary,
  @JsonValue('bu12Small')
  bu12Small,

  @JsonValue('link16')
  link16,
  @JsonValue('link14')
  link14,

  //#region PREVIOUS VERSION
  //Keep this for mapping with API
  @JsonValue('h0')
  h0,
  @JsonValue('h1')
  h1,
  @JsonValue('h2')
  h2,
  @JsonValue('h3')
  h3,
  @JsonValue('h4')
  h4,

  @JsonValue('bo1')
  bo1,
  @JsonValue('bo2')
  bo2,
  @JsonValue('bo3')
  bo3,
  @JsonValue('bo4')
  bo4,
  @JsonValue('bo5')
  bo5,
  @JsonValue('bo6')
  bo6,

  @JsonValue('c0')
  c0,
  @JsonValue('c1')
  c1,
  @JsonValue('c2')
  c2,
  @JsonValue('c3')
  c3,
  @JsonValue('c4')
  c4,
  @JsonValue('c5')
  c5,
  @JsonValue('c6')
  c6,
  @JsonValue('c7')
  c7,
  @JsonValue('c8')
  c8,
  @JsonValue('c9')
  c9,

  @JsonValue('bu1')
  bu1,
  @JsonValue('bu2')
  bu2,
  @JsonValue('bu3')
  bu3,
  //#endregion
}

extension ETextStyleType on TextStyleType {
  TextStyle get style {
    switch (this) {
      case TextStyleType.h64Large:
        return AppTextStyle.h64Large;
      case TextStyleType.h48Large:
      case TextStyleType.h3:
        return AppTextStyle.h48Large;
      case TextStyleType.h32Large:
      case TextStyleType.h4:
        return AppTextStyle.h32Large;
      case TextStyleType.h28Large:
      case TextStyleType.bo1:
        return AppTextStyle.h28Large;
      case TextStyleType.h24Large:
      case TextStyleType.h0:
      case TextStyleType.h1:
        return AppTextStyle.h24Large;
      case TextStyleType.h20Large:
        return AppTextStyle.h20Large;
      case TextStyleType.h18Medium:
      case TextStyleType.h2:
      case TextStyleType.bo6:
        return AppTextStyle.h18Medium;

      case TextStyleType.bo18Large:
      case TextStyleType.bo2:
        return AppTextStyle.bo18Large;
      case TextStyleType.bo16Primary:
      case TextStyleType.bo4:
      case TextStyleType.bo5:
        return AppTextStyle.bo16Primary;
      case TextStyleType.bo16Header:
      case TextStyleType.bo3:
        return AppTextStyle.bo16Header;

      case TextStyleType.c14Primary:
      case TextStyleType.c1:
      case TextStyleType.c2:
        return AppTextStyle.c14Primary;
      case TextStyleType.c14Header:
      case TextStyleType.c0:
      case TextStyleType.c9:
        return AppTextStyle.c14Header;
      case TextStyleType.c12Primary:
      case TextStyleType.c4:
      case TextStyleType.c5:
        return AppTextStyle.c12Primary;
      case TextStyleType.c12Header:
      case TextStyleType.c3:
        return AppTextStyle.c12Header;
      case TextStyleType.c10Primary:
      case TextStyleType.c7:
      case TextStyleType.c8:
        return AppTextStyle.c10Primary;
      case TextStyleType.c10Header:
      case TextStyleType.c6:
        return AppTextStyle.c10Header;

      case TextStyleType.bu16Primary:
      case TextStyleType.bu3:
        return AppTextStyle.bu16Primary;
      case TextStyleType.bu14Secondary:
      case TextStyleType.bu2:
        return AppTextStyle.bu14Secondary;
      case TextStyleType.bu12Small:
      case TextStyleType.bu1:
        return AppTextStyle.bu12Small;

      case TextStyleType.link16:
        return AppTextStyle.link16;
      case TextStyleType.link14:
        return AppTextStyle.link14;
    }
  }
}