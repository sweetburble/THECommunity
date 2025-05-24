import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/theme/custom_theme_app.dart';
import 'package:THECommu/riverpods/loader/loader_controller.dart';
import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'common/theme/custom_theme.dart';
import 'router.dart';

class App extends StatefulHookConsumerWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  /// light, dark 테마가 준비되었고, 시스템 테마를 따라가게 하려면 해당 필드를 제거
  static const defaultTheme = CustomTheme.light;
  static bool isForeground = true;

  const App({super.key});

  @override
  ConsumerState<App> createState() => AppState();
}

class AppState extends ConsumerState<App> with Nav, WidgetsBindingObserver {
  final router = makeGoRouter(navigatorKey: App.navigatorKey); // router.dart 확인!

  @override
  GlobalKey<NavigatorState> get navigatorKey => App.navigatorKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// listen : loaderControllerProvider가 관리하는 State(상태)에 변화가 생기면, 정의한 콜백함수를 실행
    ref.listen(loaderControllerProvider, (previous, next) {
      next ? context.loaderOverlay.show() : context.loaderOverlay.hide();
    });

    return CustomThemeApp(
      child: Builder(
        builder: (context) {
          return GlobalLoaderOverlay(
            // useDefaultLoaing: false 대체
            overlayWidgetBuilder: (_) => Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            overlayColor: Color.fromRGBO(0, 0, 0, 0.4),
            child: MaterialApp.router(
              // navigatorKey: App.navigatorKey, // GoRouter를 사용하면 이 부분을 삭제하고, GoRouter 정의부 key 파라미터에 넣는다
              debugShowCheckedModeBanner: false,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              title: 'THECommu',
              theme: context.themeType.themeData,
              // home: const OTPScreen(),
              routerConfig: router,
            ),
          );
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        App.isForeground = true;
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        App.isForeground = false;
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }
}