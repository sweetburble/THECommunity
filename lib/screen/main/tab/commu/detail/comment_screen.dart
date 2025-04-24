import 'package:THECommu/common/common.dart';
import 'package:THECommu/data/models/comment_model.dart';
import 'package:THECommu/screen/main/tab/commu/detail/w_comment_item.dart';
import 'package:flutter/material.dart';

/**
 * 피드에 달린 "모든 댓글" 들을 표시하는 스크린 위젯
 */
class CommentScreen extends StatelessWidget {
  final List<CommentModel> commentList;

  const CommentScreen({
    super.key,
    required this.commentList,
  });

  @override
  Widget build(BuildContext context) {
    if (commentList.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: "피드의 첫번째 댓글을 달아주세요!".text.makeWithDefaultFont(),
        ),
      );
    }

    return ListView.builder(
        shrinkWrap: true,
        itemCount: commentList.length,
        itemBuilder: (context, index) {
          return CommentItemWidget(commentModel: commentList[index]);
        });
  }
}
