import 'package:flutter/material.dart';

class AppColors {
  AppColors._internal();

  //#region PRIMARY
  static const Color primary = primary60;
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF5596F7),
      primary,
    ],
  );

  static const Color primary10 = Color(0xFFF0F3FE);
  static const Color primary20 = Color(0xFFDDE4FC);
  static const Color primary30 = Color(0xFFC2D0FB);
  static const Color primary40 = Color(0xFF98B2F8);
  static const Color primary50 = Color(0xFF678BF3);
  static const Color primary60 = Color(0xFF4564ED);
  static const Color primary70 = Color(0xFF2F44E1);
  static const Color primary80 = Color(0xFF2631CF);
  static const Color primary90 = Color(0xFF252AA8);
  static const Color primary100 = Color(0xFF232A85);
  //#endregion

  //#region SECONDARY
  static const Color secondary = secondary60;
  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFF8F4B),
      Color(0xFFFF5C00),
    ],
  );

  static const Color secondary10 = Color(0xFFFFF7EC);
  static const Color secondary20 = Color(0xFFFFEDD3);
  static const Color secondary30 = Color(0xFFFFD8A5);
  static const Color secondary40 = Color(0xFFFFBB6D);
  static const Color secondary50 = Color(0xFFFF9232);
  static const Color secondary60 = Color(0xFFFF730A);
  static const Color secondary70 = Color(0xFFFF5900);
  static const Color secondary80 = Color(0xFFCC3E02);
  static const Color secondary90 = Color(0xFF822B0C);
  static const Color secondary100 = Color(0xFF461204);
  //#endregion

  //#region SIEMATIC
  //GREEN
  static const Color success = green60;
  static const Color successBackground = Color(0xFFDCF5E6);
  static const Color green10 = Color(0xFFF1FDF6);
  static const Color green20 = Color(0xFFC9F8DC);
  static const Color green30 = Color(0xFF89F0B2);
  static const Color green40 = Color(0xFF53E98F);
  static const Color green50 = Color(0xFF1CDE69);
  static const Color green60 = Color(0xFF17BA58);
  static const Color green70 = Color(0xFF14A34D);
  static const Color green80 = Color(0xFF118840);
  static const Color green90 = Color(0xFF0C642F);
  static const Color green100 = Color(0xFF08401E);

  //RED
  static const Color error = red60;
  static const Color errorBackground = red10;
  static const Color red10 = Color(0xFFFFF3F6);
  static const Color red20 = Color(0xFFFBD0D5);
  static const Color red30 = Color(0xFFF7AAB2);
  static const Color red40 = Color(0xFFFB8D9B);
  static const Color red50 = Color(0xFFFF5A75);
  static const Color red60 = Color(0xFFFF2156);
  static const Color red70 = Color(0xFFB60630);
  static const Color red80 = Color(0xFF990529);
  static const Color red90 = Color(0xFF66041B);
  static const Color red100 = Color(0xFF33020E);
  //#endregion

  //#region NEUTRAL
  static const Color neutral10 = Color(0xFFF5F5F5);
  static const Color neutral20 = Color(0xFFE7E7E7);
  static const Color neutral30 = Color(0xFFD1D1D1);
  static const Color neutral40 = Color(0xFFB0B0B0);
  static const Color neutral50 = Color(0xFF949494);
  static const Color neutral60 = Color(0xFF888888);
  static const Color neutral70 = Color(0xFF616161);
  static const Color neutral80 = Color(0xFF3D3D3D);
  static const Color neutral90 = Color(0xFF252525);
  static const Color neutral100 = Color(0xFF121212);

  //Icon/Text
  static const Color textIconDisable = neutral30;
  static const Color textIconLight = neutral60;
  static const Color textIconPrimary = neutral80;
  static const Color textIconDark = Color(0xFF252525);

  //Border/Stroke
  static const Color strokeLight = Color(0xFFE7E7E7);
  static const Color strokePrimary = Color(0xFFD1D1D1);
  static const Color strokeDark = Color(0xFF3D3D3D);

  //Background
  static const Color backgroundLight = Color(0xFFFBFDFF);
  static const Gradient backgroundBlue = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFF2F8FF),
      Color(0XFFEDF5FF),
    ],
  );
  static const Color backgroundPrimary = Color(0xFFEDF2F5);
  static const Color backgroundDisable = Color(0xFFF8F8F8);
  //#endregion

  //#region OTHERS
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFFD0E8FE);
  //#endregion

  //#region GLUCOSE
  //Glucose
  static const Color bloodGlucoseVeryHigh = Color(0xFFFF831C);
  static const Color bloodGlucoseHigh = Color(0xFFFFB029);
  static const Color bloodGlucoseNormal = Color(0xFF22A464);
  static const Color bloodGlucoseLow = Color(0xFFFF6271);
  static const Color bloodGlucoseVeryLow = Color(0xFFE0413B);
  static const Color bloodGlucosePoint = Color(0xFF3FADC6);

  //Background
  static const Color bloodGlucoseVeryHighBg = Color(0xFFFFEDDD);
  static const Color bloodGlucoseHighBg = Color(0xFFFFF3DF);
  static const Color bloodGlucoseNormalBg = Color(0xFFDEF2E8);
  static const Color bloodGlucoseLowBg = Color(0xFFFFE8EA);
  static const Color bloodGlucoseVeryLowBg = Color(0xFFFBE3E2);

  //Daily Trending
  static const Color bloodGlucoseDay1 = Color(0xFF202020);
  static const Color bloodGlucoseDay2 = Color(0xFF1890FF);
  static const Color bloodGlucoseDay3 = Color(0xFFBF6DFF);
  static const Color bloodGlucoseDay4 = Color(0xFF09D5E2);

  // ??? old design system
  static const Color background = Color(0xFFF0F2F4);
  static const Color bloodGlucoseIncreasingRapidly = Color(0xFFFF831C);
  static const Color bloodGlucoseLow15 = Color(0x26FF6271);
  //#endregion

  //TODO: optimize this
  static const Color seperatorLine = Color(0xFFE5EAEC);
  static const Color divider = Color(0xFFDDDDDD);
  static const Color inactiveOtp = Color(0xFFE5EAEC);
  static const Color placeholder = Color(0xFF607D8B);
  static const Color placeholderPinCode = Color(0xFFE5EAEC);
  static const Color dotIndicator = Color(0xFFE0E0E0);
  static const Color emptyDataText = Color(0xFF607D8B);
  static const Color profileBox = Color(0xffF0F2F4);

  static const Color disableButtonBorder = strokeLight;
  static const Color disableText = textIconLight;
  static const Color biometricButton = backgroundPrimary;
  static const Color settingIcon = textIconPrimary;
  static const Color notiBadgeBackground = secondary10;
  static const Color notiBadgeText = red60;

  static const Color appBarDefault = white;

  static const Color eventLogDiabetes = Color(0xFF22A464);
  static const Color eventLogDining = Color(0xFF3FADC6);
  static const Color eventLogMovement = Color(0xFFF0F3FE);
  static const Color eventLogMedicine = Color(0xFFBF6DFF);
  static const Color eventLogWeight = Color(0xFFFFF7EC);
  static Color white20 = const Color(0xFFFFFFFF).withOpacity(0.2);
}
