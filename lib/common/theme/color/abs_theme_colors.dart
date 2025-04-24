import 'package:THECommu/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

export 'package:THECommu/common/constant/app_colors.dart';

typedef ColorProvider = Color Function();

/**
 * 테마에 상관없이 바뀌지 않는 색들을 여기에 정의한다.
 * 테마에 맞게 바뀌어야 하는 색들은 그 테마에 맞는 xxx_app_colors 파일에 오버라이드한다
 */
abstract class AbstractThemeColors {
  const AbstractThemeColors();

  Color get seedColor => const Color(0xff26ff8c);

  Color get veryBrightGrey => AppColors.brightGrey;

  Color get drawerBg => const Color.fromARGB(255, 255, 255, 255);

  Color get scrollableItem => const Color.fromARGB(255, 57, 57, 57);

  Color get iconButton => const Color.fromARGB(255, 0, 0, 0);

  Color get iconButtonInactivate => const Color.fromARGB(255, 162, 162, 162);

  Color get inActivate => const Color.fromARGB(255, 200, 207, 220);

  Color get activate => const Color.fromARGB(255, 63, 72, 95);

  Color get badgeBg => AppColors.blueGreen;

  Color get textBadgeText => Colors.white;

  Color get badgeBorder => Colors.transparent;

  Color get divider => const Color.fromARGB(255, 189, 189, 189);

  Color get text => AppColors.darkGrey;

  Color get hintText => AppColors.middleGrey;

  Color get focusedBorder => AppColors.darkGrey;

  Color get confirmText => AppColors.blue;

  Color get drawerText => text;

  Color get snackbarBgColor => AppColors.mediumBlue;

  Color get blueButtonBackground => AppColors.darkBlue;

  Color get checkBoxColor => const Color(0xff108243);

  Color get itemBackground => Colors.white;

  Color get lessImportantColor => const Color.fromARGB(255, 117, 117, 117);

  /// 이 부분은 라이트/다크 모드 따로 설정할 색
  Color get uploadContainer => const Color(0xff393E46);

  Color get blackAndWhite => const Color.fromARGB(255, 0, 0, 0);

  Color get chatCard => const Color.fromARGB(255, 201, 255, 229);

  Color get myChatCard => Colors.yellow;



}
