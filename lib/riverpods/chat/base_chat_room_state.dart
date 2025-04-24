import 'package:THECommu/data/models/chat/base_chat_room_model.dart';
import 'package:THECommu/data/models/chat/chat_model.dart';

/**
 * 1대1 채팅방 + 그룹 채팅방 상태(state)의 부모 클래스
 */
abstract class BaseChatRoomState {
  final BaseChatRoomModel model; // 채팅방 모델
  final List<ChatModel> chatList; // 채팅방이 가지는 채팅 내역 -> 각 채팅 모델들이 모인 리스트 형태
  final bool hasPrev; // 더 조회할 채팅 내역이 있는가? -> 페이징

  const BaseChatRoomState({
    required this.model,
    required this.chatList,
    required this.hasPrev,
  });
}