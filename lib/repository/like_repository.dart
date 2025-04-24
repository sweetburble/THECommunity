import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/**
 * 유저가 좋아요한 피드를 모아놓는 화면을 위한 로직을 구현한 리포지토리
 */
class LikeRepository {
  final FirebaseFirestore firebaseFirestore;

  const LikeRepository({
    required this.firebaseFirestore,
  });

  /**
   * "내가" 좋아요한 피드만 조회하기 + 페이징 기능 추가
   */
  Future<List<FeedModel>> getLikeList({
    required String myUid, // 나의 UID
    required int likeLength,
    String? feedId,
  }) async {
    try {
      Map<String, dynamic> userMapData = await firebaseFirestore
          .collection('users')
          .doc(myUid)
          .get()
          .then((value) => value.data()!);

      // Map의 value의 타입을 dynamic -> String으로 변환
      List<String> likes = List<String>.from(userMapData['likes']);

      /// 페이징 로직
      if (feedId != null) {
        int startIdx = likes.indexWhere((element) => element == feedId) + 1;
        int endIdx = startIdx + likeLength > likes.length ? likes.length : startIdx + likeLength;
        // 즉, likes 리스트에서 startIdx~endIdx 만큼만 조회한다는 뜻(페이징)
        likes = likes.sublist(startIdx, endIdx);
      } else {
        // 좋아요 목록 화면을 처음 생성했을 경우
        int endIdx = likes.length < likeLength ? likes.length : likeLength;
        likes = likes.sublist(0, endIdx);
      }

      // Future.wait()를 사용함으로써, List<Future<FeedModel>> -> List<FeedModel>이 된다
      List<FeedModel> likeList = await Future.wait(likes.map((feedId) async {
        DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
            await firebaseFirestore.collection('feeds').doc(feedId).get();
        Map<String, dynamic> feedMapData = documentSnapshot.data()!;

        // 이것도 역시 firebase feeds에 저장되어있는 writer 항목은 Reference이기 때문에 UserModel로 변환
        DocumentReference<Map<String, dynamic>> userDocRef = feedMapData['writer'];
        Map<String, dynamic> writerMapData =
            await userDocRef.get().then((value) => value.data()!);
        feedMapData['writer'] = UserModel.fromMap(writerMapData);
        return FeedModel.fromMap(feedMapData);
      }).toList());

      return likeList;

    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }
}
