import 'package:THECommu/repository/like_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  return LikeRepository(
    firebaseFirestore: FirebaseFirestore.instance,
  );
});