import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * chat_provider : 전체 채팅 목록, 채팅방, 채팅방 목록 등을 관리하는 프로바이더들이 정의되어 있다
 * chatting_provider : 한 채팅(chatModel)만 관리하는 프로바이더가 정의되어 있다
 */
final chattingProvider = Provider<ChatModel>((ref) {
  /// w_chatting_list에서 오버라이드해서 사용하기 때문에, 여기는 미구현
  throw UnimplementedError();
});
