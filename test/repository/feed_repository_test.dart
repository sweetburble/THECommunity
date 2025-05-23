// ignore_for_file: prefer_const_constructors, unused_local_variable

import 'dart:io';
import 'dart:typed_data';

import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data_model/feed_model.dart';
import 'package:THECommu/data_model/user_model.dart';
import 'package:THECommu/repository/feed_repository.dart';
import 'package:THECommu/repository/gemini_repository.dart'; // Assuming this is the correct path
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Aliasing to avoid conflict with mock
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart' as auth_mocks;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_remote_config_platform_interface/firebase_remote_config_platform_interface.dart';


// Mock Classes
class MockFirebaseAuthInternal extends Mock implements fb_auth.FirebaseAuth {} // For instance mocking if needed
class MockUser extends Mock implements fb_auth.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;


  MockUser({this.uid = 'test_user_uid', this.email = 'test@example.com', this.displayName = 'Test User'});
}

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}
class MockGeminiRepository extends Mock implements GeminiRepository {}
class MockTaskSnapshot extends Mock implements fb_storage.TaskSnapshot {}
class MockStorageReference extends Mock implements fb_storage.Reference {}
class MockFile extends Mock implements File {
  @override
  final String path;
  MockFile(this.path);
}

// Fallbacks for any() matchers
void registerFallbacks() {
  registerFallbackValue(MockFile('dummy_path.jpg'));
  registerFallbackValue(MockStorageReference());
  registerFallbackValue(Uint8List(0));
  registerFallbackValue(fb_auth.UserCredential); // For UserCredential if needed
  registerFallbackValue(fb_storage.SettableMetadata()); // For putFile/putData metadata
  registerFallbackValue(Duration(seconds: 1)); // For timeout if used
}


// Helper to set up a TestFirebaseRemoteConfig instance
void setupMockRemoteConfig(String key, String value) {
  // Initialize the binding if necessary (usually done in test_helper.dart or main test file)
  TestFirebaseRemoteConfigPlatform.instance = TestFirebaseRemoteConfigPlatform();
  TestFirebaseRemoteConfigPlatform.instance.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1),
    minimumFetchInterval: const Duration(hours: 1),
  ));
  TestFirebaseRemoteConfigPlatform.instance.setDefaults(const <String, dynamic>{
    key: value, // Default value if not fetched
  });
   TestFirebaseRemoteConfigPlatform.instance.setRemoteConfig(const <String, dynamic>{
    key: value, // Simulate fetched value
  });
}


void main() {
  late FeedRepository feedRepository;
  late MockFirebaseStorage mockFirebaseStorage;
  late FakeFirebaseFirestore fakeFirebaseFirestore;
  late auth_mocks.MockFirebaseAuth mockFirebaseAuthInstance; // For FirebaseAuth.instance
  late MockGeminiRepository mockGeminiRepository; // This will be tricky

  const String testMyUid = 'test_user_uid';
  const String dummyApiKey = 'dummy_api_key_from_remote_config';
  final mockUser = MockUser(uid: testMyUid);

  setUpAll(() {
    registerFallbacks();
    // Setup for FirebaseRemoteConfig.instance
    // This uses the platform interface to inject test values.
    // This needs to be called before FeedRepository tries to access FirebaseRemoteConfig.instance
    setupMockRemoteConfig('gemini_api_key', dummyApiKey);
  });

  setUp(() {
    mockFirebaseStorage = MockFirebaseStorage();
    fakeFirebaseFirestore = FakeFirebaseFirestore();
    // This mock will be used for FirebaseAuth.instance
    mockFirebaseAuthInstance = auth_mocks.MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    mockGeminiRepository = MockGeminiRepository(); // Instance to mock methods on

    // Instantiate FeedRepository with mocked dependencies
    // IMPORTANT: This assumes FeedRepository is refactored to take GeminiRepository
    // or uses a factory that can be overridden.
    // If GeminiRepository is new GeminiRepository() inside uploadFeed, this mockGeminiRepository
    // instance won't be used unless we can somehow intercept that creation.
    // For this subtask, we assume this mockGeminiRepository can be made effective.
    feedRepository = FeedRepository(
      firebaseStorage: mockFirebaseStorage,
      firebaseFirestore: fakeFirebaseFirestore,
      // The following are not in constructor per prompt, so FeedRepository uses static instances
      // firebaseAuth: mockFirebaseAuthInstance, // If it were injected
      // remoteConfig: mockRemoteConfig, // If it were injected
      // geminiRepository: mockGeminiRepository, // If it were injected
    );

    // Since GeminiRepository is instantiated inside uploadFeed, and we can't easily mock
    // constructors with mocktail, we rely on the hope that mocktail's `when` might
    // intercept calls on *any* instance if set up correctly, or this test highlights
    // the need for refactoring FeedRepository to inject GeminiRepository.
    // For now, we will mock the `requestSummary` on our created `mockGeminiRepository`.
    // This will only work if FeedRepository somehow uses this specific instance.
    // A more robust way without refactoring FeedRepository is not straightforward.
    // The instructions say: "assume GeminiRepository().requestSummary() can be mocked".
    // This implies we might not need to mock the constructor.
    // This is a common challenge. For now, we will proceed with mocking `mockGeminiRepository.requestSummary`.
    // If the test fails because the wrong GeminiRepository instance is called, it proves refactoring is needed.
  });

  group('uploadFeed method', () {
    final List<String> testImagePaths = ['path/to/image1.jpg', 'path/to/image2.jpg'];
    final List<MockFile> testImageFiles = testImagePaths.map((path) => MockFile(path)).toList();
    const String testTitle = 'Test Feed Title';
    const String testContent = 'Test feed content.';
    const String dummySummary = 'This is a Gemini summary.';
    final List<String> dummyImageUrls = ['http://example.com/image1.jpg', 'http://example.com/image2.jpg'];

    final userModelData = UserModel(
      uid: testMyUid,
      email: 'user@example.com',
      nickname: 'TestUser',
      profileImage: 'http://example.com/profile.png',
    ).toJson();


    test('Test Case 1.1: Successful feed upload', () async {
      // --- ARRANGE ---
      // User is authenticated (done in global mockFirebaseAuthInstance via mockUser)
      when(() => mockFirebaseAuthInstance.currentUser).thenReturn(mockUser);


      // Mock FirebaseStorage for image uploads
      for (int i = 0; i < testImageFiles.length; i++) {
        final imageFile = testImageFiles[i];
        final imageUrl = dummyImageUrls[i];
        final mockStorageRef = MockStorageReference();
        final mockUploadTaskRef = MockStorageReference(); // Ref for upload task path
        final mockTaskSnapshot = MockTaskSnapshot();

        // Mock ref() path chaining
        when(() => mockFirebaseStorage.ref()).thenReturn(mockStorageRef);
        when(() => mockStorageRef.child('feed_images')).thenReturn(mockStorageRef);
        when(() => mockStorageRef.child(testMyUid)).thenReturn(mockStorageRef);
        // Extract filename from path for child(filename)
        final filename = imageFile.path.split('/').last;
        when(() => mockStorageRef.child(filename)).thenReturn(mockUploadTaskRef);

        // Mock putFile and getDownloadURL
        when(() => mockUploadTaskRef.putFile(imageFile, any())).thenAnswer((_) async => mockTaskSnapshot);
        when(() => mockTaskSnapshot.ref).thenReturn(mockUploadTaskRef);
        when(() => mockUploadTaskRef.getDownloadURL()).thenAnswer((_) async => imageUrl);
      }

      // Mock GeminiRepository.requestSummary()
      // This is the tricky part. We assume that FeedRepository will somehow use an instance
      // of GeminiRepository whose `requestSummary` method calls can be intercepted by this mock.
      // This requires FeedRepository to be designed for testability (e.g., injection, factory).
      // If FeedRepository creates `new GeminiRepository()` directly, this mock won't work as expected
      // unless mocktail has advanced features for this or we use a different mocking strategy.
      // For now, we proceed with the assumption it can be mocked as per prompt.
      // The API key for Gemini is mocked via TestFirebaseRemoteConfigPlatform.
      when(() => mockGeminiRepository.requestSummary(testTitle, testContent))
          .thenAnswer((_) async => dummySummary);
      
      // To make the above mock work IF GeminiRepository is directly instantiated,
      // we would need to ensure FeedRepository uses *our* mockGeminiRepository.
      // This is often done by injecting the dependency. If not, this specific `when` might not be hit.
      // This test setup implicitly assumes `FeedRepository` is refactored or uses a mechanism
      // (like a service locator or factory) that allows `mockGeminiRepository` to be used.
      // For the purpose of this task, we will assume the FeedRepository uses a GeminiRepository
      // instance that this mock can influence.


      // Mock Firestore: Add user data to FakeFirebaseFirestore
      await fakeFirebaseFirestore.collection('users').doc(testMyUid).set(userModelData);

      // --- ACT ---
      // Call uploadFeed. We need to pass the mockFirebaseAuthInstance to the repository
      // if it expects it, or ensure it uses the static mock.
      // The prompt implies FeedRepository uses FirebaseAuth.instance.
      // Our mockFirebaseAuthInstance is set up to be the one returned by FirebaseAuth.instance.
      final FeedModel result = await feedRepository.uploadFeed(
        auth: mockFirebaseAuthInstance, // Pass the mock auth instance
        geminiRepo: mockGeminiRepository, // Pass the mock gemini repo instance
        imagePaths: testImagePaths, // Pass paths, FeedRepository will create File objects
        title: testTitle,
        content: testContent,
      );

      // --- ASSERT ---
      // Verify FirebaseAuth.instance.currentUser was called
      verify(() => mockFirebaseAuthInstance.currentUser).called(1);

      // Verify FirebaseRemoteConfig.instance.getString was called (implicitly by GeminiRepository or FeedRepository)
      // This is hard to verify directly if it's deep inside. We trust TestFirebaseRemoteConfigPlatform setup.

      // Verify FirebaseStorage calls
      for (int i = 0; i < testImageFiles.length; i++) {
        final imageFile = testImageFiles[i];
        final filename = imageFile.path.split('/').last;
        // verify(() => mockFirebaseStorage.ref().child('feed_images').child(testMyUid).child(filename).putFile(imageFile, any())).called(1);
        // verify(() => mockFirebaseStorage.ref().child('feed_images').child(testMyUid).child(filename).getDownloadURL()).called(1);
        // More robust: verify putFile and getDownloadURL on the specific refs
      }
       // Verify overall storage interaction (less precise but useful)
      verify(() => mockFirebaseStorage.ref()).called(testImagePaths.length);


      // Verify GeminiRepository.requestSummary call
      verify(() => mockGeminiRepository.requestSummary(testTitle, testContent)).called(1);

      // Verify Firestore operations (FakeFirebaseFirestore handles batch writes internally)
      final feedDoc = await fakeFirebaseFirestore.collection('feeds').doc(result.feedId).get();
      expect(feedDoc.exists, isTrue);
      expect(feedDoc.data()?['title'], testTitle);
      expect(feedDoc.data()?['content'], testContent);
      expect(feedDoc.data()?['summary'], dummySummary);
      expect(feedDoc.data()?['imageUrls'], orderedEquals(dummyImageUrls));
      expect(feedDoc.data()?['uid'], testMyUid);
      expect(feedDoc.data()?['writer'], fakeFirebaseFirestore.collection('users').doc(testMyUid));

      final userDoc = await fakeFirebaseFirestore.collection('users').doc(testMyUid).get();
      expect(userDoc.data()?['feedCount'], 1);
      expect(userDoc.data()?['feedList'], contains(result.feedId));

      // Verify returned FeedModel
      expect(result.title, testTitle);
      expect(result.content, testContent);
      expect(result.summary, dummySummary);
      expect(result.imageUrls, orderedEquals(dummyImageUrls));
      expect(result.uid, testMyUid);
      expect(result.writer.uid, testMyUid);
      expect(result.writer.nickname, userModelData['nickname']);
    });

    test('Test Case 1.2: Attempted upload when user is unauthenticated', () async {
      // --- ARRANGE ---
      // Set current user to null for this test
      final unauthedMockAuth = auth_mocks.MockFirebaseAuth(signedIn: false);
      when(() => unauthedMockAuth.currentUser).thenReturn(null);

      // --- ACT & ASSERT ---
      await expectLater(
        feedRepository.uploadFeed(
          auth: unauthedMockAuth, // Pass the unauthenticated mock
          geminiRepo: mockGeminiRepository, // Still need to pass it
          imagePaths: testImagePaths,
          title: testTitle,
          content: testContent,
        ),
        throwsA(isA<CustomException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );

      verify(() => unauthedMockAuth.currentUser).called(1);
      verifyNever(() => mockFirebaseStorage.ref());
      verifyNever(() => mockGeminiRepository.requestSummary(any(), any()));
    });
  });

  group('deleteFeed method', () {
    final String feedOwnerUid = testMyUid; // Feed owned by our main test user
    final String likerUid = 'liker_user_uid';
    final String feedId = 'feed_to_delete_id';

    final feedOwnerUserModel = UserModel(uid: feedOwnerUid, email: 'owner@e.com', nickname: 'Owner', feedCount: 1, feedList: [feedId]);
    final likerUserModel = UserModel(uid: likerUid, email: 'liker@e.com', nickname: 'Liker', feedLikeList: [feedId]);

    final feedModelToDelete = FeedModel(
      feedId: feedId,
      uid: feedOwnerUid,
      writer: feedOwnerUserModel, // Populated writer
      title: 'Feed To Delete',
      content: 'This feed will be deleted.',
      imageUrls: ['http://example.com/delete_image1.jpg', 'http://example.com/delete_image2.jpg'],
      summary: 'Delete summary',
      likeCount: 1,
      commentCount: 1, // Has one comment
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      whoLiked: [fakeFirebaseFirestore.collection('users').doc(likerUid)], // Liked by likerUid
      isLiked: false,
    );

    setUp(() async {
      // Populate Firestore with data for deletion
      await fakeFirebaseFirestore.collection('users').doc(feedOwnerUid).set(feedOwnerUserModel.toJson());
      await fakeFirebaseFirestore.collection('users').doc(likerUid).set(likerUserModel.toJson());
      await fakeFirebaseFirestore.collection('feeds').doc(feedId).set(feedModelToDelete.toFullJson(fakeFirebaseFirestore)); // Use toFullJson to store refs
      await fakeFirebaseFirestore.collection('feeds').doc(feedId).collection('comments').doc('comment1').set({'text': 'A comment to delete'});
    });

    test('Test Case 2.1: Successful feed deletion', () async {
      // --- ARRANGE ---
      // Mock FirebaseStorage.refFromURL().delete() for each image
      for (String url in feedModelToDelete.imageUrls) {
        final mockStorageRef = MockStorageReference();
        when(() => mockFirebaseStorage.refFromURL(url)).thenReturn(mockStorageRef);
        when(() => mockStorageRef.delete()).thenAnswer((_) async {});
      }

      // --- ACT ---
      await feedRepository.deleteFeed(feedModel: feedModelToDelete);

      // --- ASSERT ---
      // Verify FirebaseStorage deletions
      for (String url in feedModelToDelete.imageUrls) {
        verify(() => mockFirebaseStorage.refFromURL(url).delete()).called(1);
      }

      // Verify Firestore state after deletion (FakeFirebaseFirestore handles batch writes)
      final feedDoc = await fakeFirebaseFirestore.collection('feeds').doc(feedId).get();
      expect(feedDoc.exists, isFalse, reason: "Feed document should be deleted");

      final commentsSnapshot = await fakeFirebaseFirestore.collection('feeds').doc(feedId).collection('comments').get();
      expect(commentsSnapshot.docs.isEmpty, isTrue, reason: "Comments should be deleted");

      final feedOwnerDoc = await fakeFirebaseFirestore.collection('users').doc(feedOwnerUid).get();
      expect(feedOwnerDoc.data()?['feedCount'], 0, reason: "Owner's feedCount should be decremented");
      expect(feedOwnerDoc.data()?['feedList'], isNot(contains(feedId)), reason: "feedId should be removed from owner's feedList");

      final likerDoc = await fakeFirebaseFirestore.collection('users').doc(likerUid).get();
      expect(likerDoc.data()?['feedLikeList'], isNot(contains(feedId)), reason: "feedId should be removed from liker's feedLikeList");
    });
  });

   group('getFeedList method', () {
    final writer1 = UserModel(uid: 'writer1_uid', email: 'w1@e.com', nickname: 'Writer1');
    final writer2 = UserModel(uid: 'writer2_uid', email: 'w2@e.com', nickname: 'Writer2');

    final feed1 = FeedModel(
      feedId: 'feed1_id', uid: writer1.uid, writer: writer1, title: 'Feed 1', content: 'Content 1',
      createdAt: Timestamp.fromMillisecondsSinceEpoch(1000), summary: '', imageUrls: []
    );
    final feed2 = FeedModel(
      feedId: 'feed2_id', uid: writer2.uid, writer: writer2, title: 'Feed 2', content: 'Content 2',
      createdAt: Timestamp.fromMillisecondsSinceEpoch(2000), summary: '', imageUrls: []
    );

    setUp(() async {
      // Populate FakeFirebaseFirestore
      await fakeFirebaseFirestore.collection('users').doc(writer1.uid).set(writer1.toJson());
      await fakeFirebaseFirestore.collection('users').doc(writer2.uid).set(writer2.toJson());

      // Store feeds with DocumentReferences to writers
      await fakeFirebaseFirestore.collection('feeds').doc(feed1.feedId)
          .set(feed1.toFullJson(fakeFirebaseFirestore));
      await fakeFirebaseFirestore.collection('feeds').doc(feed2.feedId)
          .set(feed2.toFullJson(fakeFirebaseFirestore));
    });

    test('Test Case 3.1: Fetching a list of feeds (general case, no specific UID)', () async {
      // --- ACT ---
      final results = await feedRepository.getFeedList();

      // --- ASSERT ---
      expect(results, isA<List<FeedModel>>());
      expect(results.length, 2);

      // Feeds are ordered by createdAt descending by default in FeedRepository
      final resultFeed2 = results.firstWhere((f) => f.feedId == feed2.feedId);
      final resultFeed1 = results.firstWhere((f) => f.feedId == feed1.feedId);

      expect(resultFeed2.writer.uid, writer2.uid);
      expect(resultFeed2.writer.nickname, writer2.nickname);
      expect(resultFeed1.writer.uid, writer1.uid);
      expect(resultFeed1.writer.nickname, writer1.nickname);
    });
   });
}

// Extension on FeedModel to simulate storing DocumentReference for writer
// This is how it might be stored in Firestore.
extension FeedModelFirestore on FeedModel {
  Map<String, dynamic> toFullJson(FirebaseFirestore firestore) {
    final json = toJson();
    json['writer'] = firestore.collection('users').doc(uid); // uid is writer's uid
    return json;
  }
}

// Extension on FeedRepository to allow injecting mocks for static/global instances
// This is a way to handle the GeminiRepository and FirebaseAuth.instance if not refactored.
// Requires FeedRepository to be structured to accept these, e.g. by passing them as parameters to methods.
// This is what I've done by adding `auth` and `geminiRepo` parameters to `uploadFeed` in the test.
// If the actual `FeedRepository.uploadFeed` does not take these, these tests will need adjustment
// or the `FeedRepository` needs to be refactored for testability.
// For example:
// Future<FeedModel> uploadFeed({
//   required List<String> imagePaths,
//   required String title,
//   required String content,
//   fb_auth.FirebaseAuth? auth, // Optional for testing
//   GeminiRepository? geminiRepo, // Optional for testing
// }) async {
//   final firebaseAuth = auth ?? fb_auth.FirebaseAuth.instance;
//   final actualGeminiRepo = geminiRepo ?? GeminiRepository(apiKey: /* ... get from remote config ... */);
//   // ... rest of the code
// }
