import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_chat_room_model.dart';

/**
 * "그룹 채팅방"의 데이터 모델
 */
class GroupChatRoomModel extends BaseChatRoomModel {
  final String groupRoomName; // 그룹 채팅방 이름
  final String? groupRoomImageUrl; // 그룹 채팅방의 대표 이미지

  const GroupChatRoomModel({
    required super.id,
    required super.userList,
    required super.createAt,
    super.lastMessage = "",
    required this.groupRoomName,
    this.groupRoomImageUrl,
  });

  factory GroupChatRoomModel.init() {
    return GroupChatRoomModel(
      id: "",
      userList: [],
      createAt: Timestamp.now(),
      groupRoomName: "",
      groupRoomImageUrl: "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      "userList": userList,
      "createAt": createAt,
      "lastMessage": lastMessage,
      'groupRoomName': groupRoomName,
      'groupRoomImageUrl': groupRoomImageUrl,
    };
  }

  factory GroupChatRoomModel.fromMap({
    required Map<String, dynamic> map,
    required List<String> userList,
  }) {
    return GroupChatRoomModel(
      id: map['id'],
      userList: userList,
      createAt: map['createAt'],
      lastMessage: map['lastMessage'],
      groupRoomName: map['groupRoomName'],
      groupRoomImageUrl: map['groupRoomImageUrl'],
    );
  }

  GroupChatRoomModel copyWith({
    String? id,
    List<String>? userList,
    Timestamp? createAt,
    String? lastMessage,
    String? groupRoomName,
    String? groupRoomImageUrl,
  }) {
    return GroupChatRoomModel(
      id: id ?? this.id,
      userList: userList ?? this.userList,
      createAt: createAt ?? this.createAt,
      lastMessage: lastMessage ?? this.lastMessage,
      groupRoomName: groupRoomName ?? this.groupRoomName,
      groupRoomImageUrl: groupRoomImageUrl ?? this.groupRoomImageUrl,
    );
  }

  @override
  String toString() {
    return 'GroupChatRoomModel{groupRoomName: $groupRoomName, groupRoomImageUrl: $groupRoomImageUrl}';
  }
}
