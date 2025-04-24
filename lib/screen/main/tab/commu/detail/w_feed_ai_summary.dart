import 'package:THECommu/common/common.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:flutter/material.dart';

class FeedAISummary extends StatelessWidget {
  final FeedModel feedModel;

  const FeedAISummary({
    super.key,
    required this.feedModel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.deviceWidth,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: context.appColors.blackAndWhite),
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          "AI Summary".text.bold.size(25).makeWithDefaultFont(),
          height10,
          feedModel.summary.text.makeWithDefaultFont(),
        ],
      ),
    );
  }
}
