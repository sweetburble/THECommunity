import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:THECommu/data/models/chat/group_chat_room_model.dart';
import 'package:THECommu/riverpods/chat/base_chat_room_state.dart';

/**
 * "그룹 채팅방"의 데이터를 상태(state)로 갖는다
 */
class GroupChatRoomState extends BaseChatRoomState {
  GroupChatRoomState({
    required super.model, // "그룹 채팅방" 모델
    required super.chatList, // 채팅방이 가지는 채팅 내역 -> 각 채팅 모델들이 모인 리스트 형태
    required super.hasPrev,
  });

  factory GroupChatRoomState.init() {
    return GroupChatRoomState(
      model: GroupChatRoomModel.init(),
      chatList: [],
      hasPrev: false,
    );
  }

  GroupChatRoomState copyWith({
    GroupChatRoomModel? model,
    List<ChatModel>? chatList,
    bool? hasPrev,
  }) {
    return GroupChatRoomState(
      model: model ?? this.model,
      chatList: chatList ?? this.chatList,
      hasPrev: hasPrev ?? this.hasPrev,
    );
  }

  @override
  String toString() {
    return "GroupChatRoomState{model: $model, chatList: $chatList, hasPrev: $hasPrev}";
  }
}
