import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/riverpods/chat/chat_controller.dart';
import 'package:THECommu/riverpods/friend/friend_provider.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'chat_screen.dart';

/**
 * 서로 팔로우 한 유저들만 DM을 주고 받을 수 있다
 * DM 가능한 "친구"들을 표시해주는 스크린
 */
class FriendListScreen extends ConsumerWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      // getFriendListProvider는 List<UserModel>을 가지고 있다
      child: ref.watch(getFriendListProvider).when(
        data: (data) {
          context.loaderOverlay.hide();

          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (context, index) => Height(10),
            itemBuilder: (context, index) {
              final friendUserModel = data[index];
              return ListTile(
                onTap: () async {
                  try {
                    /// 1대1 채팅방 개설(또는 입장)
                    await ref.read(chatControllerProvider.notifier)
                        .enterChatFromFriendList(
                          selectedUserModel: friendUserModel,
                        );

                    // then()을 사용하면, push()로 이동한 곳에서, 뒤로가기나 pop() 등으로 빠져나올 때 실행할 로직을 정할 수 있다
                    if (context.mounted) {
                      context.push(ChatScreen.routeName).then(
                          (value) {
                            ref.invalidate(chatControllerProvider);
                          });
                    }
                  } catch (e, stackTrace) {
                    logger.e(e);
                    logger.e(stackTrace);
                    MessageDialog(e.toString());
                  }
                },
                title: friendUserModel.nickname.text.make(),
                leading: AvatarWidget(userModel: friendUserModel, isTap: false, radius: 30),
              );
            },
          );
        },
        error: (error, stackTrace) {
          context.loaderOverlay.hide();
          logger.e(error);
          logger.e(stackTrace);
          MessageDialog(error.toString());
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
