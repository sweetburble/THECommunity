import 'dart:typed_data';

import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/common/util/logger.dart';
import 'package:THECommu/repository/auth_repository.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/loader/loader_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});

/**
 * AuthController는 인증 상태를 변경하는 로직을 가진다
 * -> 따라서 AuthController를 생성할 때, AuthState도 동시에 생성한다.
 * Notifier는 별도의 Notifier 함수로 생성해서, 값이 변경되었을 때 실행할 로직을 구현할 수 있다!
 *
 * 기존 signIn() / signOut()에서는 함수가 실행되어야, state의 값을 변경했다. -> state.copyWith()
 * 하지만 Firebase 자체에서 문제가 발생할 수 있으므로,
 * Firebase Auth 인증 상태에 따라 AuthStatus 상태를 변경하도록 로직을 구성하자
 */
class AuthController extends Notifier<AuthState> {
  late AuthRepository authRepository; // 리포지토리에 구현된 함수를 호출하기 위해
  late LoaderController loaderController; // 로딩 화면을 그리기 위한 컨트롤러

  AuthController();

  @override
  AuthState build() {
    _listenForAuthChanges(); // 초기 상태 설정
    authRepository = ref.watch(authRepositoryProvider);
    loaderController = ref.watch(loaderControllerProvider.notifier);
    return AuthState.init();
  }

  /**
   * FirebaseAuth의 User 객체의 값을 감시하여 분기한다
   * ref.watch는 빌드 단계에서만 사용되기 때문에, 상태 변화에 반응하려면 ref.listen을 사용해야 한다
   */
  void _listenForAuthChanges() {
    // authStateProvider의 상태 변화 감지
    ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (previous, next) {
        final user = next.value;

        logger.d("update가 실행되었습니다!");

        if (user != null && !user.emailVerified) {
          return; // 1. 이메일 인증을 받지 않은 경우 main 화면으로 못가게 함
        }

        if (user == null && state.authStatus == AuthStatus.unauthenticated) {
          return; // 2. 미인증 이메일로 로그인할 때, 상태 변화가 없어도 splashScreen에서 캐치
        }

        // user 값을 감시하여 변경되면 상태를 업데이트
        if (user != null) {
          // 로그인 상태면
          state = state.copyWith(
            authStatus: AuthStatus.authenticated,
          );
        } else {
          // 로그아웃 상태면
          state = state.copyWith(
            authStatus: AuthStatus.unauthenticated,
          );
        }
      },
    );
  }

  /**
   * 로그인 로직
   */
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // loaderController.show(); // 실제로 로딩 화면을 보여주는 로직은 아니고, state(상태)만 변경한다
      await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
    } on CustomException catch (_) {
      rethrow;
    } finally {
      // loaderController.hide();
    }
  }

  /**
   * 로그아웃 로직
   */
  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  /**
   * 회원가입 로직
   */
  Future<void> signUp({
    required String email,
    required String nickname,
    required String password,
    required Uint8List? profileImage,
  }) async {
    try {
      // loaderController.show();

      await ref.read(authRepositoryProvider).signUp(
            email: email,
            nickname: nickname,
            password: password,
            profileImage: profileImage,
          );
    } on CustomException catch (_) {
      rethrow; // signup_screen.dart의 회원가입 버튼 클릭 로직으로 다시 예외를 던진다
    } finally {
      // loaderController.hide();
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
      loaderController.show();
      await authRepository.sendOTP(myPhoneNumber: myPhoneNumber);
    } catch (_) {
      rethrow;
    } finally {
      loaderController.hide();
    }
  }

  /**
   * 인증번호를 검증하고, 맞다면 로그인
   */
  Future<void> verifyOTP({
    required String userOTP,
  }) async {
    try {
      loaderController.show();
      await authRepository.verifyOTP(userOTP: userOTP);
    } catch (_) {
      rethrow;
    } finally {
      loaderController.hide();
    }
  }
}
