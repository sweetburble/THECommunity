import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/data/models/user_model.dart';

enum UserStatus {
  init, // 초기
  submitting, // 제출중
  fetching, // 피드 목록 조회 중
  reFetching, // 페이징 -> n개의 데이터를 표시하고 나서, 그 다음 n개의 데이터를 가져오는 중의 상태
  success, // 성공
  error, // 에러
}

class UserState {
  final UserStatus userStatus;
  final UserModel userModel; // 유저 데이터 클래스
  final List<FeedModel> feedList; // 특정 유저만 작성한 피드 리스트
  final bool hasNext; // 페이징을 위해

  const UserState({
    required this.userStatus,
    required this.userModel,
    required this.feedList,
    required this.hasNext,
  });

  factory UserState.init() {
    return UserState(
      userStatus: UserStatus.init,
      userModel: UserModel.init(),
      feedList: [],
      hasNext: true,
    );
  }

  UserState copyWith({
    UserStatus? userStatus,
    UserModel? userModel,
    List<FeedModel>? feedList,
    bool? hasNext,
  }) {
    return UserState(
      userStatus: userStatus ?? this.userStatus,
      userModel: userModel ?? this.userModel,
      feedList: feedList ?? this.feedList,
      hasNext: hasNext ?? this.hasNext,
    );
  }

  @override
  String toString() {
    return 'UserState{userStatus: $userStatus, userModel: $userModel, feedList: $feedList, hasNext: $hasNext}';
  }
}

