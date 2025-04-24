import 'package:THECommu/data/models/today_topic.dart';

enum TodayTopicStatus {
  init, // 초기
  success, // 성공
  error, // 에러
}

class TodayTopicState {
  final TodayTopicStatus todayTopicStatus;
  final TodayTopic todayTopic;

  const TodayTopicState({
    required this.todayTopicStatus,
    required this.todayTopic,
  });

  factory TodayTopicState.init() {
    return TodayTopicState(
      todayTopicStatus: TodayTopicStatus.init,
      todayTopic: TodayTopic.init(),
    );
  }

  TodayTopicState copyWith({
    TodayTopicStatus? todayTopicStatus,
    TodayTopic? todayTopic,
  }) {
    return TodayTopicState(
      todayTopicStatus: todayTopicStatus ?? this.todayTopicStatus,
      todayTopic: todayTopic ?? this.todayTopic,
    );
  }

  @override
  String toString() {
    return 'TodayTopicState{todayTopicStatus: $TodayTopicStatus, todayTopic: $todayTopic}';
  }
}

