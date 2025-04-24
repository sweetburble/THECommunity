import 'package:THECommu/common/common.dart';
import 'package:flutter/material.dart';

/**
 * 메신저앱 만들기에서 만든 커스텀 버튼 위젯
 */
class CustomButtonWidget extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;

  const CustomButtonWidget({
    super.key,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDarkMode) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: buttonText.text.bold.black.make(), // 일단은 다크모드여도 텍스트를 검은색으로 함
      );
    }
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
      child: buttonText.text.bold.make(),
    );
  }
}
