/**
 * 커뮤니티 스크린에 띄워질 "오늘의 토론 주제" 데이터 클래스
 * date : 그 날짜의 토론 주제, "today_topic" 컬렉션의 문서 제목으로도 사용된다
 * tag : 정치 / 젠더 / 계급 / 개방성 이라는 주제로 gpt한테 요청한다
 * topic : gpt가 제안해준 "오늘의 토론 주제" 내용
 */
class TodayTopic {
  final String date;
  final String tag;
  final String topic;

  const TodayTopic({
    required this.date,
    required this.tag,
    required this.topic,
  });

  factory TodayTopic.init() {
    return const TodayTopic(
      date: "",
      tag: "",
      topic: "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'tag': tag,
      'topic': topic,
    };
  }

  factory TodayTopic.fromMap(Map<String, dynamic> map) {
    return TodayTopic(
      date: map['date'] as String,
      tag: map['tag'] as String,
      topic: map['topic'] as String,
    );
  }

  TodayTopic copyWith({
    String? date,
    String? tag,
    String? topic,
  }) {
    return TodayTopic(
      date: date ?? this.date,
      tag: tag ?? this.tag,
      topic: topic ?? this.topic,
    );
  }

  @override
  String toString() {
    return 'TodayTopic{date: $date, tag: $tag, topic: $topic}';
  }
}
