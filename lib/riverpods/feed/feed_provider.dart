import 'package:THECommu/repository/feed_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(
    firebaseStorage: FirebaseStorage.instance,
    firebaseFirestore: FirebaseFirestore.instance,
  );
});
