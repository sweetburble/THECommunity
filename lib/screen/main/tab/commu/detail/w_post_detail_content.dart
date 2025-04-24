import 'package:THECommu/common/common.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:flutter/material.dart';

/**
 * 피드의 내용을 표현하는 위젯
 */
class FeedDetailContent extends StatelessWidget {
  final FeedModel feedModel;

  const FeedDetailContent({
    super.key,
    required this.feedModel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        feedModel.content.text.make().pOnly(top: 30, bottom: 60),
      ],
    ).pSymmetric(h: 15);
  }
}
