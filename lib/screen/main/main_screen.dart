import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/common/util/local_notifications.dart';
import 'package:THECommu/data/models/chat/base_chat_room_model.dart';
import 'package:THECommu/data/models/chat/chat_room_model.dart';
import 'package:THECommu/data/models/chat/group_chat_room_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/chat/chat_controller.dart';
import 'package:THECommu/riverpods/chat/chat_provider.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_controller.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_provider.dart';
import 'package:THECommu/riverpods/user/user_controller.dart';
import 'package:THECommu/riverpods/user/user_provider.dart';
import 'package:THECommu/screen/DM/f_dm.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:THECommu/screen/main/tab/Commu/f_commu.dart';
import 'package:THECommu/screen/main/tab/profile/f_profile.dart';
import 'package:THECommu/screen/main/tab/search/f_search.dart';
import 'package:THECommu/screen/main/tab/upload/f_feed_upload.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

import 'w_menu_drawer.dart';

class MainScreen extends StatefulHookConsumerWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with SingleTickerProviderStateMixin {
  late TabController tabController; // 필드 변수가 먼저 정의되고 -> 그 다음에 _MainScreenState가 정의되기 때문에

  bool get extendBody => true;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 5, // TabBarView 를 사용하기 위한 컨트롤러
      vsync: this, // 탭을 이동할 때 보여지는 애니메이션 정의
    );
    _getProfile(); // 앱을 시작하면, 앱을 사용하는 유저(나)의 데이터를 가져온다
  }

  void bottomNavigationItemOnTab(int index) {
    setState(() {
      tabController.index = index;
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  /**
   * 앱을 시작하면, 앱을 사용하는 유저(나)의 데이터를 가져온다
   */
  Future<void> _getProfile() async {
    try {
      await ref.read(userMyControllerProvider.notifier).getUserInfo();
    } on CustomException catch (e) {
      MessageDialog(e.toString());
    }
  }

  /**
   * 채팅방 밖에 있거나, 아예 앱 밖에 있을 때 -> 새로운 채팅 알림을 위한 함수
   * StreamProvider<List<BaseChatRoomModel>> : chatRoomListProvider와 groupChatRoomListProvider를 모두 받을 수 있다
   * ref.listen()을 통해 참여중인 모든 채팅방 모델을 감시한다.
   * -> 어떤 채팅방에 새로운 채팅이 전송되면, 그 채팅방 모델의 데이터도 변하니까
   */
  void _localNotification({
    required AutoDisposeStreamProvider<List<BaseChatRoomModel>> streamProvider,
  }) {
    ref.listen(streamProvider, (previous, next) async {
      // 1. 채팅방 목록을 아직 가져오는 중일 경우
      // 2. 채팅방 목록 데이터를 가져왔는데, 참여 중인 채팅방이 하나도 없을 경우
      // 3. 앱을 처음 실행한 상태일 때, listen하지 않는다
      if (next.isLoading || next.value!.isEmpty || previous!.value == null) return;

      // 4-1) 새로운 채팅이 올라온 곳이 1대1 채팅방인지 / 그룹 채팅방인지 확인한다
      // 4-2) ref.watch(provider).model.id : 현재 내가 접속 중인 채팅방 ID
      // 4-3) next.value!.first.id : 새로운 채팅이 올라온 채팅방 ID
      // -> 따라서 같으면 새로운 채팅이 올라왔다는 것을 나도 봤으니까, 알림이 필요없다
      final provider = next.value!.first is ChatRoomModel
          ? chatControllerProvider
          : groupChatControllerProvider;
      if (ref.watch(provider).model.id == next.value!.first.id) return;

      // 5. 내가 참여중인 채팅방이 증가하거나 감소했을 때도 알림이 발생할 수 있어서
      if (next.value!.length != previous.value!.length) return;

      // 6. 내가 아닌 다른 유저가 참여 중인 채팅방에서 증가, 감소했을 경우
      // 6-1) 새로운 채팅이 올라온 채팅방의 데이터를 토대로 찾아서, 이전 데이터 값도 저장한다
      // 6-2) 유저가 채팅방을 나가면, 로직상 UID가 ""가 되니까 -> 개수가 다르면 새로 나갔다는 뜻
      final nextChatRoomModel = next.value!.first;
      final prevChatRoomModel = previous.value!.firstWhere(
          (chatRoomModel) => chatRoomModel.id == nextChatRoomModel.id);
      if (nextChatRoomModel.userList
              .where((userId) => userId.isEmpty).length !=
          prevChatRoomModel.userList
              .where((userId) => userId.isEmpty).length) { return; }

      /// flutter_local_notifications 패키지로 푸시 메시지 구현
      /// 1. 푸시 메시지 title : 1대1 채팅이면 친구 닉네임, 그룹 채팅방이면 그룹 채팅방 이름
      /// 2. 푸시 메시지 body : 새로운 채팅 내용
      String title;
      if (next.value!.first is ChatRoomModel) {
        final friendModel = await ref.read(userRepositoryProvider).getProfile(uid: next.value!.first.userList[1]);
        title = friendModel.nickname;
      } else {
        title = (next.value!.first as GroupChatRoomModel).groupRoomName;
      }

      LocalNotifications.showSimpleNotification(
        title: title,
        body: next.value!.first.lastMessage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _localNotification(streamProvider: chatRoomListProvider);
    _localNotification(streamProvider: groupChatRoomListProvider);

    final myUID = ref.read(authStateProvider).value!.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => false,
      child: Scaffold(
        extendBody: false, // bottomNavigationBar 아래 영역 까지 그림
        drawer: const MenuDrawer(),
        body: TabBarView(
          controller: tabController,
          physics: NeverScrollableScrollPhysics(), // 화면 자체를 스와이프해도 탭이 변경되지 않음,
          children: [
            CommunityFragment(),
            DMFragment(),
            SearchFragment(),
            FeedUploadFragment(
              onFeedUploaded: () {
                setState(() {
                  tabController.index = 0;
                });
              },
            ),
            ProfileFragment(
              uid: myUID,
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          // shifting은 선택한 bottomNavigationBar에 애니메이션이 들어간다
          currentIndex: tabController.index,
          onTap: bottomNavigationItemOnTab,
          selectedItemColor: context.appColors.text,
          unselectedItemColor: context.appColors.iconButtonInactivate,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_network_chart),
              label: context.tr("community"),
            ),
            BottomNavigationBarItem(
              icon: Icon(BoxIcons.bx_message_square_detail),
              label: "DM",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: context.tr("search"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_outlined),
              label: context.tr("upload"),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: context.tr("profile"),
            ),
          ],
        ),
      ),
    );
  }
}
