import 'dart:io';

import 'package:THECommu/common/common.dart';
import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:THECommu/data/models/chat/chat_room_model.dart';
import 'package:THECommu/data/models/chat/chat_type_enum.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/repository/chat_repository.dart';
import 'package:THECommu/riverpods/chat/chat_provider.dart';
import 'package:THECommu/riverpods/chat/chat_room_state.dart';
import 'package:THECommu/riverpods/chat/toast_new_chat_controller.dart';
import 'package:THECommu/riverpods/loader/loader_controller.dart';
import 'package:THECommu/riverpods/user/user_controller.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// TIP) 또는 ChatController.new 라고 적어도 된다
final chatControllerProvider
  = NotifierProvider<ChatController, ChatRoomState>(ChatController.new);


/**
 * "1대1 채팅방의 상태"를 가져서, 상태관리한다
 */
class ChatController extends Notifier<ChatRoomState> {
  late LoaderController loaderController;
  late ChatRepository chatRepository;
  late UserModel myUserModel; // "나의" 유저 모델

  @override
  ChatRoomState build() {
    loaderController = ref.watch(loaderControllerProvider.notifier);
    chatRepository = ref.watch(chatRepositoryProvider);
    myUserModel = ref.watch(userMyControllerProvider).userModel;

    return ChatRoomState.init();
  }

  /**
   * "친구 목록" 스크린에서 특정 친구 UI를 클릭하면, 채팅방 데이터를 생성해서 데이터베이스에 저장
   * 이미 개설된 채팅방이 없다면, 1대1 채팅방 생성
   */
  Future<void> enterChatFromFriendList({
    required UserModel selectedUserModel,
  }) async {
    try {
      loaderController.show();

      final chatRoomModel = await chatRepository.enterChatFromFriendList(
        selectedUserModel: selectedUserModel,
      );

      state = state.copyWith(
        model: chatRoomModel,
      );
    } catch (_) {
      rethrow;
    } finally {
      loaderController.hide();
    }
  }

  /**
   * "채팅방 목록" 스크린에서 특정 채팅방를 클릭하면, chat_screen으로 이동하는 로직
   */
  Future<void> enterChatFromChatRoomList({
    required ChatRoomModel chatRoomModel,
  }) async {
    try {
      loaderController.show();

      state = state.copyWith(
        model: chatRoomModel,
      );
    } catch (_) {
      rethrow;
    } finally {
      loaderController.hide();
    }
  }

  /**
   * "내가" 1대1 채팅방에서 채팅(DM) 전송
   * 텍스트 전송 / 이미지 전송 / 동영상 전송 -> 3가지 타입이 있다
   */
  Future<void> sendChat({
    String? text,
    File? file,
    required ChatTypeEnum chatType,
  }) async {
    try {
      await chatRepository.sendChat(
        text: text,
        file: file,
        chatRoomModel: state.model as ChatRoomModel,
        myUserModel: myUserModel,
        chatType: chatType,
        replyChatModel: ref.read(replyChatModelProvider),
      );
    } catch (_) {
      rethrow;
    } finally {
      // 답장 채팅을 작성하고 나면, 추가 화면 숨김
      ref.read(replyChatModelProvider.notifier).state = null;
    }
  }

  /**
   * 해당 채팅방의 채팅 내역(List<ChatModel>)을 "한 번" 가져오는 함수 (실시간 업데이트 아님!)
   * lastChatId가 null이 아님 -> 누군가의 채팅 작성
   * firstChatId가 null이 아님 -> 더 예전의 채팅 내역 조회
   * -> 둘은 동시에 발생하지 않는다!
   */
  Future<void> getChattingList({
    String? lastChatId,
    String? firstChatId,
  }) async {
    try {
      /// state에 저장할 때 ChatRoomModel -> BaseChatRoomModel로 변환해서 저장했으므로,
      /// state에 꺼낼 때도 BaseChatRoomModel -> ChatRoomModel로 변환할 수 있다,
      final chatRoomModel = state.model as ChatRoomModel;

      final chattingList = await chatRepository.getChattingList(
        chatRoomId: chatRoomModel.id,
        lastChatId: lastChatId,
        firstChatId: firstChatId,
      );
      
      // 누군가가 채팅을 작성했다면, 새 채팅 toast를 보내야 할수도 있으니까 true로 변경
      if (lastChatId != null) {
        ref.read(toastNewChatControllerProvider.notifier).newChat();
      }

      /// lastChatId가 null이 아니면, 기존 state가 가진 List + 조회한 리스트를 붙여서 다시 state에 저장한다
      /// firstChatId가 null이 아니면, 조회한 리스트 + 기존 state가 가진 최근 List를 붙여서 다시 state에 저장한다
      List<ChatModel> newChatList = [
        if (lastChatId != null) ...state.chatList,
        ...chattingList,
        if (firstChatId != null) ...state.chatList,
      ];

      // 조회한 채팅 내역이 20개 보다 적으면, 더 이상 조회할 채팅이 없다는 뜻!
      // lastChatId가 null이 아니면 -> 누군가 채팅을 작성했다 -> 그로 인해 안 보이게 된 채팅이 있을 수 있음
      // -> hasPrev = true 로 설정
      state = state.copyWith(
        chatList: newChatList,
        hasPrev: lastChatId != null || chattingList.length == 20,
      );
    } catch (_) {
      rethrow;
    }
  }

  /**
   * 채팅방 나가기 로직
   */
  Future<void> exitChatRoom({
    required ChatRoomModel chatRoomModel,
  }) async {
    try {
      await chatRepository.exitChatRoom(chatRoomModel: chatRoomModel, myUserId: myUserModel.uid);
    } catch (_) {
      rethrow;
    }
  }
}
