import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'user_provider.dart';

/// 임시로 UserModel 객체 하나만 관리하는 Provider
final userModelProvider = NotifierProvider<UserModelController, UserModel>(() {
  return UserModelController();
});

class UserModelController extends Notifier<UserModel> {
  UserModelController();

  @override
  UserModel build() {
    return UserModel.init();
  }

  /**
   * UID를 입력받고, fireStore에서 조회하여 userModelProvider에 저장한다
   */
  Future<void> getUserInfoById({
    required String id,
  }) async {
    try {
      UserModel newModel = await ref.read(userRepositoryProvider).getProfile(uid: id);

      state = state.copyWith(
        uid: newModel.uid,
        nickname: newModel.nickname,
        email: newModel.email,
        profileImage: newModel.profileImage,
        feedCount: newModel.feedCount,
        followers: newModel.followers,
        following: newModel.following,
        feedLikeList: newModel.feedLikeList,
      );
    } on CustomException catch (_) {
      rethrow;
    }
  }
}
