import 'package:THECommu/common/common.dart';
import 'package:THECommu/data/models/chat/group_chat_room_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/chat/base_chat_provider.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_controller.dart';
import 'package:THECommu/screen/DM/widget/w_chat_input_field.dart';
import 'package:THECommu/screen/DM/widget/w_chatting_list.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * 1대1 채팅방의 화면만 구현
 */
class GroupChatScreen extends StatefulHookConsumerWidget {
  static const String routeName = "/group-chat-screen";

  const GroupChatScreen({super.key});

  @override
  ConsumerState<GroupChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<GroupChatScreen> {
  @override
  Widget build(BuildContext context) {
    final currentChatRoomModel =
        ref.watch(groupChatControllerProvider).model as GroupChatRoomModel;

    if (currentChatRoomModel.id.isEmpty) {
      return Container(); // GroupChatRoomModel을 init()하는 과정에서 groupRoomImageUrl에 빈 문자열이 들어가는 에러 수정
    }

    // 채팅방에 참여하고 있는 유저가 2명 이상인 경우 -> 항상 userList[0] = "나의 userModel"이 들어있기 때문에, userList[1]이 상대방 유저가 된다
    // 뒤로 가기 또는 아예 "채팅방 나가기"로 참여 유저가 1명 이하가 되면 임시로 빈 UserModel을 대입한다
    final friendUserModel = currentChatRoomModel.userList.length > 1
        ? currentChatRoomModel.userList[1]
        : UserModel.init();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: currentChatRoomModel.groupRoomImageUrl == null
                    ? ExtendedAssetImageProvider('assets/image/profile.png') as ImageProvider
                    : ExtendedNetworkImageProvider(
                        currentChatRoomModel.groupRoomImageUrl!),
              ),
              width10,
              /// 현재 채팅방에 참여하고 있는 유저들을 센다 -> 우리의 그룹 채팅방 | 3명 참가중
              '${currentChatRoomModel.groupRoomName} | ${currentChatRoomModel.userList.where((userId) =>
                userId.isNotEmpty).length}${context.tr('groupScreenText1')}'
                  .text.bold.ellipsis.make(),
            ],
          ),
        ),
        /// ChatInputFieldWidget()을 chat_screen과 group_chat_screen 둘 다 사용하고 있으므로
        /// ProviderScope를 사용해서 groupChatRoomModel을 담은 baseChatProvider을 지역 등록한다
        /// 따라서 ChatInputFieldWidget() 내부의 로직을 통해 group_chat_screen이 호출했는 지 판단할 수 있다
        body: ProviderScope(
          overrides: [
            // groupChatRoomModel은 baseChatRoomModel을 상속하고 있으므로, baseChatProvider에 등록할 수 있다
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
