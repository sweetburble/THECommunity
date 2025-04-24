import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/common/widget/heart_animation_widget.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/feed/feed_controller.dart';
import 'package:THECommu/riverpods/feed/feed_state.dart';
import 'package:THECommu/riverpods/like/like_controller.dart';
import 'package:THECommu/riverpods/user/user_controller.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

/**
 * 피드에서 작성자의 프로필 사진, 제목, 작성 날짜, 좋아요 위젯 등등을 구현한 위젯
 */
class FeedDetailTitle extends StatefulHookConsumerWidget {
  final FeedModel feedModel; // 현재 보고 있는 피드

  const FeedDetailTitle({
    super.key,
    required this.feedModel,
  });

  @override
  ConsumerState<FeedDetailTitle> createState() => _FeedDetailTitleState();
}

class _FeedDetailTitleState extends ConsumerState<FeedDetailTitle> {
  bool isAnimating = false; // true면 애니메이션을 실행하고, false면 종료한다

  /**
   * 좋아요 기능
   */
  Future<void> _likeFeed() async {
    if (ref.read(feedControllerProvider).feedStatus == FeedStatus.submitting) {
      return; // 너무 빠른 속도로 좋아요 버튼을 누르는 것을 방지
    }

    try {
      isAnimating = true;
      FeedModel newFeedModel = await ref.read(feedControllerProvider.notifier).likeFeed(
        feedId: widget.feedModel.feedId,
        feedLikes: widget.feedModel.likes,
      );

      // 1) userState -> UserModel -> feedLikeList에 반영
      // 2) userState -> feedList에 반영 (자기가 작성한 게시물에 좋아요 누를수도 있으니까)
      ref.read(userMyControllerProvider.notifier).likeFeed(newFeedModel: newFeedModel);

      // likeState -> likeList 갱신
      ref.read(likeControllerProvider.notifier).likeFeed(likeFeedModel: newFeedModel);

    } on CustomException catch (e) {
      MessageDialog(e.toString());
    }
  }

  /**
   * 상위 위젯인 FeedDetailScreen에서 feedState를 watch하고 있기 때문에
   * _likeFeed()로 feedState가 갱신되면, 이 FeedDetailTitle로 전달되는 feedModel도 갱신된다.
   */
  @override
  Widget build(BuildContext context) {
    String myUID = ref.read(authStateProvider).value!.uid; // 내 유저 아이디

    bool isLike = widget.feedModel.likes.contains(myUID); // 내가 이 피드를 좋아요 했는지

    return Row(
      children: [
        AvatarWidget(userModel: widget.feedModel.writer, isTap: true, radius: 30),
        width5,
        // TODO: 나중에 더 이쁘게 UI 수정
        // Column(
        //   mainAxisAlignment: MainAxisAlignment.center,
        //   children: [
        //     widget.feedModel.writer.nickname.text.bold.size(20).makeWithDefaultFont(),
        //   ],
        // ),
        // widget.feedModel.writer.nickname.text.bold.size(20).makeWithDefaultFont(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.feedModel.title.text.size(20).bold.makeWithDefaultFont(),
              height10,
              Row(
                children: [
                  widget.feedModel.writer.nickname.text.makeWithDefaultFont(),
                  ' | '
                      .text
                      .color(context.appColors.lessImportantColor)
                      .makeWithDefaultFont(),
                  timeago
                      .format(widget.feedModel.createAt.toDate(),
                      locale: context.locale.languageCode) // Timestamp -> Datetime
                      .text
                      .color(context.appColors.lessImportantColor)
                      .makeWithDefaultFont(),
                ],
              )
            ],
          ),
        ),
        Stack(
          children: [
            GestureDetector(
              onTap: () async {
                await _likeFeed();
              },
              child: HeartAnimationWidget(
                isAnimating: isAnimating,
                child: isLike
                    ? Icon(
                  Icons.favorite,
                  color: Colors.red,
                )
                    : Icon(
                  Icons.favorite_border,
                  color: context.appColors.lessImportantColor,
                ),
                onEnd: () => setState(() {
                  isAnimating = false;
                }),
              ),
            ),
          ],
        )
      ],
    ).pSymmetric(h: 10, v: 15);
  }
}
