import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/chat/base_chat_provider.dart';
import 'package:THECommu/riverpods/chat/chat_controller.dart';
import 'package:THECommu/riverpods/friend/friend_controller.dart';
import 'package:THECommu/screen/DM/widget/w_chat_input_field.dart';
import 'package:THECommu/screen/DM/widget/w_chatting_list.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * 1대1 채팅방의 화면만 구현
 */
class ChatScreen extends StatefulHookConsumerWidget {
  static const String routeName = "/chat-screen";

  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    final currentChatRoomModel = ref.watch(chatControllerProvider).model;

    /// 1대1 채팅방에서 상대방이 나가면, 인덱스 1번이 없어지기 때문에 빈 UserModel을 넣는다
    final friendUserModel = currentChatRoomModel.userList.length > 1
        ? ref.read(friendMapProvider)[currentChatRoomModel.userList[1]] ?? UserModel.init()
        : UserModel.init();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              AvatarWidget(userModel: friendUserModel, isTap: false),
              width10,
              friendUserModel.nickname.isEmpty
                  ? context.tr('unknown').text.bold.make()
                  : friendUserModel.nickname.text.bold.ellipsis.make(),
            ],
          ),
        ),

        /// ChatInputFieldWidget()을 chat_screen과 group_chat_screen 둘 다 사용하고 있으므로
        /// ProviderScope를 사용해서 ChatRoomModel을 담은 baseChatProvider을 지역 등록한다
        /// 따라서 ChatInputFieldWidget() 내부의 로직을 통해 chat_screen이 호출했는 지 판단할 수 있다
        body: ProviderScope(
          overrides: [
            // ChatRoomModel은 baseChatRoomModel을 상속하고 있으므로, baseChatProvider에 등록할 수 있다
            baseChatProvider.overrideWithValue(currentChatRoomModel),
          ],
          child: Column(
            children: [
              Expanded(
                child: ChattingListWidget(),
              ),
              height20,
              Line(color: context.appColors.blackAndWhite),
              ChatInputFieldWidget(), // 채팅 입력 키보드 위젯
            ],
          ),
        ),
      ),
    );
  }
}
