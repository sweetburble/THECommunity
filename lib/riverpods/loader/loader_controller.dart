import 'package:hooks_riverpod/hooks_riverpod.dart';

final loaderControllerProvider = NotifierProvider<LoaderController, bool>(() {
  return LoaderController();
});

/**
 * Riverpod을 사용해서 앱의 어디에서든지 "loader_overlay" 패키지를 이용한 로딩 화면에 접근할 수 있다
 */
class LoaderController extends Notifier<bool> {
  LoaderController();

  @override
  bool build() {
    return false;
  }

  /**
   * 로딩 화면을 보여준다
   */
  void show() {
    state = true;
  }

  /**
   * 로딩 화면을 숨긴다
   */
  void hide() {
    state = false;
  }
}

