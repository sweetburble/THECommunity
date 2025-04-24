import 'package:THECommu/common/common.dart';
import 'package:THECommu/riverpods/friend/friend_controller.dart';
import 'package:THECommu/screen/DM/chat_room_list_screen.dart';
import 'package:THECommu/screen/DM/friend_list_screen.dart';
import 'package:THECommu/screen/group_chat/group_room_list_screen.dart';
import 'package:THECommu/screen/main/w_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

class DMFragment extends StatefulHookConsumerWidget {
  static const String routeName = "/dm-fragment";

  const DMFragment({super.key});

  @override
  ConsumerState<DMFragment> createState() => _DMFragmentState();
}

class _DMFragmentState extends ConsumerState<DMFragment> {

  @override
  Widget build(BuildContext context) {
    /// 친구목록 갱신
    ref.watch(friendMapProvider.notifier).updateFriends();

    return DefaultTabController(
      animationDuration: Duration.zero, // 기본 애니메이션 삭제
      length: 3,
      child: Scaffold(
        drawer: const MenuDrawer(),
        appBar: AppBar(
          title: context.tr("mainLayoutScreenText1").text.bold.make(),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(BoxIcons.bx_user),
                iconMargin: const EdgeInsets.only(bottom: 1),
                text: context.tr("mainLayoutScreenText2"),
              ),
              Tab(
                icon: Icon(BoxIcons.bx_message_square_dots),
                iconMargin: const EdgeInsets.only(bottom: 1),
                text: context.tr("mainLayoutScreenText3"),
              ),
              Tab(
                icon: Icon(BoxIcons.bx_conversation),
                iconMargin: const EdgeInsets.only(bottom: 1),
                text: context.tr("mainLayoutScreenText4"),
              ),
            ],
          ),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(), // 스와이프로는 화면 전환 불가
          children: [
            FriendListScreen(),
            ChatRoomListScreen(),
            GroupRoomListScreen(),
          ],
        ),
      ),
    );
  }
}
