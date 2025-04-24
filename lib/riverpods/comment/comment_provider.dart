import 'package:THECommu/repository/comment_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return CommentRepository(
    firebaseFirestore: FirebaseFirestore.instance,
  );
});