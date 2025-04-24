import 'package:THECommu/repository/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    fireStore: FirebaseFirestore.instance,
  );
});
