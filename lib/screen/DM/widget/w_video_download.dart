import 'package:THECommu/common/common.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

/**
 * 채팅방에서 동영상 파일을 올리면, 그에 맞는 위젯을 보여주고 다운받을 수도 있게 한다
 */
class VideoDownloadWidget extends StatelessWidget {
  final String downloadUrl;

  const VideoDownloadWidget({
    super.key,
    required this.downloadUrl,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        try {
          FileDownloader.downloadFile(
            url: downloadUrl,
            notificationType: NotificationType.all, // 다운로드가 완료되면 채팅가 출력된다
          );
        } catch (e, stackTrace) {
          logger.e(e);
          logger.e(stackTrace);
          MessageDialog(e.toString());
        }
      },
      child: const Text(
        '🎬',
        style: TextStyle(fontSize: 25),
      ),
    );
  }
}
