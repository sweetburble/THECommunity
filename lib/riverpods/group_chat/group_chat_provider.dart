import 'package:THECommu/data/models/chat/group_chat_room_model.dart';
import 'package:THECommu/repository/group_chat_repository.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * group_chat_provider : 그룹 채팅방, 그룹 채팅방 목록 등을 관리하는 프로바이더들이 정의되어 있다
 */


final groupChatRepositoryProvider = Provider<GroupChatRepository>((ref) {
  return GroupChatRepository(
    fireStore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});

/// "내가" 참여하고 있는 모든 그룹 채팅방을 List<GroupChatRoomModel>로 실시간 상태관리하는 StreamProvider
/// 로그아웃을 해서 더 이상 이 프로바이더를 참조하지 않으면 -> 삭제하도록 autoDispose를 붙인다
final groupChatRoomListProvider = StreamProvider.autoDispose<List<GroupChatRoomModel>>((ref) {
  final myUserId = ref.watch(authStateProvider).value!.uid; // "나의" userId

  return ref.watch(groupChatRepositoryProvider).getGroupChatRoomList(myUserId: myUserId);
});
