import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:THECommu/data/models/chat/chat_room_model.dart';
import 'package:THECommu/riverpods/chat/base_chat_room_state.dart';

/**
 * 1대1 채팅방의 데이터를 상태(state)로 갖는다
 */
class ChatRoomState extends BaseChatRoomState {
  ChatRoomState({
    required super.model,
    required super.chatList,
    required super.hasPrev,
});

  factory ChatRoomState.init() {
    return ChatRoomState(
      model: ChatRoomModel.init(),
      chatList: [],
      hasPrev: false,
    );
  }

  ChatRoomState copyWith({
    ChatRoomModel? model,
    List<ChatModel>? chatList,
    bool? hasPrev,
  }) {
    return ChatRoomState(
      model: model ?? this.model,
      chatList: chatList ?? this.chatList,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }

  @override
  String toString() {
    return "ChatRoomState{model: $model, chatList: $chatList, hasPrev: $hasPrev}";
  }
}