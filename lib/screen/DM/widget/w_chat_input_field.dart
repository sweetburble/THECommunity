import 'dart:io';

import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/dart/extension/enum_extension.dart';
import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:THECommu/data/models/chat/chat_room_model.dart';
import 'package:THECommu/data/models/chat/chat_type_enum.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/chat/base_chat_provider.dart';
import 'package:THECommu/riverpods/chat/chat_controller.dart';
import 'package:THECommu/riverpods/chat/chat_provider.dart';
import 'package:THECommu/riverpods/group_chat/group_chat_controller.dart';
import 'package:THECommu/screen/DM/widget/w_custom_image_viewer.dart';
import 'package:THECommu/screen/DM/widget/w_video_download.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';

/**
 * DM(채팅) 입력 필드 위젯과 로직을 구현했다
 * baseChatProvider를 사용해서 1대1 채팅방과 그룹 채팅방을 모두 지원한다
 */
class ChatInputFieldWidget extends StatefulHookConsumerWidget {
  const ChatInputFieldWidget({super.key});

  @override
  ConsumerState<ChatInputFieldWidget> createState() =>
      _ChatInputFieldWidgetState();
}

class _ChatInputFieldWidgetState extends ConsumerState<ChatInputFieldWidget> {
  final TextEditingController _textEditingController = TextEditingController();

  /// FocusNode를 사용한 위젯은 자신이 현재 선택되었는지/아닌지를 알 수 있다
  final FocusNode _focusNode = FocusNode();

  bool isTextInputted = false; // 빈 채팅은 보낼 수 없음
  bool isEmojiWidgetShow = false; // EmojiPicker를 보여줄 것인가?

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  /**
   * EmojiPicker와 입력 키보드는 동시에 존재할 수 없음
   */
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        isEmojiWidgetShow = false;
      });
    }
  }

  /**
   * 채팅방에 "일반 텍스트"를 보내는 함수
   */
  Future<void> _sendTextChat() async {
    final baseChatRoomModel = ref.read(baseChatProvider);
    try {
      /// chat_screen의 키보드였다면, 1대1 채팅 컨트롤러 호출
      /// group_chat_screen의 키보드였다면, 그룹 채팅 컨트롤러를 호출한다
      if (baseChatRoomModel is ChatRoomModel) {
        await ref.read(chatControllerProvider.notifier).sendChat(
              text: _textEditingController.text,
              chatType: ChatTypeEnum.text,
            );
      } else {
        await ref.read(groupChatControllerProvider.notifier).sendChat(
              text: _textEditingController.text,
              chatType: ChatTypeEnum.text,
            );
      }

      _textEditingController.clear();

      setState(() {
        isTextInputted = false;
        isEmojiWidgetShow = false;
      });
    } catch (e, stackTrace) {
      logger.e(e);
      logger.e(stackTrace);
      MessageDialog(e.toString());
    }
  }

  /**
   * BottonSheet에 사용되는 아이콘 버튼을 생성
   */
  Widget _mediaFileUploadButton({
    required IconData iconData,
    required Color backgroundColor,
    required VoidCallback onPressed,
    required String buttonName,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: backgroundColor,
            minimumSize: const Size(50, 50),
          ),
          onPressed: () {
            onPressed();
            Nav.pop(context);
          },
          child: Icon(iconData),
        ),
        height5,
        buttonName.text.bold.make(),
      ],
    ).pSymmetric(v: 30, h: 20);
  }

  /**
   * 미디어 파일 전송을 위한 BottomSheet를 보여준다
   */
  void _showMediaFileUploadSheet() {
    showBottomSheet(
      shape: const LinearBorder(),
      backgroundColor: Vx.yellow50,
      context: context,
      builder: (context) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _mediaFileUploadButton(
              iconData: MingCute.photo_album_line,
              backgroundColor: Colors.lightGreen,
              onPressed: () {
                _sendMediaChat(
                  chatType: ChatTypeEnum.image,
                );
              },
              buttonName: context.tr('image'),
            ),
            _mediaFileUploadButton(
              iconData: MingCute.video_fill,
              backgroundColor: Colors.lightBlue,
              onPressed: () {
                _sendMediaChat(
                  chatType: ChatTypeEnum.video,
                );
              },
              buttonName: context.tr('video'),
            ),
          ],
        );
      },
    );
  }

  /**
   * 채팅방에 "이미지 파일" 또는 "동영상 파일" 을 보내는 함수
   */
  Future<void> _sendMediaChat({
    required ChatTypeEnum chatType,
  }) async {
    final baseChatRoomModel = ref.read(baseChatProvider);
    XFile? xFile;
    if (chatType == ChatTypeEnum.image) {
      xFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxHeight: 1024,
        maxWidth: 1024,
      );
    } else if (chatType == ChatTypeEnum.video) {
      xFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );
    }

    if (xFile == null) return;

    /// chat_screen의 키보드였다면, 1대1 채팅 컨트롤러 호출
    /// group_chat_screen의 키보드였다면, 그룹 채팅 컨트롤러를 호출한다
    if (baseChatRoomModel is ChatRoomModel) {
      ref.read(chatControllerProvider.notifier).sendChat(
        chatType: chatType,
        file: File(xFile.path),
      );
    } else {
      ref.read(groupChatControllerProvider.notifier).sendChat(
        chatType: chatType,
        file: File(xFile.path),
      );
    }
  }

  /**
   * "답장 채팅"일 때, input_field 위에 추가로 표시되는 UI
   * baseChatProvider를 사용해서 1대1 채팅방과 그룹 채팅방을 모두 지원한다
   */
  Widget replyChatPreviewWidget({
    required ChatModel replyChatModel,
  }) {
    // 현재 들어와 있는 채팅방 모델
    final chatRoomModel = ref.read(baseChatProvider);

    final myUID = ref.watch(authStateProvider).value!.uid;
    final userName = (myUID == replyChatModel.userId)
        ? context.tr('receiver')
        : replyChatModel.userModel.nickname.isEmpty
            ? context.tr('unknown')
            : replyChatModel.userModel.nickname;

    return ListTile(
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      tileColor: Colors.blue[50],
      leading: replyChatModel.chatType != ChatTypeEnum.text
          ? FittedBox(
              child: mediaPreviewWidget(
                url: replyChatModel.text,
                chatType: replyChatModel.chatType,
              ),
            )
          : null,
      title: context
          .tr('replyTo', namedArgs: {'userName': userName})
          .text
          .bold
          .make(),
      subtitle: Text(
        replyChatModel.chatType == ChatTypeEnum.text
            ? replyChatModel.text
            : replyChatModel.chatType.fromChatTypeEnumToText(),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        // 채팅 답장 취소 -> replyChatModelProvider의 상태를 null로 비운다
        onPressed: () => ref.read(replyChatModelProvider.notifier).state = null,
        icon: Icon(MingCute.close_fill),
      ),
    );
  }

  /**
   * 이미지/동영상 채팅을 답장할 때, 미리 보여지는 위젯
   */
  Widget mediaPreviewWidget({
    required String url,
    required ChatTypeEnum chatType,
  }) {
    switch (chatType) {
      case ChatTypeEnum.video:
        return VideoDownloadWidget(downloadUrl: url);
      default:
        return CustomImageViewerWidget(imageUrl: url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final replyChatModel = ref.watch(replyChatModelProvider);

    /// 답장 채팅 인지 / 일반 채팅 인지
    final isReplyChat = (replyChatModel != null);

    return PopScope(
      // 뒤로가기 버튼을 눌렀을 때, 작동할 로직을 결정한다
      canPop: !isEmojiWidgetShow, // false면 아예 뒤로가기 버튼 동작이 막힘
      onPopInvokedWithResult: (didPop, _) {
        setState(() {
          isEmojiWidgetShow = false;
        });
      },
      child: Column(
        children: [
          /// 답장 채팅이면 : 키보드 위에 추가 위젯을 표사
          if (isReplyChat)
            replyChatPreviewWidget(replyChatModel: replyChatModel),

          Offstage(
            // offstage 값에 따라서, 아예 내부 위젯의 빌드 여부를 결정한다
            offstage: !isEmojiWidgetShow,
            child: SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _textEditingController,
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    isTextInputted = true;
                  });
                },
                onBackspacePressed: () {
                  // EmojiPicker의 삭제 버튼을 눌렀을 때
                  if (_textEditingController.text.isEmpty) {
                    setState(() {
                      isTextInputted = false;
                    });
                  }
                },
              ),
            ),
          ),
          Container(
            color: Colors.blue[50],
            child: Row(
              children: [
                if (!isReplyChat)
                  /// 일반 채팅일 때만 : 미디어 파일 전송 버튼 사용 가능
                  GestureDetector(
                    onTap: () => _showMediaFileUploadSheet(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Icon(MingCute.plus_line),
                    ),
                  ),

                /// 답장 채팅일 때 : 일반 아이콘
                if (isReplyChat) Icon(BoxIcons.bx_subdirectory_right).p(5),

                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: isReplyChat
                          ? context.tr("chattingInputFieldWidgetText2")
                          : context.tr("chattingInputFieldWidgetText1"),
                      hintStyle:
                          TextStyle(color: context.appColors.blackAndWhite),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 0,
                          style: BorderStyle.none,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(5),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && isTextInputted == false) {
                        setState(() {
                          isTextInputted = true;
                        });
                      } else if (value.isEmpty && isTextInputted == true) {
                        setState(() {
                          isTextInputted = false;
                        });
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    /// Android Native 명령어 사용
                    await SystemChannels.textInput.invokeListMethod("TextInput.hide");

                    setState(() {
                      isEmojiWidgetShow = !isEmojiWidgetShow;
                    });
                  },
                  child: Icon(MingCute.emoji_line),
                ),
                Width(15),
                if (isTextInputted)
                  GestureDetector(
                    onTap: _sendTextChat,
                    child: Container(
                      height: 55,
                      width: 55,
                      color: Colors.blueAccent,
                      child: Icon(MingCute.send_plane_line),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
