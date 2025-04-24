import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/data/models/comment_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:flutter/material.dart';

import '../../../../../common/common.dart';

/**
 * 피드 댓글 하나의 디자인을 결정하는 위젯
 */
class CommentItemWidget extends StatelessWidget {
  final CommentModel commentModel;

  const CommentItemWidget({
    super.key,
    required this.commentModel,
  });

  @override
  Widget build(BuildContext context) {
    UserModel writer = commentModel.writer;

    return Row(
      children: [
        AvatarWidget(userModel: writer, isTap: false),
        width10,
        Column(
          mainAxisAlignment: MainAxisAlignment.center, // 문제 발생 소지 있음!
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              // 아래의 위젯들이 하나의 문자열이 돼서 들어간다.
              text: TextSpan(
                children: [
                  TextSpan(
                    text: writer.nickname,
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.appColors.blackAndWhite),
                  ),
                  WidgetSpan(child: width10),
                  TextSpan(
                    style: TextStyle(color: context.appColors.blackAndWhite),
                    text: commentModel.comment,
                  ),
                ],
              ),
            ),
            Height(4),
            Text(
              commentModel.createAt.toDate().toString().split(' ')[0],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    ).pOnly(
      top: 16,
      left: 13,
      right: 13,
    );
  }
}
