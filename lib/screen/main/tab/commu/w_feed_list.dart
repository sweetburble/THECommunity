import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/riverpods/feed/feed_controller.dart';
import 'package:THECommu/riverpods/feed/feed_state.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:THECommu/screen/main/tab/commu/w_feed_item.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FeedList extends StatefulHookConsumerWidget {
  const FeedList({super.key});

  @override
  ConsumerState<FeedList> createState() => _FeedListState();
}

/**
 * AutomaticKeepAliveClientMixin<FeedScreen> 을 mixin 했기 때문에,
 * 다른 탭바로 이동했다가 다시 돌아와도, 모든 피드 카드를 다시 그리지 않는다
 * 즉, _getFeedList()를 다시 수행하지 않는다 => Firebase에 다시 데이터를 가져오지 않는다
 * -> 그러면, 부하가 줄어드는 대신 데이터 갱신이 되지 않으므로, 수동적인 데이터 갱신 로직이 필요하다
 */
class _FeedListState extends ConsumerState<FeedList> with AutomaticKeepAliveClientMixin<FeedList> {
  // 무한 스크롤 화면(ListView)에 페이징을 적용하기 위해서, 스크롤 컨트롤러를 사용
  final ScrollController _scrollController = ScrollController();
  late final FeedController feedController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    feedController = ref.read(feedControllerProvider.notifier);

    // 이 컨트롤러를 ListView에 등록했기 때문에, ListView를 스크롤할 때마다 실행될 (콜백) 함수를 등록한다
    _scrollController.addListener(scrollListener);
    _getFeedList();
  }

  /**
   * ListView를 스크롤할 때마다, 호출될 함수
   * _scrollController.offset; // 현재 스크롤 위치
   * _scrollController.position.maxScrollExtent; // 가능한 최대 스크롤 위치
   */
  void scrollListener() {
    FeedState feedState = ref.read(feedControllerProvider);

    if (feedState.feedStatus == FeedStatus.reFetching) {
      return; // 이미 다음 페이지를 가져오는 중이면, 이 함수는 실행되지 않는다
    }

    bool hasNext = feedState.hasNext;

    // 스크롤을 끝까지 했다면, 그리고 아직 가져올 피드가 남았다면
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && hasNext) {
      // 현재까지 조회한 피드 목록 중 가장 마지막 피드 모델
      FeedModel lastFeedModel = feedState.feedList.last;

      feedController.getFeedList(feedId: lastFeedModel.feedId); // 피드 n개 추가 로드
    }
  }


  @override
  void dispose() {
    _scrollController.removeListener(scrollListener); // 등록할 때와 마찬가지로 리스너를 제거해준다
    _scrollController.dispose();
    super.dispose();
  }

  /**
   * 위젯이 그려지기 전에 List<FeedModel>를 가져오는 것을 막기 위해서
   */
  void _getFeedList() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await feedController.getFeedList(); // 최신 피드 n개 로드
      } on CustomException catch (e) {
        MessageDialog(e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    FeedState feedState = ref.watch(feedControllerProvider);
    List<FeedModel> feedList = feedState.feedList;

    if (feedState.feedStatus == FeedStatus.fetching) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (feedState.feedStatus == FeedStatus.success && feedList.isEmpty) {
      return Center(
        child: "아직 피드가 존재하지 않습니다!".text.makeWithDefaultFont(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _getFeedList();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // 스크롤 컨트롤러를 사용하면, 위로 당겨서 목록 갱신이 안될 수가 있어서
        itemCount: feedList.length + 1, // 로딩 위젯도 표시하기 위해
        itemBuilder: (context, index) {
          // index는 0 ~ feedList.length-1 까지는 피드를 표시하고, 마지막에는 로딩 위젯을 표시한다
          // + feedState.hasNext가 true일 때만 표시하면 된다
          if (feedList.length == index) {
            return feedState.hasNext ? Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: CircularProgressIndicator(),
              ),
            ) : Container();
          }
          return FeedItemWidget(feedModel: feedList[index]);
        },
      ),
    );
  }
}
