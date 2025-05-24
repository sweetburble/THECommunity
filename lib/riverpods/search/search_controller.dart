import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/search/search_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'search_state.dart';

class SearchController extends Notifier<SearchState> {
  SearchController();

  @override
  SearchState build() {
    return SearchState.init();
  }

  /**
   * 한 번 검색했다가 키워드를 다 지우면 -> 검색 결과도 전부 지워진다
   */
  void clear() {
    state = state.copyWith(userModelList: []);
  }

  /**
   * 유저 검색 로직 -> SearchRepository 호출
   */
  Future<void> searchUser({
    required String keyword,
  }) async {
    state = state.copyWith(searchStatus: SearchStatus.searching);

    try {
      List<UserModel> userModelList = await ref.read(searchRepositoryProvider).searchUser(keyword: keyword);

      state = state.copyWith( // 검색 결과를 userState -> userModelList에 갱신
        searchStatus: SearchStatus.success,
        userModelList: userModelList,
      );
    } on CustomException catch(_) {
      state = state.copyWith(searchStatus: SearchStatus.error);
      rethrow;
    }
  }
}

final searchControllerProvider = NotifierProvider<SearchController, SearchState>(() {
  return SearchController();
});