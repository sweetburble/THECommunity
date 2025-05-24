import 'package:THECommu/data_model/user_model.dart';
import 'package:THECommu/repository/search_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper function to create user data in Firestore
Future<void> createTestUserInFirestore({
  required FakeFirebaseFirestore firestore,
  required String uid,
  required String nickname,
  String? email,
  String? profileImage,
  List<String> following = const [],
  List<String> followers = const [],
  int feedCount = 0,
  List<String> feedList = const [],
  List<String> feedLikeList = const [],
}) async {
  await firestore.collection('users').doc(uid).set({
    'uid': uid,
    'nickname': nickname,
    'email': email ?? '$uid@example.com',
    'profileImage': profileImage ?? 'http://example.com/profile/$uid.png',
    'following': following,
    'followers': followers,
    'followingCount': following.length,
    'followerCount': followers.length,
    'feedCount': feedCount,
    'feedList': feedList,
    'feedLikeList': feedLikeList,
    // Ensure all fields required by UserModel.fromJson are present
  });
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late SearchRepository searchRepository;

  // User UIDs and Nicknames for consistent testing
  const String user1Uid = 'user1';
  const String user1Nickname = 'applepie';

  const String user2Uid = 'user2';
  const String user2Nickname = 'applejuice';

  const String user3Uid = 'user3';
  const String user3Nickname = 'apricot';

  const String user4Uid = 'user4';
  const String user4Nickname = 'banana';

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    searchRepository = SearchRepository(firebaseFirestore: fakeFirestore);

    // Pre-populate Firestore with test users
    await createTestUserInFirestore(firestore: fakeFirestore, uid: user1Uid, nickname: user1Nickname);
    await createTestUserInFirestore(firestore: fakeFirestore, uid: user2Uid, nickname: user2Nickname);
    await createTestUserInFirestore(firestore: fakeFirestore, uid: user3Uid, nickname: user3Nickname);
    await createTestUserInFirestore(firestore: fakeFirestore, uid: user4Uid, nickname: user4Nickname);
  });

  group('searchUser method', () {
    test('Test Case 1: Keyword matches multiple users', () async {
      // --- ARRANGE ---
      // Firestore is set up in `setUp`

      // --- ACT ---
      final List<UserModel> results = await searchRepository.searchUser(keyword: "app");

      // --- ASSERT ---
      expect(results.length, 2, reason: "Should find 'applepie' and 'applejuice'");
      
      // Verify the users found (order might vary depending on Firestore's internal indexing with FakeFirebaseFirestore)
      final nicknamesFound = results.map((user) => user.nickname).toList();
      expect(nicknamesFound, containsAll([user1Nickname, user2Nickname]));

      // Verify UserModel population for one of the users
      final applePieUser = results.firstWhere((user) => user.nickname == user1Nickname);
      expect(applePieUser.uid, user1Uid);
      expect(applePieUser.email, '$user1Uid@example.com'); // Default email from helper
    });

    test('Test Case 2: Keyword matches a single user', () async {
      // --- ARRANGE ---
      // Firestore is set up in `setUp`

      // --- ACT ---
      final List<UserModel> results = await searchRepository.searchUser(keyword: "banana");

      // --- ASSERT ---
      expect(results.length, 1, reason: "Should only find 'banana'");
      expect(results.first.nickname, user4Nickname);
      expect(results.first.uid, user4Uid);
    });

    test('Test Case 3: Keyword matches no users', () async {
      // --- ARRANGE ---
      // Firestore is set up in `setUp`

      // --- ACT ---
      final List<UserModel> results = await searchRepository.searchUser(keyword: "xyz");

      // --- ASSERT ---
      expect(results.isEmpty, isTrue, reason: "Should find no users for 'xyz'");
    });

    test('Test Case 4: Case sensitivity', () async {
      // --- ARRANGE ---
      // Firestore is set up in `setUp` with lowercase nicknames

      // --- ACT ---
      final List<UserModel> results = await searchRepository.searchUser(keyword: "Apple");

      // --- ASSERT ---
      // Firestore's string range queries are case-sensitive.
      // 'Apple' is between 'Apolda' and 'Applegate', but not 'apple...'.
      // The range query `isGreaterThanOrEqualTo: "Apple"` and `isLessThanOrEqualTo: "Apple\uf7ff"`
      // will not match lowercase "applepie" or "applejuice".
      expect(results.isEmpty, isTrue, reason: "Search should be case-sensitive; 'Apple' should not match 'apple...'");
    });

    test('Test Case 5: Keyword is a full match to a nickname', () async {
      // --- ARRANGE ---
      // Firestore is set up in `setUp`

      // --- ACT ---
      final List<UserModel> results = await searchRepository.searchUser(keyword: "applepie");

      // --- ASSERT ---
      expect(results.length, 1, reason: "Should find 'applepie' exactly");
      expect(results.first.nickname, user1Nickname);
      expect(results.first.uid, user1Uid);
    });
  });
}
