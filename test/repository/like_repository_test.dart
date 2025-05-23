import 'package:THECommu/data_model/feed_model.dart';
import 'package:THECommu/data_model/user_model.dart';
import 'package:THECommu/repository/like_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to get DocumentReference for a user
DocumentReference<Map<String, dynamic>> userDocRef(FakeFirebaseFirestore firestore, String uid) {
  return firestore.collection('users').doc(uid);
}

// Helper to get DocumentReference for a feed
DocumentReference<Map<String, dynamic>> feedDocRef(FakeFirebaseFirestore firestore, String feedId) {
  return firestore.collection('feeds').doc(feedId);
}

// Helper to create user data in Firestore (for writers)
Future<void> createWriterUserInFirestore({
  required FakeFirebaseFirestore firestore,
  required String uid,
  String? nickname,
  String? email,
  String? profileImage,
}) async {
  await userDocRef(firestore, uid).set({
    'uid': uid,
    'nickname': nickname ?? 'Writer $uid',
    'email': email ?? '$uid@example.com',
    'profileImage': profileImage ?? 'http://example.com/profile/$uid.png',
    'feedList': [],
    'feedCount': 0,
    'following': [],
    'followers': [],
    'followingCount': 0,
    'followerCount': 0,
    'feedLikeList': [], // Renamed from 'likes' to avoid confusion with the like list being tested
  });
}

// Helper to create user data with a 'likes' list (for the user whose liked feeds are being fetched)
Future<void> createUserWithLikesInFirestore({
  required FakeFirebaseFirestore firestore,
  required String uid,
  required List<String> likedFeedIds, // List of feed IDs
  String? nickname,
  String? email,
  String? profileImage,
}) async {
  await userDocRef(firestore, uid).set({
    'uid': uid,
    'nickname': nickname ?? 'TestUser $uid',
    'email': email ?? '$uid@example.com',
    'profileImage': profileImage ?? 'http://example.com/profile/$uid.png',
    'feedLikeList': likedFeedIds, // This is the field LikeRepository reads
    'feedList': [],
    'feedCount': 0,
    'following': [],
    'followers': [],
    'followingCount': 0,
    'followerCount': 0,
  });
}


// Helper to create feed data in Firestore
Future<void> createFeedInFirestore({
  required FakeFirebaseFirestore firestore,
  required String feedId,
  required String writerUid, // UID of the feed writer
  String? title,
  String? content,
  Timestamp? createdAt,
}) async {
  await feedDocRef(firestore, feedId).set({
    'feedId': feedId,
    'uid': writerUid,
    'writer': userDocRef(firestore, writerUid), // DocumentReference to the writer
    'title': title ?? 'Feed $feedId',
    'content': content ?? 'Content for $feedId',
    'imageUrls': [],
    'summary': 'Summary for $feedId',
    'likeCount': 0,
    'commentCount': 0,
    'createdAt': createdAt ?? Timestamp.now(),
    'updatedAt': Timestamp.now(),
    'whoLiked': [],
  });
}


void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late LikeRepository likeRepository;

  const String testUserUid = 'testUserUid';
  const String writerUser1Uid = 'writerUser1';
  const String writerUser2Uid = 'writerUser2';

  final List<String> initialLikedFeedIds = ['feed1', 'feed2', 'feed3', 'feed4'];

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    likeRepository = LikeRepository(firebaseFirestore: fakeFirestore);

    // Common setup for tests that need user and feed data
    // Create writer users
    await createWriterUserInFirestore(firestore: fakeFirestore, uid: writerUser1Uid, nickname: 'Writer One');
    await createWriterUserInFirestore(firestore: fakeFirestore, uid: writerUser2Uid, nickname: 'Writer Two');

    // Create feeds, alternating writers for variety
    await createFeedInFirestore(firestore: fakeFirestore, feedId: 'feed1', writerUid: writerUser1Uid, createdAt: Timestamp(100,0));
    await createFeedInFirestore(firestore: fakeFirestore, feedId: 'feed2', writerUid: writerUser2Uid, createdAt: Timestamp(200,0));
    await createFeedInFirestore(firestore: fakeFirestore, feedId: 'feed3', writerUid: writerUser1Uid, createdAt: Timestamp(300,0));
    await createFeedInFirestore(firestore: fakeFirestore, feedId: 'feed4', writerUid: writerUser2Uid, createdAt: Timestamp(400,0));
    await createFeedInFirestore(firestore: fakeFirestore, feedId: 'feed5', writerUid: writerUser1Uid, createdAt: Timestamp(500,0)); // Extra feed not initially liked

    // Create the main test user with their list of liked feeds
    await createUserWithLikesInFirestore(
      firestore: fakeFirestore,
      uid: testUserUid,
      likedFeedIds: initialLikedFeedIds, // Likes feed1, feed2, feed3, feed4
    );
  });

  group('getLikeList method', () {
    test('Test Case 1.1: Initial load with several liked feeds', () async {
      // --- ARRANGE ---
      // Firestore is set up in `setUp`

      // --- ACT ---
      final List<FeedModel> likedFeeds = await likeRepository.getLikeList(
        myUid: testUserUid,
        likeLength: 2, // Requesting 2 feeds
        feedId: null,    // Initial load, so feedId is null
      );

      // --- ASSERT ---
      expect(likedFeeds.length, 2, reason: "Should return 2 feeds as per likeLength");

      // Verify feed IDs (order matters, should be first 2 from user's feedLikeList)
      expect(likedFeeds[0].feedId, 'feed1', reason: "First feed should be feed1");
      expect(likedFeeds[1].feedId, 'feed2', reason: "Second feed should be feed2");

      // Verify writer population
      expect(likedFeeds[0].writer, isA<UserModel>(), reason: "Feed1 writer should be populated");
      expect(likedFeeds[0].writer.uid, writerUser1Uid, reason: "Feed1 writer UID should be correct");
      expect(likedFeeds[0].writer.nickname, 'Writer One', reason: "Feed1 writer nickname should be correct");

      expect(likedFeeds[1].writer, isA<UserModel>(), reason: "Feed2 writer should be populated");
      expect(likedFeeds[1].writer.uid, writerUser2Uid, reason: "Feed2 writer UID should be correct");
      expect(likedFeeds[1].writer.nickname, 'Writer Two', reason: "Feed2 writer nickname should be correct");
    });

    test('Test Case 1.2: Paginated load', () async {
      // --- ARRANGE ---
      // Firestore is set up in `setUp`. User `testUserUid` likes ['feed1', 'feed2', 'feed3', 'feed4'].
      // We want to fetch the page starting *after* 'feed1'.

      // --- ACT ---
      final List<FeedModel> likedFeedsPage2 = await likeRepository.getLikeList(
        myUid: testUserUid,
        likeLength: 2,     // Requesting next 2 feeds
        feedId: 'feed1',   // ID of the last feed from the previous page
      );

      // --- ASSERT ---
      expect(likedFeedsPage2.length, 2, reason: "Should return 2 feeds for the paginated load");

      // Verify feed IDs (should be feed2, feed3 from user's feedLikeList)
      expect(likedFeedsPage2[0].feedId, 'feed2', reason: "First feed on page 2 should be feed2");
      expect(likedFeedsPage2[1].feedId, 'feed3', reason: "Second feed on page 2 should be feed3");

      // Verify writer population
      expect(likedFeedsPage2[0].writer.uid, writerUser2Uid, reason: "Feed2 writer UID");
      expect(likedFeedsPage2[0].writer.nickname, 'Writer Two', reason: "Feed2 writer nickname");

      expect(likedFeedsPage2[1].writer.uid, writerUser1Uid, reason: "Feed3 writer UID");
      expect(likedFeedsPage2[1].writer.nickname, 'Writer One', reason: "Feed3 writer nickname");
    });

    test('Test Case 1.3: User has no liked feeds', () async {
      // --- ARRANGE ---
      const String emptyLikesUserUid = 'emptyLikesUserUid';
      await createUserWithLikesInFirestore(
        firestore: fakeFirestore,
        uid: emptyLikesUserUid,
        likedFeedIds: [], // Empty list of liked feeds
      );

      // --- ACT ---
      final List<FeedModel> likedFeeds = await likeRepository.getLikeList(
        myUid: emptyLikesUserUid,
        likeLength: 5,
        feedId: null,
      );

      // --- ASSERT ---
      expect(likedFeeds.isEmpty, isTrue, reason: "Returned list should be empty for a user with no liked feeds");
    });

    test('Test Case 1.4: Requesting more feeds than available after pagination', () async {
      // --- ARRANGE ---
      // User `testUserUid` likes ['feed1', 'feed2', 'feed3', 'feed4'] as per setUp.
      // Let's modify this user for this specific test to have only 3 liked feeds.
      const String userWithThreeLikesUid = 'userWithThreeLikes';
      final List<String> threeLikedFeedIds = ['feed1', 'feed2', 'feed3'];
      await createUserWithLikesInFirestore(
        firestore: fakeFirestore,
        uid: userWithThreeLikesUid,
        likedFeedIds: threeLikedFeedIds,
      );
      // Ensure these feeds exist (they do from global setUp, but good to be explicit if test were standalone)

      // --- ACT & ASSERT ---
      // First call: Paginate after 'feed1', request 2. Should get 'feed2', 'feed3'.
      List<FeedModel> page1 = await likeRepository.getLikeList(
        myUid: userWithThreeLikesUid,
        likeLength: 2,
        feedId: 'feed1',
      );
      expect(page1.length, 2, reason: "Page 1 should return 2 feeds ('feed2', 'feed3')");
      expect(page1[0].feedId, 'feed2');
      expect(page1[1].feedId, 'feed3');

      // Second call: Paginate after 'feed2', request 2. Should get 'feed3' (only 1 remaining).
      List<FeedModel> page2 = await likeRepository.getLikeList(
        myUid: userWithThreeLikesUid,
        likeLength: 2,
        feedId: 'feed2',
      );
      expect(page2.length, 1, reason: "Page 2 should return 1 feed ('feed3') as it's the last one");
      expect(page2[0].feedId, 'feed3');

      // Third call: Paginate after 'feed3', request 2. Should get [] (no more feeds).
       List<FeedModel> page3 = await likeRepository.getLikeList(
        myUid: userWithThreeLikesUid,
        likeLength: 2,
        feedId: 'feed3',
      );
      expect(page3.isEmpty, isTrue, reason: "Page 3 should return an empty list as no feeds remain after 'feed3'");
    });
  });
}
