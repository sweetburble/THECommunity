import 'package:THECommu/common/common.dart';
import 'package:THECommu/login/signin_screen.dart';
import 'package:THECommu/riverpods/auth/auth_controller.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/auth/auth_state.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'main/main_screen.dart';

/**
 * 로그인 여부를 확인한다
 */
class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: auth.when(
        data: (user) {
          context.loaderOverlay.hide(); // 데이터를 가져왔으면, loading에서 정의한 로딩 오버레이를 숨긴다

          if (authState.authStatus == AuthStatus.unauthenticated) {
            /// 1. User 객체에 데이터가 없는, null일 경우 (로그아웃 상태) -> 로그인 화면으로 이동
            return SigninScreen();
          }

          /// 2. 모든 것이 완료된 로그인 상태일 때
          return MainScreen();
        },
        error: (error, stackTrace) {
          context.loaderOverlay.hide();
          MessageDialog(error.toString());
          logger.e(error);
          logger.e(stackTrace);
          return null;
        },
        loading: () {
          context.loaderOverlay.show();
          return null;
        },
      ),
    );
  }
}

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }