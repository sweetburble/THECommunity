import 'package:THECommu/data/models/chat/base_chat_room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/**
 * 1대1 채팅방 모델
 */
class ChatRoomModel extends BaseChatRoomModel {
  ChatRoomModel({
    required super.id,
    super.lastMessage = "",
    required super.userList,
    required super.createAt,
  });

  factory ChatRoomModel.init() {
    return ChatRoomModel(
      id: "",
      userList: [],
      createAt: Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lastMessage': lastMessage,
      // firestore에는 UserModel 그대로가 아닌 -> uid(String) 리스트로 저장한다
      'userList': userList,
      'createAt': createAt,
    };
  }

  factory ChatRoomModel.fromMap({
    required Map<String, dynamic> map,
    required List<String> userModelList,
  }) {
    return ChatRoomModel(
      id: map['id'] as String,
      lastMessage: map['lastMessage'] as String,
      userList: userModelList,
      createAt: map['createAt'] as Timestamp,
    );
  }

  ChatRoomModel copyWith({
    String? id,
    String? lastMessage,
    List<String>? userList,
    Timestamp? createAt,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      lastMessage: lastMessage ?? this.lastMessage,
      userList: userList ?? this.userList,
      createAt: createAt ?? this.createAt,
    );
  }
}
