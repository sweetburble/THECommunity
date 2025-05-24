import 'package:THECommu/data_model/user_model.dart';
import 'package:THECommu/repository/friend_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper function to create user data in Firestore
Future<void> createTestUserInFirestore({
  required FakeFirebaseFirestore firestore,
  required String uid,
  String? nickname,
  String? email,
  String? profileImage,
  List<String> following = const [], // Store UIDs
  List<String> followers = const [], // Store UIDs
  int feedCount = 0,
  List<String> feedList = const [],
  List<String> feedLikeList = const [],

}) async {
  // Convert UIDs to DocumentReferences for Firestore storage if your model expects that for following/followers
  // However, the prompt implies UIDs are stored: "The lists in Firestore usually store UIDs."
  // If they store DocumentReferences, this helper and the tests need adjustment.
  // For this implementation, assuming UIDs are stored directly in the arrays as strings.
  // If DocumentReferences are actually stored, the setup for following/followers would be:
  // List<DocumentReference> followingRefs = following.map((id) => firestore.collection('users').doc(id)).toList();
  // List<DocumentReference> followerRefs = followers.map((id) => firestore.collection('users').doc(id)).toList();

  await firestore.collection('users').doc(uid).set({
    'uid': uid,
    'nickname': nickname ?? 'Nickname_$uid',
    'email': email ?? '$uid@example.com',
    'profileImage': profileImage ?? 'http://example.com/profile/$uid.png',
    'following': following,
    'followers': followers,
    'followingCount': following.length,
    'followerCount': followers.length,
    'feedCount': feedCount,
    'feedList': feedList,
    'feedLikeList': feedLikeList,
    // Add any other fields UserModel.fromJson expects
  });
}


void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late FriendRepository friendRepository;

  const String currentUserUid = 'currentUserUid';
  const String friend1Uid = 'friend1Uid'; // Mutual friend
  const String friend2Uid = 'friend2Uid'; // Follows current user, not followed back by current user
  const String friend3Uid = 'friend3Uid'; // Followed by current user, doesn't follow back
  const String otherUser1Uid = 'otherUser1';
  const String otherUser2Uid = 'otherUser2';


  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    // Mock current user for FirebaseAuth.instance.currentUser
    final mockUser = MockUser(uid: currentUserUid);
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    friendRepository = FriendRepository(
      firebaseAuth: mockAuth,
      firebaseFirestore: fakeFirestore,
    );
  });

  group('getFriendList method', () {
    test('Test Case 1.1: User has mutual friends', () async {
      // --- ARRANGE ---
      // currentUserUid is already set in mockAuth

      // Initialize Firestore with user documents
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: currentUserUid,
        following: [friend1Uid, friend3Uid], // Follows friend1 and friend3
        followers: [friend1Uid, friend2Uid], // Followed by friend1 and friend2
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: friend1Uid,
        nickname: 'FriendOne',
        following: [currentUserUid], // friend1 follows currentUserUid back
        followers: [currentUserUid], // friend1 is followed by currentUserUid back
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: friend2Uid,
        nickname: 'FriendTwo',
        following: [], // friend2 does not follow currentUserUid
        followers: [currentUserUid], // friend2 is followed by currentUserUid
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: friend3Uid,
        nickname: 'FriendThree',
        following: [], // friend3 follows others, but not necessarily currentUserUid
        followers: [currentUserUid], // friend3 is followed by currentUserUid, but does not follow back
      );
       // Add one more user to make sure only mutual ones are picked
      await createTestUserInFirestore(firestore: fakeFirestore, uid: 'randomUser', followers: ['anotherRandom']);


      // --- ACT ---
      final List<UserModel> friendList = await friendRepository.getFriendList();

      // --- ASSERT ---
      expect(friendList.length, 1, reason: "Should only contain mutual friend (friend1Uid)");
      expect(friendList.first.uid, friend1Uid, reason: "The mutual friend should be friend1Uid");
      expect(friendList.first.nickname, 'FriendOne', reason: "Friend1's nickname should be correctly populated");
    });

    test('Test Case 1.2: User has no mutual friends', () async {
      // --- ARRANGE ---
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: currentUserUid,
        following: [otherUser1Uid], // currentUser follows otherUser1
        followers: [otherUser2Uid], // currentUser is followed by otherUser2
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: otherUser1Uid,
        nickname: 'OtherUserOne',
        followers: [currentUserUid], // otherUser1 is followed by currentUser, but does not follow back
        following: [],
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: otherUser2Uid,
        nickname: 'OtherUserTwo',
        following: [currentUserUid], // otherUser2 follows currentUser, but is not followed back
        followers: [],
      );

      // --- ACT ---
      final List<UserModel> friendList = await friendRepository.getFriendList();

      // --- ASSERT ---
      expect(friendList.isEmpty, isTrue, reason: "Friend list should be empty as there are no mutual friends");
    });
  });

  group('getFriendMap method', () {
    test('Test Case 2.1: User has mutual friends (same setup as 1.1)', () async {
      // --- ARRANGE ---
      // (currentUserUid is already set in mockAuth via setUp)
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: currentUserUid,
        following: [friend1Uid, friend3Uid],
        followers: [friend1Uid, friend2Uid],
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: friend1Uid,
        nickname: 'FriendOneMap', // Use different nickname to ensure it's fetched correctly for this test
        following: [currentUserUid],
        followers: [currentUserUid],
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: friend2Uid,
        nickname: 'FriendTwoMap',
        followers: [currentUserUid],
        following: [],
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: friend3Uid,
        nickname: 'FriendThreeMap',
        following: [currentUserUid], // Current user follows friend3
        followers: [],                // But friend3 does not follow current user
      );
       await createTestUserInFirestore(firestore: fakeFirestore, uid: 'randomUserMap', followers: ['anotherRandomMap']);


      // --- ACT ---
      final Map<String, UserModel> friendMap = await friendRepository.getFriendMap();

      // --- ASSERT ---
      expect(friendMap.length, 1, reason: "Friend map should contain one entry for the mutual friend");
      expect(friendMap.containsKey(friend1Uid), isTrue, reason: "Map key should be friend1Uid");
      
      final UserModel? friend1Model = friendMap[friend1Uid];
      expect(friend1Model, isNotNull, reason: "UserModel for friend1Uid should not be null");
      expect(friend1Model!.uid, friend1Uid, reason: "Friend1's UID in UserModel is correct");
      expect(friend1Model.nickname, 'FriendOneMap', reason: "Friend1's nickname in UserModel is correct");
    });

    test('Test Case 2.2: User has no mutual friends (same setup as 1.2)', () async {
      // --- ARRANGE ---
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: currentUserUid,
        following: [otherUser1Uid],
        followers: [otherUser2Uid],
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: otherUser1Uid,
        nickname: 'OtherUserOneMap',
        followers: [currentUserUid],
        following: [],
      );
      await createTestUserInFirestore(
        firestore: fakeFirestore,
        uid: otherUser2Uid,
        nickname: 'OtherUserTwoMap',
        following: [currentUserUid],
        followers: [],
      );

      // --- ACT ---
      final Map<String, UserModel> friendMap = await friendRepository.getFriendMap();

      // --- ASSERT ---
      expect(friendMap.isEmpty, isTrue, reason: "Friend map should be empty as there are no mutual friends");
    });
  });
}
