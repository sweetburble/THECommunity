import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/**
 * 피드에 달 수 있는 "댓글" 데이터 클래스
 */
class CommentModel {
  final String commentId; // uuid로 부여되는 고유 댓글 ID
  final String comment; // 댓글 내용
  final UserModel writer; // 댓글을 작성한 유저 모델
  final Timestamp createAt; // 댓글을 작성한 시기

  const CommentModel({
    required this.commentId,
    required this.comment,
    required this.writer,
    required this.createAt,
  });


  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'comment': comment,
      'writer': writer,
      'createAt': createAt,
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      commentId: map['commentId'] as String,
      comment: map['comment'] as String,
      writer: map['writer'] as UserModel,
      createAt: map['createAt'] as Timestamp,
    );
  }

  @override
  String toString() {
    return 'CommentModel{commentId: $commentId, comment: $comment, writer: $writer, createAt: $createAt}';
  }
}