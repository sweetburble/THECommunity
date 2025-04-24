import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/comment_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/**
 * 댓글과 관련된 로직을 실제로 구현한 리포지토리 (Firebase와 소통)
 */
class CommentRepository {
  final FirebaseFirestore firebaseFirestore;

  const CommentRepository({
    required this.firebaseFirestore,
  });

  /**
   * 한 피드에 달린 댓글들을 List로 조회한다
   */
  Future<List<CommentModel>> getCommentList({
    required String feedId,
  }) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await firebaseFirestore
          .collection('feeds')
          .doc(feedId)
          .collection('comments')
          .orderBy('createAt', descending: true)
          .get();

      // Future.wait()로 commentList에 Future 제거
      List<CommentModel> commentList =
          await Future.wait(snapshot.docs.map((item) async {
        Map<String, dynamic> data = item.data();
        // firestore의 comments 컬렉션의 'writer' 속성은 DocumentReference이니까 -> UserModel로 변환
        DocumentReference<Map<String, dynamic>> writerDocRef = data['writer'];
        Map<String, dynamic> writerMapData =
            await writerDocRef.get().then((value) => value.data()!);
        data['writer'] = UserModel.fromMap(writerMapData);
        return CommentModel.fromMap(data);
      }).toList());

      return commentList;

    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }

  /**
   * "내가" 댓글을 작성, 현재는 feeds 컬렉션 안에 새로운 comments 컬렉션을 만들어서 저장한다
   */
  Future<CommentModel> uploadComment({
    required String feedId,
    required String uid,
    required String comment,
  }) async {
    try {
      String commentId = Uuid().v1();

      DocumentReference<Map<String, dynamic>> writerDocRef = firebaseFirestore.collection('users').doc(uid);
      DocumentReference<Map<String, dynamic>> feedDocRef = firebaseFirestore.collection('feeds').doc(feedId);
      DocumentReference<Map<String, dynamic>> commentDocRef = feedDocRef.collection('comments').doc(commentId);

      await firebaseFirestore.runTransaction((transaction) async {
        transaction.set(commentDocRef, {
          'commentId': commentId,
          'comment': comment, // 댓글 내용
          'writer': writerDocRef,
          'createAt': Timestamp.now(),
        });

        transaction.update(feedDocRef, {
          'commentCount': FieldValue.increment(1),
        });
      });

      /// 댓글 등록 후, 등록한 댓글 데이터를 CommentModel로 만들어서 반환한다
      UserModel userModel = await writerDocRef.get().then((snapshot) => snapshot.data()!).then((data) => UserModel.fromMap(data));

      CommentModel commentModel = await commentDocRef.get().then((snapshot) => snapshot.data()!).then((data) {
        data['writer'] = userModel;
        return CommentModel.fromMap(data);
      });

      return commentModel;

    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }
}