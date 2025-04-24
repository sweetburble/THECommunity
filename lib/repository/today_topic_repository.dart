import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/today_topic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodayTopicRepository {
  final FirebaseFirestore firebaseFirestore;

  const TodayTopicRepository({
    required this.firebaseFirestore,
  });

  /**
   * Firestore에 저장되어 있는 "오늘의 토론 주제"를 가져옵니다
   */
  Future<TodayTopic> getTodayTopic(String today) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await firebaseFirestore.collection('today_topic').doc(today).get();

      Map<String, dynamic> topicModelData = snapshot.data()!;

      return TodayTopic.fromMap(topicModelData);
    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }
}