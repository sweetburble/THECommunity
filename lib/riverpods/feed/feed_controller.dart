import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/feed/feed_provider.dart';
import 'package:THECommu/riverpods/user/user_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'feed_state.dart';

class FeedController extends Notifier<FeedState> {
  FeedController();

  @override
  FeedState build() {
    return FeedState.init();
  }

  /**
   * "내가" "나의" 피드 삭제
   * feedState -> feedList(모든 유저가 작성한 피드 리스트)에서도 삭제
   */
  Future<void> deleteFeed({
    required FeedModel feedModel,
  }) async {
    state = state.copyWith(feedStatus: FeedStatus.submitting);

    try {
      await ref.read(feedRepositoryProvider).deleteFeed(feedModel: feedModel);

      // where() 문으로, 인자 값으로 받은 삭제한 피드 모델과 다른 피드들만 빼내서 새로운 피드 리스트로 만든다
      List<FeedModel> newFeedList = state.feedList
          .where((element) => element.feedId != feedModel.feedId)
          .toList();

      state = state.copyWith(
        feedStatus: FeedStatus.success,
        feedList: newFeedList, // 메인 화면은 반영되지만, 아직 좋아요 화면은 반영되지 않음!
      );
    } on CustomException catch (_) {
      state = state.copyWith(feedStatus: FeedStatus.error);
      rethrow;
    }
  }

  /**
   * (페이징을 적용한) 피드 조회
   */
  Future<void> getFeedList({
    String? feedId,
  }) async {
    final int feedLength = 7; // 한 화면에 피드가 몇 개 표시될 지 생각하면서 설정

    try {
      // feedId가 null이면, 처음 feedLength개의 피드 조회니까 fetching, 그 외는 전부 reFetching이다
      state = feedId == null
          ? state.copyWith(feedStatus: FeedStatus.fetching)
          : state.copyWith(feedStatus: FeedStatus.reFetching);

      List<FeedModel> feedList =
          await ref.read(feedRepositoryProvider).getFeedList(
                feedLength: feedLength,
                feedId: feedId,
              );

      // feedList에는 feedLength개만 담겨있으니까, 기존에 조회했던 것도 여전히 표시해야 한다
      // -> newFeedList에 기존 조회 결과도 저장하도록 로직을 작성
      List<FeedModel> newFeedList = [
        if (feedId != null) ...state.feedList,
        ...feedList,
      ];

      state = state.copyWith(
        feedList: newFeedList,
        feedStatus: FeedStatus.success,
        hasNext: feedList.length == feedLength,
        // 마지막으로 조회한 피드의 개수가 feedLength개 보다 적다면, 남은 피드는 없다는 것!
      );
    } on CustomException catch (_) {
      state = state.copyWith(feedStatus: FeedStatus.error);
      rethrow;
    }
  }

  /**
   * "내가" "나의" 피드를 등록한다
   */
  Future<void> uploadFeed({
    required List<String> files, // 피드 사진(또는 이미지 파일) 경로 리스트
    required String title, // 피드 제목
    required String content, // 피드 내용
  }) async {
    try {
      state = state.copyWith(feedStatus: FeedStatus.submitting);

      // StreamProvider<User>를 등록했기 때문에, 여기에서 User 정보를 얻어올 수 있다
      String myUid = ref.read(authStateProvider).value!.uid;

      FeedModel feedModel = await ref.read(feedRepositoryProvider)
          .uploadFeed(files: files, title: title, content: content, myUid: myUid);

      state = state.copyWith(
        feedStatus: FeedStatus.success,
        feedList: [feedModel, ...state.feedList], // 리스트 가장 앞에 추가
      );
    } on CustomException catch (_) {
      state = state.copyWith(feedStatus: FeedStatus.error);
      rethrow;
    }
  }

  /**
   * "내가" -> 피드 좋아요/취소를 하는 로직
   * TODO : 피드 활성화 구현
   */
  Future<FeedModel> likeFeed({
    required String feedId,
    required List<String> feedLikes, // 피드에 좋아요를 누른 유저들의 명단
  }) async {
    state = state.copyWith(feedStatus: FeedStatus.submitting);

    try {
      UserModel myUserModel =
          ref.read(userMyControllerProvider).userModel; // "나"의 유저 모델을 가져온다

      FeedModel newFeedModel = await ref.read(feedRepositoryProvider).likeFeed(
            feedId: feedId,
            feedLikes: feedLikes,
            myUid: myUserModel.uid,
            userLikes: myUserModel.feedLikeList,
          );

      // newFeedModel (좋아요를 누른 피드 모델로) -> 새로운 feedList를 만든다
      List<FeedModel> newFeedList = state.feedList.map((feed) {
        return feed.feedId == feedId ? newFeedModel : feed;
      }).toList();

      // 새로운 feedList를 -> feedState에 갱신시킨다
      state = state.copyWith(
        feedStatus: FeedStatus.success,
        feedList: newFeedList,
      );

      return newFeedModel;
    } on CustomException catch (_) {
      state = state.copyWith(feedStatus: FeedStatus.error);
      rethrow;
    }
  }

  /**
   * "내가" 피드에 댓글 작성
   * feedState -> feedList -> feedModel에서 commentCount 1씩 증가
   * TODO : 피드 활성화 구현
   */
  Future<void> uploadComment({
    required String feedId,
  }) async {
    state = state.copyWith(feedStatus: FeedStatus.submitting);

    try {
      // 이미 comment_repository에서 firebase를 갱신했기 때문에, 값을 가져와서 newFeedModel로 저장만 했다
      FeedModel newFeedModel =
          await ref.read(feedRepositoryProvider).getFeed(feedId: feedId);

      // newFeedModel : 댓글을 작성한 피드 모델
      List<FeedModel> newFeedList = state.feedList.map((feed) {
        return feed.feedId == feedId ? newFeedModel : feed;
      }).toList();

      // 새로운 feedList를 만들어서, feedState에 갱신시킨다
      state = state.copyWith(
        feedStatus: FeedStatus.success,
        feedList: newFeedList,
      );
    } on CustomException catch (_) {
      state = state.copyWith(feedStatus: FeedStatus.error);
      rethrow;
    }
  }
}

final feedControllerProvider = NotifierProvider<FeedController, FeedState>(() {
  return FeedController();
});
