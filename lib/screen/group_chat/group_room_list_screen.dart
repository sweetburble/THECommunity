import 'package:THECommu/common/common.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_controller.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_provider.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:THECommu/screen/group_chat/group_chat_screen.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'create_group_room_screen.dart';

class GroupRoomListScreen extends ConsumerWidget {
  const GroupRoomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ref.watch(groupChatRoomListProvider).when(
            data: (data) {
              context.loaderOverlay.hide();

              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final groupChatRoomModel = data[index];

                  return Slidable(
                    // 왼쪽 -> 오른쪽 슬라이드 시 사용
                    startActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.25,
                      children: [
                        SlidableAction(
                          onPressed: (context) async {
                            await ref.read(groupChatControllerProvider.notifier).exitGroupChatRoom(groupChatRoomModel: groupChatRoomModel);

                            ref.invalidate(groupChatControllerProvider);
                          },
                          backgroundColor: Colors.red,
                          icon: MingCute.exit_line,
                          label: context.tr('exit'),
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        ref.read(groupChatControllerProvider.notifier).enterGroupChatFromGroupList(groupChatRoomModel: groupChatRoomModel);

                        // then()을 사용하면, push()로 이동했다가 뒤로가기,pop() 등으로 빠져나오면 실행할 로직을 정할 수 있다
                        if (context.mounted) {
                          context.push(GroupChatScreen.routeName).then(
                                  (value) => ref.invalidate(groupChatControllerProvider));
                        }
                      },
                      leading: CircleAvatar(
                        backgroundImage: groupChatRoomModel.groupRoomImageUrl == null
                            ? ExtendedAssetImageProvider('assets/image/profile.png')
                        as ImageProvider
                            : ExtendedNetworkImageProvider(
                            groupChatRoomModel.groupRoomImageUrl!),
                        radius: 30,
                      ),
                      title: groupChatRoomModel.groupRoomName.text.bold.make(),
                      subtitle: Text(
                        groupChatRoomModel.lastMessage,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.appColors.lessImportantColor,
                        ),
                        maxLines: 3, // 최근 채팅는 최대 3줄만 출력한다
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        DateFormat.Hm().format(groupChatRoomModel.createAt.toDate()),
                        style: TextStyle(
                            fontSize: 13,
                            color: context.appColors.lessImportantColor),
                      ),
                    ).pSymmetric(v: 10),
                  );
                },
              );
            },
            error: (e, stackTrace) {
              context.loaderOverlay.hide();
              logger.e(e);
              logger.e(stackTrace);
              MessageDialog(e.toString());
              return null;
            },
            loading: () {
              context.loaderOverlay.show();
              return null;
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(CreateGroupRoomScreen.routeName);
        },
        child: Icon(BoxIcons.bx_message_square_add),
      ),
    );
  }
}
