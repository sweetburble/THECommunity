import 'package:THECommu/common/dart/extension/enum_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/**
 * 피드 "활성화 상태"를 정의하는 enum
 */
enum FeedActiveStatus {
  cold,
  normal,
  hot,
}

/**
 * 피드 데이터 모델
 * Timestamp는 Unix epoch 이후의 초를 기반으로 하며,
 * DateTime는 년, 월, 일, 시, 분, 초, 밀리초 등 다양한 속성을 기반으로 한다.
 * 사용 목적: Timestamp는 Firestore에서 데이터를 저장하고 전송할 때 사용되며,
 * DateTime는 Dart 코드에서 날짜와 시간을 다루는 데 사용된다.
 */
class FeedModel {
  final String uid; // 피드를 작성한 유저의 유저 식별번호
  final String feedId; // 랜덤한 피드 식별번호
  final String title; // 피드 제목
  final String content; // 피드 내용
  final String summary; // 피드 내용을 AI로 3줄 요약
  final List<String> imageUrls; // 피드 첨부 이미지 리스트
  final List<String> likes; // 이 피드에 좋아요한 유저 리스트
  final int commentCount; // 피드에 달린 댓글 개수
  final int likeCount; // 피드 좋아요 개수
  final Timestamp createAt; // 피드 생성 시기
  final UserModel writer; // 피드 작성한 유저 모델
  final FeedActiveStatus feedActiveStatus; // 피드의 활성화 상태 (cold, normal, hot)

  FeedModel({
    required this.uid,
    required this.feedId,
    required this.title,
    required this.content,
    required this.summary,
    required this.imageUrls,
    required this.likes,
    required this.commentCount,
    required this.likeCount,
    required this.createAt,
    required this.writer,
    this.feedActiveStatus = FeedActiveStatus.cold,
  });

  Map<String, dynamic> toMap({
    required DocumentReference<Map<String, dynamic>> userDocRef,
  }) {
    return {
      'uid': uid,
      'feedId': feedId,
      'title': title,
      'content': content,
      'summary': summary,
      'imageUrls': imageUrls,
      'likes': likes,
      'commentCount': commentCount,
      'likeCount': likeCount,
      'createAt': createAt,
      'writer': userDocRef,
      'feedActiveStatus': feedActiveStatus.name,
    };
  }

  factory FeedModel.fromMap(Map<String, dynamic> map) {
    return FeedModel(
      uid: map['uid'],
      feedId: map['feedId'],
      title: map['title'],
      content: map['content'],
      summary: map['summary'],
      imageUrls: List<String>.from(map['imageUrls']),
      likes: List<String>.from(map['likes']),
      commentCount: map['commentCount'],
      likeCount: map['likeCount'],
      createAt: map['createAt'],
      writer: map['writer'],
      feedActiveStatus: (map['feedActiveStatus'] as String).toFeedActiveStatus(),
    );
  }

  @override
  String toString() {
    return 'FeedModel{uid: $uid, feedId: $feedId, title: $title, content: $content, summary: $summary, imageUrls: $imageUrls, likes: $likes, commentCount: $commentCount, likeCount: $likeCount, createAt: $createAt, writer: $writer, feedActiveStatus: $feedActiveStatus}';
  }

  FeedModel copyWith({
    String? uid,
    String? feedId,
    String? title,
    String? content,
    String? summary,
    List<String>? imageUrls,
    List<String>? likes,
    int? commentCount,
    int? likeCount,
    Timestamp? createAt,
    UserModel? writer,
    FeedActiveStatus? feedActiveStatus,
  }) {
    return FeedModel(
      uid: uid ?? this.uid,
      feedId: feedId ?? this.feedId,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrls: imageUrls ?? this.imageUrls,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      likeCount: likeCount ?? this.likeCount,
      createAt: createAt ?? this.createAt,
      writer: writer ?? this.writer,
      feedActiveStatus: feedActiveStatus ?? this.feedActiveStatus,
    );
  }
}