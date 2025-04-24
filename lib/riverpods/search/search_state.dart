import 'package:THECommu/data/models/user_model.dart';

enum SearchStatus {
  init,
  searching, // 유저 검색 중...
  success,
  error,
}

class SearchState {
  final SearchStatus searchStatus;
  final List<UserModel> userModelList; // 현재 유저 검색 결과를 -> UserModel 리스트에 담는다

  const SearchState({
    required this.searchStatus,
    required this.userModelList,
  });

  factory SearchState.init() {
    return SearchState(
      searchStatus: SearchStatus.init,
      userModelList: []
    );
  }

  SearchState copyWith({
    SearchStatus? searchStatus,
    List<UserModel>? userModelList,
  }) {
    return SearchState(
      searchStatus: searchStatus ?? this.searchStatus,
      userModelList: userModelList ?? this.userModelList,
    );
  }

  @override
  String toString() {
    return 'SearchState{searchStatus: $searchStatus, userModelList: $userModelList}';
  }
}