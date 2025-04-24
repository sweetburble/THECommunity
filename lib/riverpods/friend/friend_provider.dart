import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/repository/friend_repository.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(
    firebaseAuth: FirebaseAuth.instance,
    fireStore: FirebaseFirestore.instance,
  );
});

/**
 * friendRepositoryProvider.getFriendList()를 상태로 갖는 AutoDisposeFutureProvider
 * AutoDisposeFutureProvider : 등록된 상태를 더 이상 사용하는 곳이 없다면(= 참조되는 곳이 없다면), 자동으로 등록된 데이터를 없앤다
 * 그러나 기본 세팅으로는 탭을 이동할 때마다 "getFriendListProvider"를 삭제 시키므로, 추가 세팅을 정의했다
 */
final getFriendListProvider = AutoDisposeFutureProvider<List<UserModel>>((ref) {
  final link = ref.keepAlive(); // keepAlive()는 AutoDispose가 작동하지 않는다
  ref.listen(authStateProvider, (previous, next) {
    if (next.value == null) {
      link.close(); // FirebaseAuth의 User 객체가 null 이면(= 로그아웃 상태면), AutoDispose가 다시 작동한다
    }
  });
  return ref.watch(friendRepositoryProvider).getFriendList();
});