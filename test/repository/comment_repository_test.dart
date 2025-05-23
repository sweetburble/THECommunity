import 'package:THECommu/data_model/comment_model.dart';
import 'package:THECommu/data_model/user_model.dart';
import 'package:THECommu/repository/comment_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late CommentRepository commentRepository;

  // Helper to get DocumentReference for a user
  DocumentReference<Map<String, dynamic>> userDocRef(String uid) {
    return fakeFirestore.collection('users').doc(uid);
  }

  // Helper to get DocumentReference for a feed
  DocumentReference<Map<String, dynamic>> feedDocRef(String feedId) {
    return fakeFirestore.collection('feeds').doc(feedId);
  }

  // Helper to get CollectionReference for comments of a feed
  CollectionReference<Map<String, dynamic>> commentsColRef(String feedId) {
    return feedDocRef(feedId).collection('comments');
  }

  // Helper to create user data in Firestore
  Future<void> createTestUser({
    required String uid,
    required String nickname,
    String? email,
    String? profileImage,
  }) async {
    await userDocRef(uid).set({
      'uid': uid,
      'nickname': nickname,
      'email': email ?? '$uid@example.com',
      'profileImage': profileImage ?? 'http://example.com/profile/$uid.png',
      // Add other necessary UserModel fields with default values
      'feedList': [],
      'feedCount': 0,
      'following': [],
      'followers': [],
      'followingCount': 0,
      'followerCount': 0,
      'feedLikeList': [],
    });
  }

  // Helper to create feed data in Firestore
  Future<void> createTestFeed({
    required String feedId,
    required String writerUid,
    int initialCommentCount = 0,
  }) async {
    await feedDocRef(feedId).set({
      'feedId': feedId,
      'uid': writerUid, // UID of the feed writer
      'writer': userDocRef(writerUid),
      'title': 'Test Feed $feedId',
      'content': 'Content for $feedId',
      'imageUrls': [],
      'summary': 'Summary for $feedId',
      'likeCount': 0,
      'commentCount': initialCommentCount,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'whoLiked': [],
    });
  }

  // Helper to create comment data in Firestore
  Future<DocumentReference<Map<String, dynamic>>> createTestComment({
    required String feedId,
    required String commentId,
    required String writerUid,
    required String commentText,
    required Timestamp createdAt,
  }) async {
    final commentRef = commentsColRef(feedId).doc(commentId);
    await commentRef.set({
      'commentId': commentId,
      'uid': writerUid, // UID of the comment writer
      'writer': userDocRef(writerUid),
      'comment': commentText,
      'createAt': createdAt, // Note: field name in Firestore is 'createAt'
    });
    return commentRef;
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    commentRepository = CommentRepository(firebaseFirestore: fakeFirestore);
  });

  group('getCommentList method', () {
    const String feedWithCommentsId = 'feedWithComments';
    const String user1Id = 'user1';
    const String user2Id = 'user2';

    test('Test Case 1.1: Feed has multiple comments', () async {
      // --- ARRANGE ---
      // Create users
      await createTestUser(uid: user1Id, nickname: 'UserOne');
      await createTestUser(uid: user2Id, nickname: 'UserTwo');

      // Create feed
      await createTestFeed(feedId: feedWithCommentsId, writerUid: 'feedWriterUser');

      // Create comments
      final timestamp1 = Timestamp.fromMillisecondsSinceEpoch(1000);
      final timestamp2 = Timestamp.fromMillisecondsSinceEpoch(2000); // Newer
      final timestamp3 = Timestamp.fromMillisecondsSinceEpoch(500);  // Older

      await createTestComment(
          feedId: feedWithCommentsId, commentId: 'comment1', writerUid: user1Id, commentText: 'Comment by UserOne', createdAt: timestamp1);
      await createTestComment(
          feedId: feedWithCommentsId, commentId: 'comment2', writerUid: user2Id, commentText: 'Newer Comment by UserTwo', createdAt: timestamp2);
      await createTestComment(
          feedId: feedWithCommentsId, commentId: 'comment3', writerUid: user1Id, commentText: 'Older Comment by UserOne', createdAt: timestamp3);

      // --- ACT ---
      final List<CommentModel> comments = await commentRepository.getCommentList(feedId: feedWithCommentsId);

      // --- ASSERT ---
      expect(comments.length, 3, reason: "Should fetch all 3 comments");

      // Verify order (descending by createAt)
      expect(comments[0].commentId, 'comment2', reason: "First comment should be the newest");
      expect(comments[1].commentId, 'comment1', reason: "Second comment should be middle one");
      expect(comments[2].commentId, 'comment3', reason: "Third comment should be the oldest");

      // Verify writer population
      final commentFromUser1 = comments.firstWhere((c) => c.writer.uid == user1Id && c.commentId == 'comment1');
      final commentFromUser2 = comments.firstWhere((c) => c.writer.uid == user2Id && c.commentId == 'comment2');
      
      expect(commentFromUser1.writer.nickname, 'UserOne', reason: "Comment writer UserOne's nickname should be populated");
      expect(commentFromUser2.writer.nickname, 'UserTwo', reason: "Comment writer UserTwo's nickname should be populated");

      expect(comments[0].writer.uid, user2Id);
      expect(comments[0].writer.nickname, 'UserTwo');
      expect(comments[0].comment, 'Newer Comment by UserTwo');

      expect(comments[1].writer.uid, user1Id);
      expect(comments[1].writer.nickname, 'UserOne');
      expect(comments[1].comment, 'Comment by UserOne');
      
      expect(comments[2].writer.uid, user1Id);
      expect(comments[2].writer.nickname, 'UserOne');
      expect(comments[2].comment, 'Older Comment by UserOne');
    });

    test('Test Case 1.2: Feed has no comments', () async {
      // --- ARRANGE ---
      const String feedWithoutCommentsId = 'feedWithoutComments';
      await createTestFeed(feedId: feedWithoutCommentsId, writerUid: 'someUser');
      // No comments added to this feed.

      // --- ACT ---
      final List<CommentModel> comments = await commentRepository.getCommentList(feedId: feedWithoutCommentsId);

      // --- ASSERT ---
      expect(comments.isEmpty, isTrue, reason: "Returned list should be empty for a feed with no comments");
    });
  });

  group('uploadComment method', () {
    const String targetFeedId = 'targetFeedForComment';
    const String commenterUserId = 'commenterUser';
    const String commentText = "This is a test comment!";

    test('Test Case 2.1: Successfully upload a comment', () async {
      // --- ARRANGE ---
      // Create user who will comment
      await createTestUser(uid: commenterUserId, nickname: 'Commenter');
      // Create feed that will receive the comment, with initial commentCount = 0
      await createTestFeed(feedId: targetFeedId, writerUid: 'feedOwner', initialCommentCount: 0);

      // --- ACT ---
      final CommentModel uploadedComment = await commentRepository.uploadComment(
        feedId: targetFeedId,
        uid: commenterUserId, // UID of the user making the comment
        comment: commentText,
      );

      // --- ASSERT ---
      // 1. Verify new document in subcollection
      final commentsSnapshot = await commentsColRef(targetFeedId).get();
      expect(commentsSnapshot.docs.length, 1, reason: "One comment document should be created");
      final commentDocFromFirestore = commentsSnapshot.docs.first;

      // 2. Verify data in the new comment document
      final commentDataFromFirestore = commentDocFromFirestore.data();
      expect(commentDataFromFirestore['commentId'], commentDocFromFirestore.id, reason: "commentId field should match document ID");
      expect(commentDataFromFirestore['uid'], commenterUserId, reason: "Comment writer UID should be correct");
      expect(commentDataFromFirestore['writer'], userDocRef(commenterUserId), reason: "Comment writer reference should be correct");
      expect(commentDataFromFirestore['comment'], commentText, reason: "Comment text should be correct");
      expect(commentDataFromFirestore['createAt'], isA<Timestamp>(), reason: "createAt should be a Timestamp");

      // 3. Verify commentCount increment on the feed document
      final feedDocAfterComment = await feedDocRef(targetFeedId).get();
      expect(feedDocAfterComment.data()?['commentCount'], 1, reason: "Feed's commentCount should be incremented");

      // 4. Verify the returned CommentModel
      expect(uploadedComment.commentId, commentDocFromFirestore.id, reason: "Returned model's commentId is correct");
      expect(uploadedComment.uid, commenterUserId, reason: "Returned model's writer UID is correct");
      expect(uploadedComment.comment, commentText, reason: "Returned model's comment text is correct");
      expect(uploadedComment.createAt, isNotNull, reason: "Returned model's createAt should be populated");
      
      // Verify populated writer in returned CommentModel
      expect(uploadedComment.writer, isA<UserModel>(), reason: "Returned model's writer should be a UserModel");
      expect(uploadedComment.writer.uid, commenterUserId, reason: "Returned model's writer UID is correct");
      expect(uploadedComment.writer.nickname, 'Commenter', reason: "Returned model's writer nickname is correct");
    });
  });
}
