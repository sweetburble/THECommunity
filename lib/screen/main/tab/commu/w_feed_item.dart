import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/widget/w_rounded_container.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/screen/main/tab/commu/detail/s_feed_detail.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'w_feed_status.dart';

class FeedItemWidget extends ConsumerWidget {
  final FeedModel feedModel;

  const FeedItemWidget({
    super.key,
    required this.feedModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tap(
      onTap: () => Nav.push(
        FeedDetailScreen(oldFeedModel: feedModel),
        durationMs: 400,
        navAni: NavAni.Fade,
      ),
      child: RoundedContainer(
        color: context.appColors.itemBackground,
        child: Stack(
          children: [
            Row(
              children: [
                FeedStatusWidget(feedModel),
                width10,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    height5,
                    feedModel.title.text.size(18).bold
                        .color(context.appColors.lessImportantColor)
                        .makeWithDefaultFont(),
                    height5,
                    Row(
                      children: [
                        feedModel.writer.nickname.text
                            .color(context.appColors.lessImportantColor)
                            .size(14)
                            .makeWithDefaultFont(),
                        ' | '
                            .text
                            .color(context.appColors.lessImportantColor)
                            .size(14)
                            .makeWithDefaultFont(),
                        timeago
                            .format(feedModel.createAt.toDate(),
                                locale: context.locale
                                    .languageCode) // Timestamp -> Datetime
                            .text
                            .color(context.appColors.lessImportantColor)
                            .size(14)
                            .makeWithDefaultFont(),
                      ],
                    ),
                    height5,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          "assets/image/icon/댓글 아이콘_1.svg",
                          height: 20,
                        ),
                        feedModel.commentCount.text
                            .size(14)
                            .color(context.appColors.lessImportantColor)
                            .makeWithDefaultFont(),
                        width10,
                        SvgPicture.asset(
                          "assets/image/icon/하트 아이콘_1.svg",
                          height: 20,
                        ),
                        feedModel.likeCount.text
                            .size(14)
                            .color(context.appColors.lessImportantColor)
                            .makeWithDefaultFont(),
                      ],
                    ),
                  ],
                ),
                Spacer(),

                /// 썸네일
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: feedModel.imageUrls[0],
                    width: 70,
                  ),
                ),
                width10,
              ],
            ),
          ],
        ).pSymmetric(v: 8),
      ).pOnly(bottom: 10),
    );
  }
}
