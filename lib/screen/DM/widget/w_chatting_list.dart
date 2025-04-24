import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/dart/extension/enum_extension.dart';
import 'package:THECommu/common/util/global_navigator.dart';
import 'package:THECommu/data/models/chat/chat_room_model.dart';
import 'package:THECommu/data/models/chat/chat_type_enum.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/chat/base_chat_provider.dart';
import 'package:THECommu/riverpods/chat/chat_controller.dart';
import 'package:THECommu/riverpods/chat/chat_provider.dart';
import 'package:THECommu/riverpods/chat/chatting_provider.dart';
import 'package:THECommu/riverpods/chat/toast_new_chat_controller.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_controller.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_provider.dart';
import 'package:THECommu/screen/DM/widget/w_chatting_card.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * 채팅방에서 앱바와 키보드를 제외한 "채팅 내역 영역"을 표시하는 위젯
 * baseChatProvider를 사용해서 1대1 채팅방과 그룹 채팅방을 모두 지원한다
 */
class ChattingListWidget extends StatefulHookConsumerWidget {
  const ChattingListWidget({super.key});

  @override
  ConsumerState<ChattingListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends ConsumerState<ChattingListWidget> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getChatList();
    scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  /**
   * "예전 채팅 내역을 조회할 지 결정"하기 위해 스크롤의 위치를 파악한다
   * + "채팅방 상태"에 이전 채팅 내역이 있는 지 관리하는 hasPrev 속성으로 최적화한다
   */
  void scrollListener() {
    final baseChatRoomModel = ref.read(baseChatProvider);

    /// 1대1 채팅방의 채팅 내역을 확인하고 싶다면, 1대1 채팅 컨트롤러 호출
    /// 그룹 채팅방의 채팅 내역을 확인하고 싶다면, 그룹 채팅 컨트롤러를 호출한다
    final controllerProvider = baseChatRoomModel is ChatRoomModel
        ? chatControllerProvider
        : groupChatControllerProvider;
    final baseState = ref.read(controllerProvider);

    // hasPrev 값은 chatControllerProvider 또는 groupChatControllerProvider에서 관리한다
    if (baseState.hasPrev &&
        scrollController.offset >= scrollController.position.maxScrollExtent) {
      if (baseChatRoomModel is ChatRoomModel) {
        ref.read(chatControllerProvider.notifier).getChattingList(
              firstChatId: baseState.chatList.first.chattingId,
            );
      } else {
        ref.read(groupChatControllerProvider.notifier).getChattingList(
              firstChatId: baseState.chatList.first.chattingId,
            );
      }
    }
  }

  /**
   * 이 채팅방의 채팅 내역을 "한 번" 조회하는 함수
   */
  Future<void> _getChatList() async {
    final baseChatRoomModel = ref.read(baseChatProvider);

    /// 1대1 채팅방의 채팅 내역을 확인하고 싶다면, 1대1 채팅 컨트롤러 호출
    /// 그룹 채팅방의 채팅 내역을 확인하고 싶다면, 그룹 채팅 컨트롤러를 호출한다
    if (baseChatRoomModel is ChatRoomModel) {
      await ref.read(chatControllerProvider.notifier).getChattingList();
    } else {
      await ref.read(groupChatControllerProvider.notifier).getChattingList();
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 1대1 채팅방의 채팅 내역을 확인하고 싶다면, 1대1 채팅 컨트롤러 호출
    /// 그룹 채팅방의 채팅 내역을 확인하고 싶다면, 그룹 채팅 컨트롤러를 호출한다
    final baseChatRoomModel = ref.read(baseChatProvider);
    final controllerProvider = baseChatRoomModel is ChatRoomModel
        ? chatControllerProvider
        : groupChatControllerProvider;
    final chattingList = ref.watch(controllerProvider).chatList; // 채팅 내역
    final myUID = ref.watch(authStateProvider).value!.uid; // "나의" UserID

    // (group)chatControllerProvider 를 listen하고 있으므로
    // BaseChatRoomState가 가지고 있는, List<ChatModel> chatList(= 채팅내역)이 변할 때마다 함수를 실행
    ref.listen(controllerProvider, (previous, next) {
      /// 지금 보고 있는 화면이 채팅방의 최신 채팅를 볼 수 없는 위치일 때 "토스트(Toast)" 전송

      if (ref.watch(toastNewChatControllerProvider) == false) return;

      // 1) minScrollExtent : SingleChildScrollView가 생성되었을 때의 첫 위치
      if (scrollController.offset <= scrollController.position.minScrollExtent + 20) return;

      // 2) controllerProvider를 초기화 할 때, 토스트가 전달되면 안된다
      // 3) 스크롤을 올려서, 예전 채팅 내역을 가져올 때, 토스트가 전달되면 안된다 -> 채팅 내역의 first가 달라지면 과거 내역 조회를 했다는 뜻
      // 4) 내가 채팅를 작성했을 때는, 토스트가 전달되면 안된다
      if (next.model.id.isEmpty ||
          previous == null ||
          previous.chatList.first != next.chatList.first ||
          next.chatList.last.userId == myUID) { return; }

      /// 채팅 타입(텍스트,이미지,동영상)에 맞게 다른 토스트를 전송
      final newChat = next.chatList.last;
      GlobalNavigator.showToast(
        msg: newChat.chatType != ChatTypeEnum.text
            ? newChat.chatType.fromChatTypeEnumToText()
            : "새로운 채팅 : ${newChat.text}",
      );

      ref.read(toastNewChatControllerProvider.notifier).sendToast();
    });

    final streamListProvider = baseChatRoomModel is ChatRoomModel
        ? chatRoomListProvider
        : groupChatRoomListProvider;

    /// ref.listen() : 등록한 provider의 값이 변하면, 등록한 함수(로직)을 실행한다
    ref.listen(streamListProvider, (previous, next) {
      final updatedModelList = next.value;
      final updatedModel =
          updatedModelList?.first; // repository에서 채팅방 리스트를 최신 업데이트 순으로 조회하기 때문

      // 지금 보고있는 채팅방에서 값이 변했다면(= 나 포함 누군가 새로운 채팅을 했다면), 변경된 채팅 내역만 조회한다
      if (updatedModelList != null &&
          updatedModel!.id == baseChatRoomModel.id) {
        final lastChatId =
            chattingList.isNotEmpty ? chattingList.last.chattingId : null;

        if (baseChatRoomModel is ChatRoomModel) {
          ref
              .read(chatControllerProvider.notifier)
              .getChattingList(lastChatId: lastChatId);
        } else {
          ref
              .read(groupChatControllerProvider.notifier)
              .getChattingList(lastChatId: lastChatId);
        }
      }
    });

    return SingleChildScrollView(
      controller: scrollController,
      reverse: true,
      child: Column(
        children: [
          for (final chatting in chattingList)
            /// const : 불변 객체를 생성한다 -> 즉, 채팅을 칠 때마다 모든 채팅 목록을 생성하는 오버헤드를 최적화하기 위해
            ProviderScope(
              // w_chatting_list만 사용하는 프로바이더를 여기에 정의(오버라이드)
              overrides: [
                chattingProvider.overrideWithValue(chatting),
              ],
              child: const ChattingCardWidget(),
            ),
        ],
      ),
    );
  }
}
