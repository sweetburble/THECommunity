import 'package:cloud_firestore/cloud_firestore.dart';

/**
 * "1대1 채팅방 모델"과 "그룹 채팅방 모델"의 부모 모델
 */
abstract class BaseChatRoomModel {
  final String id; // 채팅방 ID
  final String lastMessage; // 채팅방의 마지막 채팅
  final List<String> userList; // 채팅방에 참여한 유저 리스트
  final Timestamp createAt; // 채팅방 생성 또는 수정 시간

  const BaseChatRoomModel({
    required this.id,
    this.lastMessage = "",
    required this.userList,
    required this.createAt,
  });
}