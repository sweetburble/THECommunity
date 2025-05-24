import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/comment/comment_controller.dart';
import 'package:THECommu/riverpods/comment/comment_state.dart';
import 'package:THECommu/riverpods/feed/feed_controller.dart';
import 'package:THECommu/riverpods/feed/feed_state.dart';
import 'package:THECommu/riverpods/like/like_controller.dart';
import 'package:THECommu/riverpods/user/user_controller.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:THECommu/screen/main/tab/commu/detail/comment_screen.dart';
import 'package:THECommu/screen/main/tab/commu/detail/w_feed_detail_title.dart';
import 'package:THECommu/screen/main/tab/commu/detail/w_post_detail_content.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'w_feed_ai_summary.dart';

/**
 * 피드 상세 화면 구현
 */
class FeedDetailScreen extends StatefulHookConsumerWidget {
  final FeedModel oldFeedModel; // 피드를 삭제하고 null 에러가 발생하는 것을 막기 위해

  const FeedDetailScreen({
    super.key,
    required this.oldFeedModel,
  });

  @override
  ConsumerState<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends ConsumerState<FeedDetailScreen> {
  static const bottomMenuHeight = 100.0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // 댓글 입력 폼을 검증(validate)하는 키
  final TextEditingController _textEditingController = TextEditingController(); // TextFormField에서 입력한 텍스트를 관리하는 컨트롤러
  late final String feedId; // 이 피드의 고유 ID

  @override
  void initState() {
    super.initState();
    feedId = widget.oldFeedModel.feedId;
    _getCommentList();
  }

  /**
   * 피드에 달린 댓글 목록을 가져오는 함수 (먼저 UI가 그려지고 나서, 실행된다)
   */
  void _getCommentList() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        ref.read(commentControllerProvider.notifier).getCommentList(feedId: feedId);
      } on CustomException catch (e) {
        MessageDialog(e.toString());
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController(); // _ImagePager가 사용
    
    FeedState feedState = ref.watch(feedControllerProvider); // FeedDetailTitle에서 좋아요 로직을 실행하면 감지 후, 갱신
    FeedModel feedModel = feedState.getFeed(feedId: feedId) ?? widget.oldFeedModel; // 상위 위젯에서 주입받지 않고, feedState가 갱신될 때마다 가져온다

    UserModel myUserModel = ref.read(userMyControllerProvider).userModel; // "나"의 UserModel

    CommentState commentState = ref.watch(commentControllerProvider);

    // 댓글 등록 중(잠시 동안)일 경우, 내용 입력 & 등록 버튼 비활성화
    bool isEnabled = commentState.commentStatus != CommentStatus.submitting;

    return PopScope(
      child: GestureDetector(
        // 댓글 작성 중 다른 곳을 클릭하면 키보드가 내려간다
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: bottomMenuHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AppBar(feedModel: feedModel),
                      _ImagePager(pageController: pageController, feedModel: feedModel),
                      height10,
                      Line(color: context.appColors.uploadContainer),

                      FeedDetailTitle(feedModel: feedModel),
                      Line(color: context.appColors.uploadContainer),

                      FeedAISummary(feedModel: feedModel),
                      Line(color: context.appColors.uploadContainer),

                      FeedDetailContent(feedModel: feedModel),
                      Line(color: context.appColors.uploadContainer),

                      CommentScreen(commentList: commentState.commentList),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: commentBottomBar(context, myUserModel, isEnabled),
        ),
      ),
    );
  }

  Widget commentBottomBar(BuildContext context, UserModel myUserModel, bool isEnabled) {
    return Container(
      // 댓글 입력 폼이 키보드에 가려지지 않도록 마진으로 보호한다 -> (context).viewInsets.bottom은 키보드가 차지하는 높이를 반환한다
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      color: Colors.black54,
      child: Form(
        key: _formKey,
        child: Row(
          children: [
            AvatarWidget(userModel: myUserModel, isTap: false),
            // Row 위젯안에 TextFormField를 넣을때는 크기를 지정해야 한다. -> Expanded로 최대한 크기 지정
            Expanded(
              child: TextFormField(
                controller: _textEditingController,
                enabled: isEnabled,
                decoration: InputDecoration(
                  hintText: "댓글을 입력하세요",
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '댓글을 입력하세요';
                  }
                  return null; // null을 반환했다는 것은 정상적인 입력이라는 것이다
                },
              ).pOnly(left: 16, right: 8),
            ),
            IconButton(
              onPressed: isEnabled
                  ? () async {
                      FocusScope.of(context).unfocus();

                      FormState? form = _formKey.currentState;

                      if (form == null || !form.validate()) {
                        return;
                      }

                      try {
                        // 댓글 등록 로직
                        await ref.read(commentControllerProvider.notifier).uploadComment(
                              feedId: feedId,
                              comment: _textEditingController.text,
                            );

                        // feedState -> feedList -> 이 feedModel의 commentCount도 1씩 증가
                        await ref.read(feedControllerProvider.notifier).uploadComment(feedId: feedId);

                        _textEditingController.clear();
                      } on CustomException catch (e) {
                        MessageDialog(e.toString());
                      }
                    }
                  : null,
              icon: Icon(BoxIcons.bx_arrow_from_bottom, color: context.appColors.blackAndWhite),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePager extends StatelessWidget {
  const _ImagePager({
    required this.pageController,
    required this.feedModel,
  });

  final PageController pageController;
  final FeedModel feedModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.deviceWidth,
      width: context.deviceWidth,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            PageView(
              controller: pageController,
              children: feedModel.imageUrls
                  .map((url) => Hero(
                        tag: '${feedModel.feedId}_$url',
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.fill,
                        ),
                      ))
                  .toList(),
            ),
            if (feedModel.imageUrls.length > 1)
              Align(
                alignment: Alignment.bottomCenter,
                child: SmoothPageIndicator(
                    controller: pageController, // PageController
                    count: feedModel.imageUrls.length,
                    effect: const JumpingDotEffect(
                      verticalOffset: 10,
                      dotColor: Colors.white54,
                      activeDotColor: Colors.black45,
                    ), // your preferred effect
                    onDotClicked: (index) {}),
              )
          ],
        ),
      ),
    ).p(10);
  }
}

class _AppBar extends ConsumerWidget {
  final FeedModel feedModel;

  const _AppBar({
    required this.feedModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String myUID = ref.read(authStateProvider).value!.uid;

    return SizedBox(
      height: 60 + context.statusBarHeight,
      child: AppBar(
        backgroundColor: context.appColors.badgeBg,
        leading: IconButton(
          onPressed: () {
            Nav.pop(context);
          },
          icon: const Icon(Icons.arrow_back_sharp, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share, color: Colors.white),
          ),
          IconButton(
              onPressed: () {
                if (myUID == feedModel.uid) {
                  // 내가 작성한 피드에만 삭제 버튼 표시
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: TextButton(
                          child: '삭제'.text.color(Colors.red).makeWithDefaultFont(),
                          onPressed: () async {
                            try {
                              // 피드 삭제 로직
                              await ref.read(feedControllerProvider.notifier)
                                  .deleteFeed(feedModel: feedModel);

                              // likeState에도 반영
                              ref.read(likeControllerProvider.notifier).deleteFeed(feedId: feedModel.feedId);

                              // userState -> feedList(내가 작성한 피드 리스트)에도 반영
                              ref.read(userMyControllerProvider.notifier).deleteFeed(feedId: feedModel.feedId);

                              if (context.mounted) {
                                Nav.pop(context); // 다이얼로그 종료 후
                                Nav.pop(context); // 커뮤니티 프래그먼트로 이동 (임시방편)
                              }
                            } on CustomException catch (e) {
                              MessageDialog(e.toString());
                            }
                          },
                        ),
                      );
                    });
                }
              },
              icon: const Icon(Icons.more_vert, color: Colors.white)),
        ],
        title: feedModel.title.text.white.textStyle(defaultFontStyle())
            .size(24).makeCentered(),
      ),
    );
  }
}
