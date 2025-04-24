import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../common/exceptions/custom_exception.dart';

class SearchRepository {
  final FirebaseFirestore firebaseFirestore;

  const SearchRepository({
    required this.firebaseFirestore,
  });

  /**
   * 유저 검색, 검색 로직은 Firebase 한계상 startWith 방식으로밖에 안됨 ㅜㅜ
   */
  Future<List<UserModel>> searchUser({
    required String keyword,
  }) async {
    try {
      // isGreaterThanOrEqualTo는 문자열일때는 유니코드를 기준으로 작동한다
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await firebaseFirestore
              .collection('users') // "name"이 keyword라면,
              .where('nickname',
                  isGreaterThanOrEqualTo:
                      keyword) // [name1, nbme1, name2] 도 검색된다
              .where('nickname',
                  isLessThanOrEqualTo: '$keyword\uf7ff') // isLessThanOrEqualTo 사용해서 nbme1를 거른 뒤에,
              // 처음 4글자만 맞으면 뒤는 어떤 글자가 나와도 검색되도록 + \uf7ff는 유니코드에서 가장 큰 코드를 가진다
              .get();

      List<UserModel> userList = querySnapshot.docs
          .map((user) => UserModel.fromMap(user.data()))
          .toList();

      return userList;
    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }
}
