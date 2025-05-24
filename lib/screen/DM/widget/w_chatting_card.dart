import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/dart/extension/enum_extension.dart';
import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:THECommu/data/models/chat/chat_type_enum.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/chat/base_chat_provider.dart';
import 'package:THECommu/riverpods/chat/chat_provider.dart';
import 'package:THECommu/riverpods/chat/chatting_provider.dart';
import 'package:THECommu/riverpods/friend/friend_controller.dart';
import 'package:THECommu/screen/DM/widget/w_custom_image_viewer.dart';
import 'package:THECommu/screen/DM/widget/w_video_download.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

/**
 * vsync : 스마트폰 기기의 화면 갱신주기(60HZ, 120HZ)랑 애니메이션 구현을 위한 위젯 다시그리기랑 싱크를 맞춰야 함
 * baseChatProvider를 사용해서 1대1 채팅방과 그룹 채팅방을 모두 지원한다
 */
class ChattingCardWidget extends StatefulHookConsumerWidget {
  const ChattingCardWidget({
    super.key,
  });

  @override
  ConsumerState<ChattingCardWidget> createState() => _ChattingCardWidgetState();
}

class _ChattingCardWidgetState extends ConsumerState<ChattingCardWidget>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation; // 채팅 카드 위젯을 슬라이드 하기 위한 애니메이션 설정
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(
      begin: 0.0, // 애니메이션의 시작과 끝, begin에는 마이너스 값이 안 들어가는 듯
      end: 1.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /**
   * 채팅 종류에 따라(텍스트, 이미지, 동영상) 알맞은 위젯을 생성한다
   */
  Widget _makeChat({
    required String text, // 일반 텍스트, 또는 Storage에 저장된 이미지/동영상 파일 참조 주소일 수도 있다
    required ChatTypeEnum chatType,
    required bool isMyChat,
  }) {
    switch (chatType) {
      case ChatTypeEnum.image:
        return CustomImageViewerWidget(imageUrl: text);
      case ChatTypeEnum.video:
        return VideoDownloadWidget(downloadUrl: text);
      default:
        return Text(
          text,
          style: TextStyle(
            // TODO: 글자색은 보류
            // color: isMyChat ? Colors.black : Color.fromRGBO(120, 120, 120, 1),
            fontSize: 16,
          ),
        );
    }
  }

  /**
   * 내가 보낸 채팅이 답장 채팅이면, 그에 맞는 UI(위젯)를 생성한다
   * baseChatProvider를 사용해서 1대1 채팅방과 그룹 채팅방을 모두 지원한다
   */
  Widget replyChatInfoWidget({
    required bool isMyChat,
    required ChatModel replyChatModel,
    required String myUID, // 나의 UID
  }) {
    // 현재 들어와 있는 채팅방 모델
    final chatRoomModel = ref.read(baseChatProvider);

    final friendUserModel = chatRoomModel.userList.length > 1
        ? ref.read(friendMapProvider)[replyChatModel.userId] ?? UserModel.init()
        : UserModel.init();

    final userName = (myUID == replyChatModel.userId)
        ? context.tr('receiver')
        : friendUserModel.nickname.isEmpty
            ? context.tr('unknown')
            : friendUserModel.nickname;

    return ListTile(
      visualDensity: VisualDensity.compact,
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      leading: replyChatModel.chatType != ChatTypeEnum.text
          ? FittedBox(
              child: mediaPreviewWidget(
                url: replyChatModel.text,
                chatType: replyChatModel.chatType,
              ),
            )
          : null,
      title: context.tr('replyTo', namedArgs: {'userName': userName})
          .text.bold.make(),
      subtitle: Text(
        replyChatModel.chatType == ChatTypeEnum.text
            ? replyChatModel.text
            : replyChatModel.chatType.fromChatTypeEnumToText(),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.appColors.lessImportantColor),
      ),
    );
  }

  /**
   * 이미지 or 동영상 채팅을 답장할 때, 미리 보여지는 위젯
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
    /// chattingProvider : 각각의 채팅 하나하나마다 생성된 지역 프로바이더
    final chatModel = ref.watch(chattingProvider);
    final userModel = chatModel.userModel;
    final createAt =
        DateFormat.Hm().format(chatModel.createAt.toDate()); // 일단 "시간-분"만 출력

    final myUid = ref.watch(authStateProvider).value!.uid;
    final isMyChat = chatModel.userId == myUid; // 내가/상대방이 작성한 채팅인지에 따라 위젯이 다르다

    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: _animationController.value,
              // 평소에는 보이지 않다가 슬라이드 할 때, 서서히 보인다
              child: Icon(BoxIcons.bx_subdirectory_right).pOnly(right: 15),
            );
          },
        ),
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            // value 값이 최대 1까지 상승한다 (end가 1이기 때문)
            if (isMyChat) {
              _animationController.value -= (details.primaryDelta ?? 0.0) / 150;
            } else {
              _animationController.value += (details.primaryDelta ?? 0.0) / 150;
            }
          },
          onHorizontalDragEnd: (details) {
            // 답장을 달 것이라고 provider에게 전달(저장)
            // Firestore에 무한 답장 중첩 저장을 막기 위해, 원본 채팅 모델을 항상 일반 채팅처럼 취급
            // 즉, 답글 채팅에 또 답글을 달아도 -> 일반 채팅에 답글을 단 것처럼 취급
            if (_animationController.value >= 0.4) {// 민감도 조절
              ref.read(replyChatModelProvider.notifier).state = chatModel.copyWith(replyChatModel: null);
            }

            // 드래그가 끝나면, 카드 위젯은 제자리로 돌아온다
            _animationController.reverse(); // 애니메이션 역재생
          },
          child: AnimatedBuilder(
            // builder에 정의한 자식 위젯을 setState()없이도 따로 다시 그려준다 -> 성능 향상
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                // 카드 위젯이 최대 -50 또는 50 까지 드래그된다
                offset: Offset(
                    _animationController.value * (isMyChat ? -50 : 30), 0),
                child: Row(
                  mainAxisAlignment: isMyChat
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMyChat)
                      AvatarWidget(userModel: userModel, isTap: false, radius: 30),
                    width5,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMyChat) userModel.nickname.text.bold.make(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isMyChat)
                              createAt.text.size(8).color(context.appColors.lessImportantColor)
                                  .make().pOnly(right: 5, bottom: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              // 너무 긴 채팅의 오버플로우를 방지하고, 줄바꿈을 하기 위해
                              constraints: BoxConstraints(
                                maxWidth: context.deviceWidth * 0.65,
                                minWidth: 80,
                              ),
                              decoration: BoxDecoration(
                                color: isMyChat
                                    ? context.appColors.myChatCard
                                    : context.appColors.chatCard,
                                borderRadius: BorderRadius.only(
                                  // 말풍선 같이 표현하기 위해
                                  topRight: Radius.circular(16),
                                  topLeft: isMyChat
                                      ? Radius.circular(16)
                                      : Radius.circular(0),
                                  bottomRight: isMyChat
                                      ? Radius.circular(0)
                                      : Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// 답장 채팅이면
                                  if (chatModel.replyChatModel != null)
                                    replyChatInfoWidget(
                                      isMyChat: isMyChat,
                                      replyChatModel: chatModel.replyChatModel!,
                                      myUID: myUid,
                                    ),
                                  _makeChat(
                                    text: chatModel.text,
                                    chatType: chatModel.chatType,
                                    isMyChat: isMyChat,
                                  ),
                                ],
                              ),
                            ),
                            if (!isMyChat)
                              createAt.text.size(8).color(context.appColors.lessImportantColor)
                                  .make().pOnly(left: 5, bottom: 8),
                          ],
                        ),
                      ],
                    ),
                  ],
                ).pSymmetric(h: 10, v: 5),
              );
            },
          ),
        ),
      ],
    );
  }
}
