import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/**
 * DM을 사용하기 위해, 유저의 연락처를 조작하는 리포지토리
 * 연락처를 비교해서 친구가 되는 것이 아닌, 서로 팔로우한 상태여야 친구 목록에 표시되도록 수정
 */
class FriendRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore fireStore;

  const FriendRepository({
    required this.firebaseAuth,
    required this.fireStore,
  });

  /**
   * 서로 팔로우한 상태여야 친구 목록에 표시된다
   */
  Future<List<UserModel>> getFriendList() async {
    try {
      final myUID = firebaseAuth.currentUser!.uid; // "나"의 UID

      DocumentReference<Map<String, dynamic>> myUserDocRef = fireStore.collection('users').doc(myUID);

      // 내가 팔로잉한 유저 리스트
      List<String> followingList = await myUserDocRef.get().then((
          value) => List<String>.from(value.data()!['following']));

      // 나를 팔로우한 유저 리스트
      List<String> followersList = await myUserDocRef.get().then((
          value) => List<String>.from(value.data()!['followers']));

      // Set으로 변환 후 intersection 메서드 사용
      List<String> friendUidList = followingList.toSet()
          .intersection(followersList.toSet())
          .toList();

      List<UserModel> friendList = [];

      for (final friendUid in friendUidList) {
        // 찾은 uid를 가지고 "users" 컬렉션에서 해당 유저의 데이터를 가져온다
        final documentSnapshot =
        await fireStore.collection("users").doc(friendUid).get();

        // 가져온 유저의 데이터로 "유저 모델"을 만든다 (firebase에만 닉네임과 프로필 사진 데이터가 있으니까)
        friendList.add(UserModel.fromMap(documentSnapshot.data()!));
      }

      return friendList;

    } catch (_) {
      rethrow;
    }
  }

  /**
   * friend_controller가 관리하는 Map<String, UserModel>가 사용할 맞팔 목록을 firebase에서 찾아서 Map 형태로 반환
   */
  Future<Map<String, UserModel>> getFriendMap() async {
    try {
      final myUID = firebaseAuth.currentUser!.uid; // "나"의 UID

      DocumentReference<Map<String, dynamic>> myUserDocRef = fireStore.collection('users').doc(myUID);

      // 내가 팔로잉한 유저 리스트
      List<String> followingList = await myUserDocRef.get().then((
          value) => List<String>.from(value.data()!['following']));

      // 나를 팔로우한 유저 리스트
      List<String> followersList = await myUserDocRef.get().then((
          value) => List<String>.from(value.data()!['followers']));

      // Set으로 변환 후 intersection 메서드 사용
      List<String> friendUidList = followingList.toSet()
          .intersection(followersList.toSet())
          .toList();

      Map<String, UserModel> friendMap = {};

      for (final friendUid in friendUidList) {
        // 찾은 uid를 가지고 "users" 컬렉션에서 해당 유저의 데이터를 가져온다
        final documentSnapshot = await fireStore.collection("users").doc(friendUid).get();

        // 가져온 유저의 데이터로 "유저 모델"을 만든다 (firebase에만 닉네임과 프로필 사진 데이터가 있으니까)
        friendMap[friendUid] = UserModel.fromMap(documentSnapshot.data()!);
      }

      return friendMap;

    } catch (_) {
      rethrow;
    }
  }
}
