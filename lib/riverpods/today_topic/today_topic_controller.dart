import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/today_topic.dart';
import 'package:THECommu/riverpods/today_topic/today_topic_provider.dart';
import 'package:THECommu/riverpods/today_topic/today_topic_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class TodayTopicController extends Notifier<TodayTopicState> {
  TodayTopicController();

  @override
  TodayTopicState build() {
    return TodayTopicState.init();
  }

  /**
   * 내 정보를 가져와서 userState(= userMyControllerProvider가 관리하는 State)에 저장한다
   */
  Future<void> getTodayTopic() async {
    try {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now()); // 예시 : "2024-10-21"

      TodayTopic todayTopic =
          await ref.read(todayTopicRepositoryProvider).getTodayTopic(today);

      state = state.copyWith(
        todayTopicStatus: TodayTopicStatus.success,
        todayTopic: todayTopic,
      );
    } on CustomException catch (_) {
      state = state.copyWith(todayTopicStatus: TodayTopicStatus.error);
      rethrow;
    }
  }
}

final todayTopicControllerProvider = NotifierProvider<TodayTopicController, TodayTopicState>(() {
  return TodayTopicController();
});
