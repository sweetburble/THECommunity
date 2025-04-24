import 'package:THECommu/repository/search_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    firebaseFirestore: FirebaseFirestore.instance,
  );
});