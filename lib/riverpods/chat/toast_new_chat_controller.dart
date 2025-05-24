import 'package:hooks_riverpod/hooks_riverpod.dart';

final toastNewChatControllerProvider = NotifierProvider<ToastNewChatController, bool>(() {
  return ToastNewChatController();
});

/**
 * 채팅방 내에서 과거 채팅을 보다가, 새로운 채팅이 올라오면 알림(Toast)을 전송하기 위한 프로바이더
 * Toast를 한 번만 전송하기 위해 : 새로운 채팅이 발생하면 true, Toast가 전송되면 false로 바뀐다
 */
class ToastNewChatController extends Notifier<bool> {
  ToastNewChatController();

  @override
  bool build() {
    return false;
  }

  /**
   * 새로운 채팅이 발생했다
   */
  void newChat() {
    state = true;
  }

  /**
   * Toast가 한 번 전송되었다
   */
  void sendToast() {
    state = false;
  }
}

