import 'dart:io';

import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/riverpods/feed/feed_controller.dart';
import 'package:THECommu/riverpods/feed/feed_state.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/**
 * InkWell은 애니메이션 효과가 있지만, 제스처를 몇개 밖에 처리하지 못한다
 * GestureDetector는 애니메이션 효과는 없고 (직접 구현), 처리할 수 있는 제스처는 많다!
 */
class FeedUploadFragment extends StatefulHookConsumerWidget {
  // 피드을 업로드하고 나면, 커뮤니티 프래그먼트으로 이동하기 위해 mainScreen의 tabController의 index를 변경한다
  final VoidCallback onFeedUploaded;

  const FeedUploadFragment({
    super.key,
    required this.onFeedUploaded,
  });

  @override
  ConsumerState<FeedUploadFragment> createState() => _FeedUploadFragmentState();
}

class _FeedUploadFragmentState extends ConsumerState<FeedUploadFragment> {
  final TextEditingController _titleEditingController = TextEditingController(); // 피드 제목을 다룰 컨트롤러
  final TextEditingController _contentEditingController = TextEditingController(); // 피드 내용을 다룰 컨트롤러
  final List<String> _files = []; // 선택한 이미지 파일들의 문자열 경로를 담을 리스트

  /**
   * 갤러리에서 이미지 선택
   */
  Future<List<String>> selectImages() async {
    // XFile이란 이미지나 미디어 파일에 접근할 수 있는 "경로"를 가지고 있는 것
    List<XFile> images = await ImagePicker().pickMultiImage(
      // 여러개의 이미지 선택 가능
      maxWidth: 1024,
      maxHeight: 1024,
    );
    return images.map((item) => item.path)
        .toList(); // XFile -> String으로 convert
  }

  /**
   * 선택된 이미지들을 보여주는 위젯
   */
  List<Widget> selectedImageList() {
    final feedStatus = ref.watch(feedControllerProvider).feedStatus;
    return _files.map((data) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(data),
              fit: BoxFit.cover,
              height: MediaQuery.of(context).size.height * 0.3,
              width: 250,
            ),
          ),

          // 이미지 삭제 버튼 추가
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: feedStatus == FeedStatus.submitting
                  ? null
                  : () {
                      setState(() {
                        _files.remove(data);
                      });
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(60),
                ),
                width: 30,
                height: 30,
                child: Icon(
                  color: Colors.black.withValues(alpha: 0.6),
                  size: 30,
                  Icons.highlight_remove_outlined,
                ),
              ),
            ),
          ),
        ],
      ).pOnly(left: 20);
    }).toList(); // 이미지 위젯(을 감싼 ClipRRect)을 갖는 리스트를 반환한다
  }

  /**
   * 피드를 업로드하면 작동하는 로직
   */
  Future<void> _handleUploadFeed() async {
    try {
      FocusScope.of(context).unfocus();

      await ref.read(feedControllerProvider.notifier).uploadFeed(
            files: _files,
            title: _titleEditingController.text,
            content: _contentEditingController.text,
          );

      if (mounted) {
        context.showSnackbar(context.tr("uploadFeedNotification"), isFloating: true);
      }

      widget.onFeedUploaded(); // widget을 사용하는 이유는 클래스가 다르니까!
    } on CustomException catch (e) {
      MessageDialog(e.toString());
    }
  }

  @override
  void dispose() {
    _contentEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedStatus = ref.watch(feedControllerProvider).feedStatus;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 기본적으로 탑재되는 뒤로가기 버튼 삭제
        actions: [
          // TODO: 피드 업로드 버튼 결정
          // 1. 이미지가 있어야 활성화되고, 2. 이미 클릭했으면 비활성화되어야 한다
          OutlinedButton(
            onPressed: (_files.isEmpty || feedStatus == FeedStatus.submitting)
                ? () {}
                : () {
                    // 비동기 작업을 따로 분리하여 실행
                    _handleUploadFeed();
                  },
            child: context.tr("upload").text.bold.makeWithDefaultFont(),
          ),
          // RoundButton(
          //   onTap: (_files.isEmpty || feedStatus == FeedStatus.submitting)
          //       ? () {}
          //       : () {
          //     // 비동기 작업을 따로 분리하여 실행
          //     _handleUploadFeed();
          //   },
          //   text: "등록",
          //   theme: RoundButtonTheme.whiteWithBlueBorder,
          // ),
          Width(10),
        ],
      ),
      body: GestureDetector(
        // unfocus()는 입력 키보드를 내리는 역할을 한다
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Height(5),
                LinearProgressIndicator(
                  // 피드를 업로드할 때, 로딩바 추가
                  backgroundColor: Colors.transparent,
                  value: feedStatus == FeedStatus.submitting ? null : 1,
                  // null이면 움직임, 1이면 움직이지 않음
                  color: feedStatus == FeedStatus.submitting
                      ? Colors.red
                      : Colors.transparent,
                ),
                Height(5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      InkWell(
                        // onTap 속성에 null값을 전달하면, 클릭이 비활성화된다
                        onTap: feedStatus == FeedStatus.submitting
                            ? null
                            : () async {
                                final images = await selectImages();
                                setState(() {
                                  _files.addAll(images);
                                });
                              },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.appColors.uploadContainer
                                .withValues(alpha: 0.2), // 투명도 조절
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.upload),
                        ),
                      ),
                      ...selectedImageList(),
                    ],
                  ),
                ),
                Height(10),
                Line(height: 2, color: context.appColors.blackAndWhite),

                if (_files.isNotEmpty)
                  Column(
                    children: [
                      /// 피드 제목
                      TextFormField(
                        controller: _titleEditingController,
                        decoration: InputDecoration(
                          hintText: context.tr("title"),
                          // border: InputBorder.none,
                          // border: OutlineInputBorder(),
                        ),
                        maxLines: 1, // 몇줄을 써도 상관은 없지만, 표시만 1줄씩 해주는 것
                      ),
                      Height(10),

                      /// 피드 내용
                      TextFormField(
                        controller: _contentEditingController,
                        decoration: InputDecoration(
                          hintText: context.tr("content"),
                          border: InputBorder.none,
                        ),
                        maxLines: 15, // 몇줄을 써도 상관은 없지만, 표시만 15줄씩 해주는 것
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
