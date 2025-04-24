import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore fireStore;

  const UserRepository({
    required this.fireStore,
  });

  /**
   * "내가" "다른 유저"를 팔로우/언팔로우 하는 기능을 동시에 구현
   */
  Future<UserModel> followUser({
    required String myUid,
    required String followId,
  }) async {
    try {
      DocumentReference<Map<String, dynamic>> currentUserDocRef = fireStore.collection('users').doc(myUid);
      DocumentReference<Map<String, dynamic>> followUserDocRef = fireStore.collection('users').doc(followId);

      // DocumentSnapshot<Map<String, dynamic>> currentUserSnapshot = await currentUserDocRef.get();
      // List<String> following = List<String>.from(currentUserSnapshot.data()!['following']);
      // 위의 코드 2줄과 같은 로직이다!
      List<String> following = await currentUserDocRef.get().then((
          value) => List<String>.from(value.data()!['following']));

      WriteBatch batch = fireStore.batch();

      if (following.contains(followId)) { // 이미 팔로우한 유저라면 -> 언팔로우
        batch.update(currentUserDocRef, {
          'following': FieldValue.arrayRemove([followId])
        });
        batch.update(followUserDocRef, {
          'followers': FieldValue.arrayRemove([myUid])
        });
      } else { // 팔로우하지 않은 유저라면 -> 팔로우
        batch.update(currentUserDocRef, {
          'following': FieldValue.arrayUnion([followId])
        });
        batch.update(followUserDocRef, {
          'followers': FieldValue.arrayUnion([myUid])
        });
      }

      await batch.commit();

      Map<String, dynamic> map = await followUserDocRef.get().then((
          value) => value.data()!);
      return UserModel.fromMap(map); // UserModel 반환
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }

  /**
   * 유저의 아이디를 인수로 받아, 그 유저 모델을 반환하는 함수
   */
  Future<UserModel> getProfile({
    required String uid,
  }) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await fireStore.collection('users').doc(uid).get();

      return UserModel.fromMap(snapshot.data()!);
    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }
}