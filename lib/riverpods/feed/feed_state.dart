import 'package:THECommu/data/models/feed_model.dart';

/**
 * 피드 "자체가 어떤 상태"인지 정의하는 enum
 */
enum FeedStatus {
  init, // 피드 초기 상태
  submitting, // 피드 등록 중
  fetching, // 피드 목록 조회 중
  reFetching, // 페이징 -> n개의 데이터를 표시하고 나서, 그 다음 n개의 데이터를 가져오는 중의 상태
  success, // 피드 등록 성공
  error, // 피드 등록 에러
}

class FeedState {
  final FeedStatus feedStatus;
  final List<FeedModel> feedList; // 모든 유저가 작성한 피드 리스트
  final bool hasNext; // 더 가져올 피드(피드)가 있는지 -> 페이징

  const FeedState({
    required this.feedStatus,
    required this.feedList,
    required this.hasNext,
  });

  factory FeedState.init() {
    return FeedState(
      feedStatus: FeedStatus.init,
      feedList: [],
      hasNext: true,
    );
  }

  FeedState copyWith({
    FeedStatus? feedStatus,
    List<FeedModel>? feedList,
    bool? hasNext,
  }) {
    return FeedState(
      feedStatus: feedStatus ?? this.feedStatus,
      feedList: feedList ?? this.feedList,
      hasNext: hasNext ?? this.hasNext,
    );
  }

  /**
   * 피드의 고유 아이디를 인수로 받아, 피드 모델(FeedModel)을 반환하는 함수
   */
  FeedModel? getFeed({
    required String feedId,
  }) {
    for (var feedModel in feedList) {
      if (feedModel.feedId == feedId) {
        return feedModel;
      }
    }
    return null;
  }
}