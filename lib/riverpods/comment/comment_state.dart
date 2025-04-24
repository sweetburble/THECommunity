import 'package:THECommu/data/models/comment_model.dart';

enum CommentStatus {
  init,
  fetching,
  submitting,
  success,
  error,
}

/**
 * 한 피드에 달린 "모든 댓글"을 "상태"로 지정했다.
 */
class CommentState {
  final CommentStatus commentStatus;
  final List<CommentModel> commentList;

  const CommentState({
    required this.commentStatus,
    required this.commentList,
  });

  factory CommentState.init() {
    return CommentState(
      commentStatus: CommentStatus.init,
      commentList: []
    );
  }

  CommentState copyWith({
    CommentStatus? commentStatus,
    List<CommentModel>? commentList,
  }) {
    return CommentState(
      commentStatus: commentStatus ?? this.commentStatus,
      commentList: commentList ?? this.commentList,
    );
  }

  @override
  String toString() {
    return "CommentState{commentStatus: $commentStatus}, commentList: $commentList}";
  }
}