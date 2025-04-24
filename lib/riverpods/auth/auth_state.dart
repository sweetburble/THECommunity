enum AuthStatus {
  authenticated,
  unauthenticated,
}

/**
 * RiverPod에서 사용할 유저의 로그인(인증) 정보를 담을 클래스
 */
class AuthState {
  final AuthStatus authStatus;

  // 생성자
  const AuthState({
    required this.authStatus,
  });

  // 팩토리 생성자
  factory AuthState.init() {
    return const AuthState(
      authStatus: AuthStatus.unauthenticated,
    );
  }

  /**
   * RiverPod에 저장되어 있는 AuthState의 값을 변경할 때 사용한다
   */
  AuthState copyWith({
    AuthStatus? authStatus,
  }) {
    return AuthState(
      authStatus: authStatus ?? this.authStatus,
    );
  }

}