import 'package:THECommu/repository/today_topic_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final todayTopicRepositoryProvider = Provider<TodayTopicRepository>((ref) {
  return TodayTopicRepository(
    firebaseFirestore: FirebaseFirestore.instance,
  );
});
