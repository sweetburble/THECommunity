import 'package:THECommu/repository/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Provider는 AuthRepository의 함수만 사용 가능하지, 수정은 불가능하다!
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firebaseStorage: FirebaseStorage.instance,
    fireStore: FirebaseFirestore.instance,
  );
});

/// FirebaseAuth의 User 객체가 변할때마다 감시해서 값이 변하고, getter로 제공한다
/// 로그아웃 상태라면 null, 로그인 상태라면 User 객체를 반환한다!
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);
