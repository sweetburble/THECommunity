import 'dart:typed_data';

import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/common/util/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/**
 * repository 클래스에서 공통적으로 사용할 firebase 인스턴스를
 * 매번 함수에서 호출하지 않고 -> field 변수로 선언한다.
 */
class AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage firebaseStorage;
  final FirebaseFirestore fireStore;

  String? _verificationId;

  AuthRepository({
    required this.firebaseAuth,
    required this.firebaseStorage,
    required this.fireStore,
  });

  /**
   * 로그아웃 로직
   */
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  /**
   * 로그인 로직
   */
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);

      bool isVerified = userCredential.user!.emailVerified;
      // 로그인 할때, 만약 아직 메일 인증을 하지 않았으면,
      if (!isVerified) {
        await userCredential.user!.sendEmailVerification();
        await firebaseAuth.signOut();
        throw CustomException(
          code: 'Exception',
          message: '인증되지 않은 이메일',
        );
      }
    } on FirebaseException catch (e) {
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      throw CustomException(code: 'Exception', message: e.toString());
    }
  }

  /**
   * 회원 가입 로직
   */
  Future<void> signUp({
    required String email,
    required String nickname,
    required String password,
    required Uint8List? profileImage, // Firebase Storage에 저장된다
  }) async {
    try {
      // UserCredential에는 로그인된 유저의 정보가 저장된다
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid; // firebase가 자동으로 생성하는 UID

      await userCredential.user!.sendEmailVerification();
      // 이메일 인증을 진행한다 -> 인증되었다면 userCredential.user.emailVerified가 true가 된다

      String? downloadURL; // null로 초기화

      if (profileImage != null) {
        Reference ref = firebaseStorage.ref().child("profile").child(uid);

        // 프로필 이미지를 완전히 스토리지에 업로드해야, 아래 코드에서 접근할 수 있다
        TaskSnapshot snapshot = await ref.putData(profileImage);

        downloadURL =
            await snapshot.ref.getDownloadURL(); // 업로드한 프로필 이미지에 접근할 수 있는 경로이다
      }

      // 파이어베이스 Storage에서 collection은 폴더라고 이해하면 쉽다!
      await fireStore.collection('users').doc(uid).set({
        'uid': uid,
        'nickname': nickname,
        'email': email,
        'profileImage': downloadURL,
        'feedCount': 0,
        'followers': [],
        'following': [],
        'feedLikeList': [],
      });

      firebaseAuth.signOut(); // 인증 메일을 눌러야 진짜 회원가입+로그인이 되는데,
      // 위 코드의 createUserWithEmailAndPassword는 자동으로 로그인까지 진행하기 때문이다
    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }


  /// 여기서부터는 전화번호 인증 로직
  /**
   * 내가 입력한 "내 전화번호"로 인증번호를 전송한다
   */
  Future<void> sendOTP({
    required String myPhoneNumber,
  }) async {
    try {
      await firebaseAuth.verifyPhoneNumber(
        phoneNumber: myPhoneNumber,
        // forceResendingToken : 인증번호 재전송 토큰
        codeSent: (verificationId, forceResendingToken) {
          _verificationId = verificationId;
        },
        verificationCompleted: (_) {},
        verificationFailed: (error) {
          logger.e(error.message);
          logger.e(error.stackTrace);
        },
        // Retrieval : 회복, 복구
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (_) {
      rethrow;
    }
  }

  /**
   * 인증번호를 검증하고, 맞다면 로그인
   */
  Future<void> verifyOTP({
    required String userOTP,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: userOTP,
      );

      await firebaseAuth.signInWithCredential(credential); // 코드인증 + 회원가입 + 로그인
    } catch (_) {
      rethrow;
    }
  }
}
