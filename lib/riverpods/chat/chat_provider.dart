import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:THECommu/data/models/chat/chat_room_model.dart';
import 'package:THECommu/repository/chat_repository.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * chat_provider : 전체 채팅 목록, 채팅방, 채팅방 목록 등을 관리하는 프로바이더들이 정의되어 있다
 * chatting_provider : 한 채팅(chatModel)만 관리하는 프로바이더가 정의되어 있다
 */


final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    fireStore: FirebaseFirestore.instance,
    firebaseAuth: FirebaseAuth.instance,
    storage: FirebaseStorage.instance,
  );
});

/// "내가" 참여하고 있는 모든 1대1 채팅방을 List<ChatRoomModel>로 실시간 상태관리하는 StreamProvider
/// 로그아웃을 해서 더 이상 이 프로바이더를 참조하지 않으면 -> 삭제하도록 autoDispose를 붙인다
final chatRoomListProvider = StreamProvider.autoDispose<List<ChatRoomModel>>((ref) {
  final myUserId = ref.watch(authStateProvider).value!.uid; // "나의" userId

  return ref.watch(chatRepositoryProvider).getChatRoomList(myUserId: myUserId);
});

/**
 * 답장 채팅 모델을 상태로 관리하는 프로바이더
 * w_chatting_card에서 클래스가 가지고 있는 ChatModel 객체를(= 답장을 달고 싶은 채팅) 상태로 갖는다
 * 따라서 이 프로바이더가 null이면 -> 일반 채팅을 작성 중인 것이다
 *                null이 아니면 -> 답장 채팅을 작성 중인 것이다
 */
final replyChatModelProvider = AutoDisposeStateProvider<ChatModel?>(
  (ref) => null,
);