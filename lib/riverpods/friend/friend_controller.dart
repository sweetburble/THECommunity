import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/friend/friend_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// friendMapProvider: uid를 키로 하고 UserModel을 값으로 가지는 Map 상태 관리
final friendMapProvider =
    NotifierProvider<FriendController, Map<String, UserModel>>(FriendController.new);

/**
 * 서로 팔로우/팔로잉을 주고 받으면, 친구가 된다 -> 서로 DM을 주고받을 수 있다
 * FriendController와 friendMapProvider는 "나"의 친구를 Map 형태로 관리한다
 */
class FriendController extends Notifier<Map<String, UserModel>> {
  @override
  Map<String, UserModel> build() {
    return {};
  }

  /// 유저 추가 또는 업데이트
  void insertFriend(UserModel user) {
    state = {
      ...state,
      user.uid: user,
    };
  }

  /// 특정 유저 삭제
  void removeFriend(String uid) {
    final updatedState = Map<String, UserModel>.from(state);
    updatedState.remove(uid);
    state = updatedState;
  }

  /// 전체 유저 삭제
  void clearFriendMap() {
    state = {};
  }

  /**
   * 맞팔한 유저 Map 전체 업데이트
   */
  Future<void> updateFriends() async {
    final newMap = await ref.read(friendRepositoryProvider).getFriendMap();
    state = newMap;
  }
}
