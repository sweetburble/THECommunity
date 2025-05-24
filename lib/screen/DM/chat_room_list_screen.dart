import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/chat/chat_controller.dart';
import 'package:THECommu/riverpods/chat/chat_provider.dart';
import 'package:THECommu/riverpods/friend/friend_controller.dart';
import 'package:THECommu/screen/DM/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:loader_overlay/loader_overlay.dart';

/**
 * 현재 개설된 "모든 1대1 채팅방 목록"을 보여주는 스크린
 */
class ChatRoomListScreen extends StatefulHookConsumerWidget {
  const ChatRoomListScreen({super.key});

  @override
  ConsumerState<ChatRoomListScreen> createState() => _ChattingListScreenState();
}

class _ChattingListScreenState extends ConsumerState<ChatRoomListScreen> {

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ref.watch(chatRoomListProvider).when(
        data: (data) {
          context.loaderOverlay.hide();

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final currentChatRoomModel = data[index];

              final friendModel = ref.read(friendMapProvider)[currentChatRoomModel.userList[1]] ?? UserModel.init();

              return Slidable(
                // 왼쪽 -> 오른쪽 슬라이드 시 사용
                startActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
                        await ref.read(chatControllerProvider.notifier)
                            .exitChatRoom(chatRoomModel: currentChatRoomModel);
                      },
                      backgroundColor: Colors.red,
                      icon: MingCute.exit_line,
                      label: context.tr('exit'),
                    ),
                  ],
                ),
                child: ListTile(
                  onTap: () {
                    ref.read(chatControllerProvider.notifier)
                        .enterChatFromChatRoomList(chatRoomModel: currentChatRoomModel);

                    // then()을 사용하면, push()로 이동한 곳에서, 뒤로가기나 pop() 등으로 빠져나오면 실행할 로직을 정할 수 있다
                    if (context.mounted) {
                      context.push(ChatScreen.routeName).then((value) =>
                          ref.invalidate(chatControllerProvider));
                    }
                  },
                  leading: AvatarWidget(userModel: friendModel, isTap: false, radius: 30),
                  title: Text(
                    friendModel.nickname.isEmpty
                        ? context.tr('unknown')
                        : friendModel.nickname,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    currentChatRoomModel.lastMessage,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.appColors.lessImportantColor,
                    ),
                    maxLines: 3, // 최근 채팅은 최대 3줄만 출력한다
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    DateFormat.Hm().format(currentChatRoomModel.createAt.toDate()),
                    style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.lessImportantColor),
                  ),
                ).pSymmetric(v: 10),
              );
            },
          );
        },
        error: (error, stackTrace) {
          context.loaderOverlay.hide();
          logger.e(error);
          logger.e(stackTrace);
          return null;
        },
        loading: () {
          context.loaderOverlay.show();
          return null;
        },
      ),
    );
  }
}
