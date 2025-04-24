import 'package:THECommu/data/models/feed_model.dart';

enum LikeStatus {
  init,
  submitting,
  fetching,
  reFetching, // 페이징 상태 추가
  success,
  error,
}

/**
 * 내가 좋아요한 피드를 따로 보는 화면을 만들기 위한 '상태'
 */
class LikeState {
  final LikeStatus likeStatus;
  final List<FeedModel> likeList; // 내가 좋아요한 피드
  final bool hasNext;

  const LikeState({
    required this.likeStatus,
    required this.likeList,
    required this.hasNext,
});

  factory LikeState.init() {
    return LikeState(
      likeStatus: LikeStatus.init,
      likeList: [],
      hasNext: true,
    );
  }

  LikeState copyWith({
    LikeStatus? likeStatus,
    List<FeedModel>? likeList,
    bool? hasNext,
  }) {
    return LikeState(
      likeStatus: likeStatus ?? this.likeStatus,
      likeList: likeList ?? this.likeList,
      hasNext: hasNext ?? this.hasNext,
    );
  }

  @override
  String toString() {
    return 'LikeState{likeStatus : $likeStatus, likeList: $likeList, hasNext: $hasNext}';
  }
}