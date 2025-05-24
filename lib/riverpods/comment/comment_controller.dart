import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/comment_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/riverpods/comment/comment_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'comment_state.dart';

class CommentController extends Notifier<CommentState> {
  CommentController();

  @override
  CommentState build() {
    return CommentState.init();
  }

  /**
   * 어떤 피드에 작성된 모든 댓글들을 조회하는 함수
   */
  Future<void> getCommentList({
    required String feedId,
  }) async {
    state = state.copyWith(commentStatus: CommentStatus.fetching);

    try {
      List<CommentModel> commentList = await ref.read(commentRepositoryProvider)
          .getCommentList(feedId: feedId);

      state = state.copyWith(
        commentStatus: CommentStatus.success,
        commentList: commentList,
      );
    } on CustomException catch (_) {
      state = state.copyWith(commentStatus: CommentStatus.error);
      rethrow;
    }
  }

  /**
   * "내가" 어떤 피드에 댓글 작성
   */
  Future<void> uploadComment({
    required String feedId,
    required String comment,
  }) async {
    state = state.copyWith(commentStatus: CommentStatus.submitting);

    try {
      final String myUid = ref.read(authStateProvider).value!.uid;

      CommentModel newCommentModel =
          await ref.read(commentRepositoryProvider).uploadComment(
                feedId: feedId,
                uid: myUid,
                comment: comment,
              );

      state = state.copyWith(
        commentStatus: CommentStatus.success,
        commentList: [...state.commentList, newCommentModel],
      );
    } on CustomException catch (_) {
      state = state.copyWith(commentStatus: CommentStatus.error);
      rethrow;
    }
  }
}

final commentControllerProvider =
    NotifierProvider<CommentController, CommentState>(() {
  return CommentController();
});
