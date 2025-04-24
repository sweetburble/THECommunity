import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/dart/extension/color_extension.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/auth/auth_controller.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/user/user_controller.dart';
import 'package:THECommu/riverpods/user/user_state.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:THECommu/screen/main/tab/commu/detail/s_feed_detail.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * 프로필을 표시하고 싶은 유저의 아이디를 생성자로 받아서, 그 유저의 프로필을 출력한다
 */
class ProfileFragment extends StatefulHookConsumerWidget {
  final String uid;

  const ProfileFragment({
    super.key,
    required this.uid,
  });

  @override
  ConsumerState<ProfileFragment> createState() => _ProfileFragmentState();
}

class _ProfileFragmentState extends ConsumerState<ProfileFragment> {
  late final String myUid; // 나의 고유 UID
  final ScrollController _scrollController = ScrollController();
  late final UserController userController;


  @override
  void initState() {
    super.initState();
    myUid = ref.read(authStateProvider).value!.uid;

    // 내 프로필을 보는지 / 다른 유저의 프로필을 보는지에 따라 변경
    userController = (widget.uid == myUid) ? ref.read(userMyControllerProvider.notifier) : ref.read(userControllerProvider.notifier);

    _scrollController.addListener(scrollListener);
    _getProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  /**
   * ListView를 스크롤할 때마다, 호출될 함수
   * _scrollController.offset; // 현재 스크롤 위치
   * _scrollController.position.maxScrollExtent; // 가능한 최대 스크롤 위치
   */
  void scrollListener() {
    // 내 프로필을 보는지 / 다른 유저의 프로필을 보는지에 따라 가져오는 userState가 다름
    UserState userState = (widget.uid == myUid) ? ref.read(userMyControllerProvider) : ref.read(userControllerProvider);

    if (userState.userStatus == UserStatus.reFetching) {
      return; // 이미 다음 페이지를 가져오는 중이면, 이 함수는 실행되지 않는다
    }

    bool hasNext = userState.hasNext;

    // 스크롤을 끝까지 했다면, 그리고 아직 가져올 피드가 남았다면
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && hasNext) {
      // 현재까지 조회한 피드 목록 중 가장 마지막 피드 모델
      FeedModel lastFeedModel = userState.feedList.last;

      userController.getProfile(
        uid: widget.uid,
        feedId: lastFeedModel.feedId,
      );
    }
  }

  /**
   * 보고 싶은 유저의 프로필 데이터를 가져오는 함수
   */
  void _getProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await userController.getProfile(uid: widget.uid);
      } on CustomException catch (e) {
        MessageDialog(e.toString());
      }
    });
  }

  /**
   * Feed, Follower, Following에 대한 정보를 위젯으로 반환하는 함수
   */
  Widget _profileInfoWidget({
    required int num, // 각 항목들의 개수
    required String label, // 각 항목들의 이름
  }) {
    return Column(
      children: [
        num.toString().text.size(22).bold.makeWithDefaultFont(),
        label.text.size(15).fontWeight(FontWeight.w400).color(context.appColors.lessImportantColor).makeWithDefaultFont(),
      ],
    );
  }

  /**
   * 3. 로그아웃 버튼, 또는 다른 유저라면 팔로우/언팔로우 버튼을 만든다
   * 비동기값(= 비동기 함수)을 인자로 받을 때는 AsyncCallback을 사용한다
   */
  Widget _customButtonWidget({
    required AsyncCallback asyncCallback,
    required String text,
  }) {
    return TextButton(
      onPressed: () async {
        try {
          await asyncCallback();
        } on CustomException catch (e) {
          MessageDialog(e.toString());
        }
      },
      style: TextButton.styleFrom(
        side: BorderSide(
          color: context.appColors.uploadContainer,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      child: text.text.makeWithDefaultFont(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 내 프로필을 보는지 / 다른 유저의 프로필을 보는지에 따라 가져오는 userState가 다름
    UserState userState = (widget.uid == myUid) ? ref.watch(userMyControllerProvider) : ref.watch(userControllerProvider);
    UserModel userModel = userState.userModel;
    List<FeedModel> feedList = userState.feedList; // 그 유저가 작성한 피드 리스트

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: context.appColors.seedColor.getSwatchByBrightness(100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // 1. 유저의 프로필 이미지와 닉네임
                  Column(
                    children: [
                      AvatarWidget(userModel: userModel, isTap: false, radius: 40),
                      height5,
                      userModel.nickname.text.bold.makeWithDefaultFont(),
                    ],
                  ),
                  // 2. Feed, Follower, Following에 대한 정보
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _profileInfoWidget(
                            num: userModel.feedCount, label: context.tr("feed_count")),
                        _profileInfoWidget(
                            num: userModel.followers.length, label: context.tr("follower")),
                        _profileInfoWidget(
                            num: userModel.following.length,
                            label: context.tr("following")),
                      ],
                    ),
                  ),
                ],
              ),

              /// 3. 로그아웃 버튼 / 다른 유저라면 팔로우/언팔 버튼
              myUid == userModel.uid
                  ? _customButtonWidget(
                      asyncCallback:
                          ref.read(authControllerProvider.notifier).signOut,
                      text: context.tr("logout"))
                  : _customButtonWidget(
                      asyncCallback: () async {
                        await userController.followUser(followId: userModel.uid);
                      },
                      text: userModel.followers.contains(myUid)
                          ? context.tr("unfollow")
                          : context.tr("follow")),
              height20,
              Line(color: context.appColors.uploadContainer),
              height10,

              /// 4. 사용자가 작성한 피드를 그리드 뷰로 표시
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  // 그리드뷰 옵션 속성
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 3,
                  ),
                  itemCount: feedList.length + 1,
                  itemBuilder: (context, index) {
                    // index는 0 ~ feedList.length-1 까지는 피드를 표시하고, 마지막에는 로딩 위젯을 표시한다
                    // + feedState.hasNext가 true일 때만 표시하면 된다
                    if (feedList.length == index) {
                      return userState.hasNext
                          ? Center(
                              child: CircularProgressIndicator().pOnly(bottom: 18),
                            )
                          : Container();
                    }
                    return GestureDetector(
                      onTap: () {
                        Nav.push(FeedDetailScreen(oldFeedModel: feedList[index]));
                      },
                      child: ExtendedImage.network(
                        feedList[index].imageUrls[0],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
          ).p(16),
        ),
      ),
    );
  }
}
