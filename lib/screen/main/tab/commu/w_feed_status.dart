import 'package:THECommu/common/common.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/screen/main/tab/commu/w_ice.dart';
import 'package:flutter/material.dart';

import 'w_fire.dart';

class FeedStatusWidget extends StatelessWidget {
  final FeedModel feed;

  const FeedStatusWidget(this.feed, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 50,
        height: 50,
        child: switch (feed.feedActiveStatus) {
          // FeedStatus.cold => SvgPicture.asset(
          //     "assets/image/icon/ice-cream.svg",
          //     fit: BoxFit.cover,
          //     height: 10,
          //   ),
          FeedActiveStatus.cold => const Ice(),
          FeedActiveStatus.normal => SvgPicture.asset(
              "assets/image/icon/cloudy-cloud-red.svg",
              fit: BoxFit.cover,
              height: 30,
            ),
          FeedActiveStatus.hot => const Fire()
        });
  }
}
