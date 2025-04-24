import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/theme/color/dark_app_colors.dart';
import 'package:THECommu/common/theme/color/light_app_colors.dart';
import 'package:THECommu/common/theme/shadows/dart_app_shadows.dart';
import 'package:THECommu/common/theme/shadows/light_app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CustomTheme {
  dark(
    DarkAppColors(),
    DarkAppShadows(),
  ),
  light(
    LightAppColors(),
    LightAppShadows(),
  );

  const CustomTheme(this.appColors, this.appShadows);

  final AbstractThemeColors appColors;
  final AbsThemeShadows appShadows;

  ThemeData get themeData {
    switch (this) {
      case CustomTheme.dark:
        return darkTheme;
      case CustomTheme.light:
        return lightTheme;
    }
  }
}

/**
 * CustomGoogleFonts 클래스는 모든 폰트를 asset에서 가져오거나, 웹에서 가져와서 사용하는 것이고
 * GoogleFonts 클래스는 일반적으로 구글이 제공하는 폰트를 사용할 때 사용한다
 */
ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.light,
    textTheme: GoogleFonts.notoSansKrTextTheme( // -> 테마에 맞게 폰트도 바꿀 수 있도록 구현
      ThemeData(brightness: Brightness.light).textTheme,
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: CustomTheme.light.appColors.seedColor));

const darkColorSeed = Color(0xbcd5ff7e);
ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.veryDarkGrey,
    textTheme: GoogleFonts.notoSansKrTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    colorScheme: ColorScheme.fromSeed(
        seedColor: CustomTheme.dark.appColors.seedColor, brightness: Brightness.dark));
