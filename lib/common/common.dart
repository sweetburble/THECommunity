import 'package:google_fonts/google_fonts.dart';

export 'dart:async';

export 'package:easy_localization/easy_localization.dart';
export 'package:flutter_svg/flutter_svg.dart';
export 'package:nav/nav.dart';
export 'package:quiver/strings.dart';
export 'package:velocity_x/velocity_x.dart';

export '../common/dart/extension/animation_controller_extension.dart';
export '../common/dart/extension/collection_extension.dart';
export '../common/dart/extension/context_extension.dart';
export '../common/dart/extension/num_extension.dart';
export '../common/dart/extension/velocityx_extension.dart';
export '../common/dart/kotlin_style/kotlin_extension.dart';
export 'constants.dart';
export 'dart/extension/snackbar_context_extension.dart';
export 'theme/color/abs_theme_colors.dart';
export 'theme/shadows/abs_theme_shadows.dart';
export 'util/async/flutter_async.dart';
export 'widget/w_empty_expanded.dart';
export 'widget/w_height_and_width.dart';
export 'widget/w_line.dart';
export 'widget/w_tap.dart';
export 'widget/constant_widget.dart';

/**
 * 내가 추가
 */
export 'util/logger.dart';

/**
 * num_duration_extension 파일은 외부 패키지 flutter_animate의 방식을 차용했으므로,
 * flutter_animate를 사용하려면 삭제해야 한다
 */
// const defaultFontStyle = GoogleFonts.ptSerif;
const defaultFontStyle = GoogleFonts.notoSansKr;

void voidFunction() {}
