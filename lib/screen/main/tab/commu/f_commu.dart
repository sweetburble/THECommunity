import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/dart/extension/color_extension.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/riverpods/today_topic/today_topic_controller.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:THECommu/screen/dialog/d_topic_bottom_sheet.dart';
import 'package:THECommu/screen/main/tab/commu/w_feed_list.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommunityFragment extends StatefulHookConsumerWidget {
  const CommunityFragment({super.key});

  @override
  ConsumerState<CommunityFragment> createState() => _CommunityFragmentState();
}

class _CommunityFragmentState extends ConsumerState<CommunityFragment> {

  @override
  void initState() {
    super.initState();
    _showConfirmDialog(context);
    logger.d("community_fragment initState() 시작");
  }

  /**
   * 커뮤니티 프래그먼트에 "오늘의 주제" 표시하기
   */
  Future<void> _showConfirmDialog(BuildContext context) async {
    await ref.read(todayTopicControllerProvider.notifier).getTodayTopic();

    String topic = ref.read(todayTopicControllerProvider).todayTopic.topic;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        TopicBottomSheet(
          topic,
          textColor: Colors.black,
          fontSize: 18,
          context: context,
          backgroundColor: Colors.yellow.shade200,
        ).show();
      } on CustomException catch (e) {
        MessageDialog(e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Container(
          color: context.appColors.seedColor.getSwatchByBrightness(100),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu),
                  )
                ],
              ),
              Expanded(child: const FeedList().pSymmetric(h: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
