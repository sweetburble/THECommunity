import 'package:THECommu/data/simple_result.dart';
import 'package:flutter/material.dart';
import 'package:nav/bottom_sheet/modal_bottom_sheet.dart';

import '../../common/common.dart';

/**
 * d_color_bottom을 베이스로 한 "오늘의 토론 주제" 바텀 시트
 */
class TopicBottomSheet extends ModalBottomSheet<SimpleResult> {
  final String message;
  final Color textColor;
  final double fontSize;

  TopicBottomSheet(
    this.message, {
    this.fontSize = 30.0,
    Color? textColor,
    super.context,
    super.key,
    super.backgroundColor = Colors.purple,
    super.handleColor = Colors.red,
    super.barrierColor = const Color(0x80000000),
  }) : textColor = textColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: () => hide(SimpleResult()),
      child: SizedBox(
        height: 230,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            height20,
            "오늘의 토론 주제".text.italic.color(textColor).makeWithDefaultFont(),
            Height(30),
            message.text.bold
                .color(textColor)
                .size(fontSize)
                .makeWithDefaultFont(),
          ],
        ).pSymmetric(h: 40),
      ),
    );
  }
}
