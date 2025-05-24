import 'dart:io';

import 'package:THECommu/common/common.dart';
import 'package:THECommu/riverpods/friend/friend_provider.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_controller.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:THECommu/screen/group_chat/group_chat_screen.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loader_overlay/loader_overlay.dart';

class CreateGroupRoomScreen extends StatefulHookConsumerWidget {
  static const String routeName = "/create-group-room";

  const CreateGroupRoomScreen({super.key});

  @override
  ConsumerState<CreateGroupRoomScreen> createState() => _CreateGroupRoomScreenState();
}

class _CreateGroupRoomScreenState extends ConsumerState<CreateGroupRoomScreen> {
  File? image; // 그룹 채팅방 프로필 사진
  List<String> selectedFriendList = []; // 그룹 채팅방에 초대할 친구 목록 -> 초대 목록
  final TextEditingController textEditingController = TextEditingController();

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  /**
   * 그룹 채팅방 프로필 사진 위젯
   */
  Widget _profileWidget() {
    return GestureDetector(
      onTap: _selectImage,
      child: image == null
          ? CircleAvatar(
              backgroundColor: Colors.grey.withValues(alpha: 0.7),
              radius: 60,
              child: Icon(
                Icons.add_a_photo,
                color: Colors.black,
                size: 30,
              ),
            )
          : Stack(
              children: [
                CircleAvatar(
                  backgroundImage: FileImage(image!),
                  radius: 60,
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    onPressed: () => setState(() {
                      image = null;
                    }),
                    icon: Icon(Icons.remove_circle),
                  ),
                ),
              ],
            ),
    );
  }

  /**
   * 갤러리에서 그룹 채팅방 프로필 사진을 선택한다
   */
  Future<void> _selectImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedImage != null) {
      setState(() {
        image = File(pickedImage.path);
      });
    }
  }

  /**
   * 그룹 채팅방에 초대할 수 있는 친구들의 리스트를 표시하는 위젯
   */
  Widget _friendListWidget() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.appColors.blackAndWhite),
        ),
        width: context.deviceWidth * 0.8,
        // getFriendListProvider는 List<UserModel>을 갖는다
        child: ref.watch(getFriendListProvider).when(
          data: (data) {
            return ListView.separated(
              separatorBuilder: (context, index) => height10,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final friendUserModel = data[index]; // 친구들의 연락처 데이터 객체

                // 선택이 안된 상태면 -1 / 선택이 된 상태면 그 위치(인덱스)
                final selectedFriendIndex = selectedFriendList.indexOf(friendUserModel.uid);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectFriend(
                          userId: friendUserModel.uid, index: selectedFriendIndex);
                    });
                  },
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundImage: friendUserModel.profileImage == null
                              ? ExtendedAssetImageProvider(
                                  'assets/image/profile.png') as ImageProvider
                              : ExtendedNetworkImageProvider(friendUserModel.profileImage!),
                          radius: 20,
                        ),

                        /// 친구 선택 확인 UI
                        Opacity(
                          opacity: selectedFriendIndex != -1 ? 0.5 : 0,
                          child: CircleAvatar(
                            backgroundColor: Colors.yellow,
                            radius: 20,
                            child: Icon(MingCute.check_2_fill),
                          ),
                        ),
                      ],
                    ),
                    title: friendUserModel.nickname.text.size(16).black.make(),
                  ),
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
      ),
    );
  }

  /**
   * "친구 목록"에서 그룹 채팅방에 초대할 친구를 선택/해제하여 -> 초대목록에 추가/삭제하는 로직
   */
  _selectFriend({
    required String userId,
    required int index, // -1이면 초대 목록 추가, 그 외는 해당되는 인덱스의 요소 삭제
  }) {
    if (index != -1) {
      selectedFriendList.removeAt(index);
    } else {
      selectedFriendList.add(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 그룹 채팅방을 생성할 수 있는 최소 조건
    final isEnabled =
        selectedFriendList.length >= 2 && textEditingController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: context.tr('createGroupScreenText1').text.bold.make(),
      ),
      body: Center(
        child: Column(
          children: [
            _profileWidget(),
            Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              child: TextFormField(
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: context.tr('createGroupScreenText2'),
                ),
                onTapOutside: (_) => FocusScope.of(context).unfocus(),
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
            _friendListWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isEnabled
            ? () async {
                try {
                  await ref.read(groupChatControllerProvider.notifier)
                      .createGroupChatRoom(
                        groupChatRoomName: textEditingController.text,
                        groupChatRoomImage: image,
                        selectedFriendList: selectedFriendList,
                      );

                  if (context.mounted) {
                    // 채팅방 생성 화면으로 돌아가지 않기 위해
                    context.pushReplacement(GroupChatScreen.routeName);
                  }
                } catch (e, stackTrace) {
                  logger.e(e);
                  logger.e(stackTrace);
                  MessageDialog(e.toString());
                }
              }
            : null,
        backgroundColor: isEnabled
            ? context.appColors.chatCard
            : context.appColors.lessImportantColor,
        child: Icon(MingCute.check_2_fill),
      ),
    );
  }
}
