import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/repository/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserRepository userRepository;

  const String userAId = 'userA';
  const String userBId = 'userB';

  // Helper function to get a user document reference
  DocumentReference<Map<String, dynamic>> userDocRef(String uid) {
    return fakeFirestore.collection('users').doc(uid);
  }

  // Helper function to create initial user data for Firestore
  // Ensures all fields expected by UserModel.fromJson are present
  Map<String, dynamic> createFirestoreUserData({
    required String uid,
    required String email,
    required String nickname,
    String? profileImage,
    List<String>? following,
    List<String>? followers,
    List<String>?
        feedLikeList, // Assuming feedLikeList stores feed IDs (strings)
    int feedCount = 0,
  }) {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'profileImage': profileImage ?? 'http://example.com/$uid.png',
      'following': following ?? [],
      'followers': followers ?? [],
      'feedLikeList': feedLikeList ?? [],
      'feedCount': feedCount,
      // Ensure all fields required by UserModel.fromJson are present
      // Add any other default fields if necessary.
    };
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userRepository = UserRepository(fireStore: fakeFirestore);
  });

  group('followUser method', () {
    test('Test Case 1.1: User A follows User B', () async {
      // --- ARRANGE ---
      await userDocRef(userAId).set(createFirestoreUserData(
        uid: userAId,
        email: 'usera@example.com',
        nickname: 'UserA',
      ));
      await userDocRef(userBId).set(createFirestoreUserData(
        uid: userBId,
        email: 'userb@example.com',
        nickname: 'UserB',
      ));

      // --- ACT ---
      final UserModel resultUserB =
          await userRepository.followUser(myUid: userAId, followId: userBId);

      // --- ASSERT ---
      // Verify userA's document in Firestore
      final userADoc = await userDocRef(userAId).get();
      expect(userADoc.exists, isTrue);
      final userAData = userADoc.data()!;
      expect(userAData['following'], contains(userBId));

      // Verify userB's document in Firestore
      final userBDoc = await userDocRef(userBId).get();
      expect(userBDoc.exists, isTrue);
      final userBData = userBDoc.data()!;
      expect(userBData['followers'], contains(userAId));

      // Verify returned UserModel (should be UserB's updated model)
      expect(resultUserB.uid, userBId);
      expect(resultUserB.nickname, 'UserB');
      // To check `isFollowing`, UserRepository.followUser would need to populate it
      // based on whether myUid is in the updated followers list of UserB.
      // This typically means the UserModel.fromJson needs to handle this logic or
      // the repository method should explicitly set it.
    });

    test('Test Case 1.2: User A unfollows User B', () async {
      // --- ARRANGE ---
      await userDocRef(userAId).set(createFirestoreUserData(
        uid: userAId,
        email: 'usera@example.com',
        nickname: 'UserA',
        following: [userBId], // UserA already follows UserB
      ));
      await userDocRef(userBId).set(createFirestoreUserData(
        uid: userBId,
        email: 'userb@example.com',
        nickname: 'UserB',
        followers: [userAId], // UserB is already followed by UserA
      ));

      // --- ACT ---
      final UserModel resultUserB =
          await userRepository.followUser(myUid: userAId, followId: userBId);

      // --- ASSERT ---
      // Verify userA's document
      final userADoc = await userDocRef(userAId).get();
      expect(userADoc.exists, isTrue);
      final userAData = userADoc.data()!;
      expect(userAData['following'], isNot(contains(userBId)));

      // Verify userB's document
      final userBDoc = await userDocRef(userBId).get();
      expect(userBDoc.exists, isTrue);
      final userBData = userBDoc.data()!;
      expect(userBData['followers'], isNot(contains(userAId)));

      // Verify returned UserModel
      expect(resultUserB.uid, userBId);
      expect(resultUserB.nickname, 'UserB');
    });
  });

  group('getProfile method', () {
    const String existingUserId = 'user123';
    final Map<String, dynamic> firestoreExistingUserData =
        createFirestoreUserData(
      uid: existingUserId,
      email: 'user123@example.com',
      nickname: 'User123',
      profileImage: 'http://example.com/user123.png',
      feedCount: 3,
      feedLikeList: ['feedLiked1'],
    );

    test('Test Case 2.1: Successfully fetching an existing user\'s profile',
        () async {
      // --- ARRANGE ---
      await userDocRef(existingUserId).set(firestoreExistingUserData);

      // --- ACT ---
      final UserModel resultUser =
          await userRepository.getProfile(uid: existingUserId);

      // --- ASSERT ---
      expect(resultUser.uid, existingUserId);
      expect(resultUser.email, firestoreExistingUserData['email']);
      expect(resultUser.nickname, firestoreExistingUserData['nickname']);
      expect(
          resultUser.profileImage, firestoreExistingUserData['profileImage']);
      expect(resultUser.feedCount, firestoreExistingUserData['feedCount']);
      expect(
          resultUser.feedLikeList,
          orderedEquals(
              firestoreExistingUserData['feedLikeList'] as List<String>));
      // isFollowing and isFollowingMe would require additional context (myUid) to be determined,
      // typically not part of a simple getProfile unless that context is provided.
    });

    test('Test Case 2.2: Attempting to fetch a non-existent user\'s profile',
        () async {
      // --- ARRANGE ---
      const String nonExistentUserId = 'nonExistentUser';
      // No data setup for nonExistentUserId, so it won't exist in fakeFirestore.

      // --- ACT & ASSERT ---
      // The current implementation of UserRepository.getProfile directly calls snapshot.data()!
      // fake_cloud_firestore's DocumentSnapshot.data() returns null if the document doesn't exist.
      // The '!' (null-check operator) on a null value will throw a runtime error.
      // This is often a TypeError or a specific "Null check operator used on a null value" error.
      expect(
        () async => await userRepository.getProfile(uid: nonExistentUserId),
        // In Dart, calling `!` on null usually throws a `TypeError` or a similar `Error`.
        // `throwsA(isA<TypeError>())` or `throwsA(isA<Error>())` are common.
        // Let's be more general with `isA<Error>()` as the exact subtype can vary.
        // If `CustomException` were thrown by the repo, that would be `isA<CustomException>()`.
        throwsA(isA<CustomException>()),
        reason:
            "Fetching a non-existent profile should throw an error due to 'data()!'",
      );
    });
  });
}
