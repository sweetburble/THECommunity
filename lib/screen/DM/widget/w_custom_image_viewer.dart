import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:nav/nav.dart';

/**
 * 채팅방에서 이미지 파일 채팅을 보여주는 위젯
 */
class CustomImageViewerWidget extends StatelessWidget {
  final String imageUrl;

  const CustomImageViewerWidget({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showGeneralDialog( // 이미지를 클릭시, 이미지를 확대/축소 할 수 있는 모달 창을 띄운다
          context: context,
          pageBuilder: (context, _, __) {
            return InteractiveViewer(
              child: GestureDetector(
                onTap: () => Nav.pop(context),
                child: ExtendedImage.network(
                  imageUrl,
                ),
              ),
            );
          },
        );
      },
      child: Container(
        color: Colors.white, // 누끼 딴 이미지 파일은 노란색 채팅 배경색이 그대로 보여서
        child: ExtendedImage.network(
          imageUrl,
          constraints: const BoxConstraints(
            maxHeight: 200, // 이미지의 최대 세로 길이만 설정
          ),
        ),
      ),
    );
  }
}
