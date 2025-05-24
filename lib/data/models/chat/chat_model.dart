import 'package:THECommu/common/dart/extension/enum_extension.dart';
import 'package:THECommu/data/models/chat/chat_type_enum.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/**
 * "채팅 하나"의 데이터 모델
 */
class ChatModel {
  final String userId; // 해당 채팅을 작성한 유저의 ID
  final UserModel userModel; // 해당 채팅을 작성한 유저의 데이터 모델
  final String chattingId; // 이 채팅의 고유 ID
  final String text; // 채팅 내용
  final ChatTypeEnum chatType; // 채팅 타입 enum -> 텍스트/이미지/동영상
  final Timestamp createAt; // 채팅 생성 시간
  final ChatModel? replyChatModel; // 만약 이 객체가 답장 채팅이라면, 원본 채팅의 데이터 모델도 저장한다

  const ChatModel({
    required this.userId,
    required this.userModel,
    required this.chattingId,
    required this.text,
    required this.chatType,
    required this.createAt,
    required this.replyChatModel,
  });

  /**
   * toMap()으로 Firestore에 저장할 때는 "userModel"이 필요없다
   */
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'chattingId': chattingId,
      'text': text,
      'chatType': chatType.name, // Enum이므로 텍스트로 firestore에 저장한다
      'createAt': createAt,
      'replyChatModel': replyChatModel?.toMap(),
    };
  }

  factory ChatModel.fromMap(
    Map<String, dynamic> map,
      UserModel userModel,
  ) {
    return ChatModel(
      userId: map['userId'],
      userModel: userModel,
      chattingId: map['chattingId'],
      text: map['text'],
      chatType: (map['chatType'] as String).toChatTypeEnum(),
      createAt: map['createAt'],
      replyChatModel: map['replyChatModel'] == null
          ? null
          // 원본 채팅을 작성한 유저의 "데이터 모델"까지는 필요가 없기 때문
          : ChatModel.fromMap(map['replyChatModel'], UserModel.init(),),
    );
  }

  ChatModel copyWith({
    String? userId,
    UserModel? userModel,
    String? chattingId,
    String? text,
    ChatTypeEnum? chatType,
    Timestamp? createAt,
    ChatModel? replyChatModel,
  }) {
    return ChatModel(
      userId: userId ?? this.userId,
      userModel: userModel ?? this.userModel,
      chattingId: chattingId ?? this.chattingId,
      text: text ?? this.text,
      chatType: chatType ?? this.chatType,
      createAt: createAt ?? this.createAt,
      replyChatModel: replyChatModel, // null 값 대입 가능
    );
  }

  @override
  String toString() {
    return 'ChatModel{userId: $userId, userModel: $userModel, chattingId: $chattingId, text: $text, chatType: $chatType, createAt: $createAt, replyChatModel: $replyChatModel}';
  }
}
