import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/like/like_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'like_state.dart';

class LikeController extends Notifier<LikeState> {
  LikeController();

  @override
  LikeState build() {
    return LikeState.init();
  }

  /**
   * "나의 피드" 삭제 로직
   * 이유 -> 삭제한 피드가 "내가 좋아요한 피드" 이었으면, newLikeList가 줄어들 것이고, 아니었다면 이전이랑 똑같다.
   */
  void deleteFeed({
    required String feedId,
  }) {
    state = state.copyWith(likeStatus: LikeStatus.submitting);

    try {
      // where() 문으로, 인자 값으로 받은 삭제한 피드 모델과 다른 피드들만 빼내서, 새로운 좋아요 리스트를 만든다
      List<FeedModel> newLikeList =
          state.likeList.where((element) => element.feedId != feedId).toList();

      state = state.copyWith(
        // 새로운 newLikeList를 likeState에 저장
        likeStatus: LikeStatus.success,
        likeList: newLikeList,
      );
    } on CustomException catch (_) {
      state = state.copyWith(likeStatus: LikeStatus.error);
      rethrow;
    }
  }

  /**
   * LikeState = 항상 내 데이터만 가진다
   * 따라서 "내가" 좋아요 버튼을 누르면, 항상 LikeState 안의 likeList에도 추가/삭제한다
   */
  void likeFeed({
    required FeedModel likeFeedModel,
  }) {
    state = state.copyWith(likeStatus: LikeStatus.submitting);

    try {
      List<FeedModel> newLikeList = [];

      // indexWhere()은 map()처럼 iterable 안의 모든 객체를 둘러보고, true인 것이 있으면 그 객체의 index를
      // 전부 false라면 -1을 반환한다
      int index = state.likeList
          .indexWhere((feedModel) => feedModel.feedId == likeFeedModel.feedId);

      if (index == -1) {
        // 좋아요였다면, 리스트 앞에 추가
        newLikeList = [likeFeedModel, ...state.likeList];
      } else {
        // 좋아요 취소였다면, 리스트에서 삭제
        state.likeList.removeAt(index);
        newLikeList = state.likeList.toList();
      }

      state = state.copyWith(
        likeStatus: LikeStatus.success,
        likeList: newLikeList,
      );
    } on CustomException catch (_) {
      state = state.copyWith(likeStatus: LikeStatus.error);
      rethrow;
    }
  }

  /**
   * "내가" 좋아요한 피드만 조회하기 + 페이징 기능 추가
   */
  Future<void> getLikeList({
    String? feedId,
  }) async {
    final int likeLength = 3;

    state = feedId == null
        ? state.copyWith(likeStatus: LikeStatus.fetching)
        : state.copyWith(likeStatus: LikeStatus.reFetching);

    try {
      final String myUid = ref.read(authStateProvider).value!.uid;

      List<FeedModel> likeList =
          await ref.read(likeRepositoryProvider).getLikeList(
                myUid: myUid,
                feedId: feedId,
                likeLength: likeLength,
              );

      List<FeedModel> newLikeList = [
        if (feedId != null) ...state.likeList,
        ...likeList,
      ];

      state = state.copyWith(
        likeStatus: LikeStatus.success,
        likeList: newLikeList,
        hasNext: likeList.length == likeLength,
      );
    } on CustomException catch (_) {
      state = state.copyWith(likeStatus: LikeStatus.error);
      rethrow;
    }
  }
}

final likeControllerProvider = NotifierProvider<LikeController, LikeState>(() {
  return LikeController();
});
