import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/feed/feed_provider.dart';
import 'package:THECommu/riverpods/user/user_provider.dart';
import 'package:THECommu/riverpods/user/user_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userControllerProvider = NotifierProvider<UserController, UserState>(() {
  return UserController();
});

/// "나의 UserState"만 제공하는 Provider를 추가 생성
final userMyControllerProvider = NotifierProvider<UserController, UserState>(() {
  return UserController();
});

class UserController extends Notifier<UserState> {
  UserController();

  @override
  UserState build() {
    return UserState.init();
  }

  /**
   * 내 정보를 가져와서 userState(= userMyControllerProvider가 관리하는 State)에 저장한다
   */
  Future<void> getUserInfo() async {
    try {
      String myUid = ref.read(authStateProvider).value!.uid;

      UserModel userModel =
          await ref.read(userRepositoryProvider).getProfile(uid: myUid);
      List<FeedModel> myFeedList =
          await ref.read(feedRepositoryProvider).getFeedList(uid: myUid);
      state = state.copyWith(
          userStatus: UserStatus.init,
          userModel: userModel,
          feedList: myFeedList,
          hasNext: false);
    } on CustomException catch (_) {
      rethrow;
    }
  }

  /**
   * 어떤 유저의 프로필을 조회하는 함수 -> user_repository 호출해서 그 유저의 모델을 받고,
   * feed_repository 호출해서는 그 유저의 피드 리스트를 받는다
   * 페이징이 적용되었다 -> 프로필 화면은 한번에 8개 정도는 출력해야 이쁘다
   */
  Future<void> getProfile({
    required String uid, // 어떤 유저의 UID
    String? feedId,
  }) async {
    final int feedLength = 8;
    state = feedId == null
        ? state.copyWith(userStatus: UserStatus.fetching)
        : state.copyWith(userStatus: UserStatus.reFetching);

    try {
      UserModel userModel =
          await ref.read(userRepositoryProvider).getProfile(uid: uid);

      List<FeedModel> feedList =
          await ref.read(feedRepositoryProvider).getFeedList(
                uid: uid,
                feedId: feedId,
                feedLength: feedLength,
              );

      List<FeedModel> newFeedList = [
        if (feedId != null) ...state.feedList,
        ...feedList,
      ];

      state = state.copyWith(
        userStatus: UserStatus.success,
        feedList: newFeedList,
        userModel: userModel,
        hasNext: feedList.length == feedLength,
      );
    } on CustomException catch (_) {
      state = state.copyWith(userStatus: UserStatus.error);
      rethrow;
    }
  }

  /**
   * "나의 피드"를 삭제했을 때
   */
  void deleteFeed({
    required String feedId,
  }) {
    state = state.copyWith(userStatus: UserStatus.submitting);

    try {
      // 1. 삭제한 피드만 빼고, 새로운 newFeedList를 만든다
      List<FeedModel> newFeedList = state.feedList.where((element) => element.feedId != feedId).toList();

      // 2. UserState에서 -> UserModel의 feedCount 값을 1 감소시켜야 한다
      UserModel myUserModel = state.userModel;
      UserModel newUserModel = myUserModel.copyWith(
        feedCount: myUserModel.feedCount - 1,
      );

      state = state.copyWith(
        userStatus: UserStatus.success,
        feedList: newFeedList,
        userModel: newUserModel,
      );
    } on CustomException catch (_) {
      state = state.copyWith(userStatus: UserStatus.error);
      rethrow;
    }
  }

  /**
   * "내가" -> 어떤 유저를 팔로잉/언팔로잉하는 함수
   */
  Future<void> followUser({
    required String followId,
  }) async {
    state = state.copyWith(userStatus: UserStatus.submitting);

    try {
      final String myUid = ref.read(authStateProvider).value!.uid;

      UserModel userModel = await ref.read(userRepositoryProvider)
          .followUser(myUid: myUid, followId: followId);

      state = state.copyWith(
        userStatus: UserStatus.success,
        userModel: userModel,
      );
    } on CustomException catch (_) {
      state = state.copyWith(userStatus: UserStatus.error);
      rethrow;
    }
  }

  /**
   * 1) userState -> UserModel -> feedLikeList에 반영
   * 2) userState -> feedList에 반영 (자기가 작성한 게시물에 좋아요 누를수도 있으니까)
   * 업데이트된 feedModel을 인자값으로 전달받아서, 그걸 가지고 UserState의 새로운 FeedList를 만든다
   */
  void likeFeed({
    required FeedModel newFeedModel, // 이미 좋아요 / 취소가 완료된 feedModel
  }) {
    state = state.copyWith(userStatus: UserStatus.submitting);

    try {
      /// 1) 좋아요/취소를 같이 구현한다
      // newFeedModel의 likes에 myUid가 있으면 좋아요 로직을 실행, 없으면 취소 로직을 실행한다
      if (newFeedModel.likes.contains(state.userModel.uid)) {
        UserModel newUserModel = state.userModel;
        List<String> newFeedLikeList = newUserModel.feedLikeList;
        newFeedLikeList.add(newFeedModel.feedId);

        newUserModel = newUserModel.copyWith(feedLikeList: newFeedLikeList);
        state = state.copyWith(
          userModel: newUserModel,
        );
      } else {
        /// 취소 로직
        UserModel newUserModel = state.userModel;

        List<String> newFeedLikeList = state.userModel.feedLikeList
            .where((element) => element != newFeedModel.feedId)
            .toList();

        newUserModel = newUserModel.copyWith(
          feedLikeList: newFeedLikeList,
        );
        state = state.copyWith(
          userModel: newUserModel,
        );
      }

      /// 2) 1이랑 다르게, 이미 newFeedModel에 구현되어 있으므로 그대로 feedList를 만들어주면 된다
      List<FeedModel> newFeedList = state.feedList.map((feed) {
        return feed.feedId == newFeedModel.feedId ? newFeedModel : feed;
      }).toList();

      state = state.copyWith(
        userStatus: UserStatus.success,
        feedList: newFeedList,
      );
    } on CustomException catch (_) {
      state = state.copyWith(userStatus: UserStatus.error);
      rethrow;
    }
  }
}
