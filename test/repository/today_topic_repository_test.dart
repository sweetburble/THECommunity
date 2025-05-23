import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data_model/today_topic.dart'; // Assuming this is the correct path
import 'package:THECommu/repository/today_topic_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper function to create today_topic data in Firestore
Future<void> createTodayTopicInFirestore({
  required FakeFirebaseFirestore firestore,
  required String dateId, // e.g., "2023-10-27"
  required String title,
  required String content,
  // Add any other fields that TodayTopic.fromMap expects
  // For example, if it expects a Timestamp for 'createdAt':
  Timestamp? createdAt,
}) async {
  await firestore.collection('today_topic').doc(dateId).set({
    'title': title,
    'content': content,
    'createdAt': createdAt ?? Timestamp.now(), // Example default, adjust if needed
    // Add other fields as per your TodayTopic model
  });
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TodayTopicRepository todayTopicRepository;

  const String testDateExists = "2023-10-27";
  const String testTitle = "Test Topic Title";
  const String testContent = "This is the content for the test topic.";

  const String testDateNotExists = "nonExistentDate";

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    todayTopicRepository = TodayTopicRepository(firebaseFirestore: fakeFirestore);
  });

  group('getTodayTopic method', () {
    test('Test Case 1: Topic exists for the given date string', () async {
      // --- ARRANGE ---
      // Add a document to the 'today_topic' collection
      final testTimestamp = Timestamp.fromDate(DateTime(2023, 10, 27));
      await createTodayTopicInFirestore(
        firestore: fakeFirestore,
        dateId: testDateExists,
        title: testTitle,
        content: testContent,
        createdAt: testTimestamp,
      );

      // --- ACT ---
      final TodayTopic? result = await todayTopicRepository.getTodayTopic(testDateExists);

      // --- ASSERT ---
      expect(result, isNotNull, reason: "TodayTopic object should not be null when data exists");
      expect(result!.title, testTitle, reason: "Title should match the data in Firestore");
      expect(result.content, testContent, reason: "Content should match the data in Firestore");
      // If your TodayTopic model has an ID field that gets populated from the document ID:
      // expect(result.id, testDateExists, reason: "ID should match the document ID");
      // Verify other fields like createdAt if they are part of your model and comparison
      expect(result.createdAt, testTimestamp, reason: "CreatedAt timestamp should match");
    });

    test('Test Case 2: Topic does not exist for the given date string', () async {
      // --- ARRANGE ---
      // Firestore is initialized but does not contain a topic for 'nonExistentDate'
      // (No specific setup needed for this case as fakeFirestore is empty by default for this doc)

      // --- ACT & ASSERT ---
      // The repository catches the error from snapshot.data()! and rethrows CustomException
      expect(
        () async => await todayTopicRepository.getTodayTopic(testDateNotExists),
        throwsA(isA<CustomException>()),
        reason: "Should throw CustomException when the topic for the date does not exist",
      );
    });
  });
}
