import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/data/models/today_topic.dart';
import 'package:THECommu/repository/today_topic_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper function to create today_topic data in Firestore
Future<void> createTodayTopicInFirestore({
  required FakeFirebaseFirestore firestore,
  required String date, // e.g., "2024-12-27"
  required String tag,
  required String topic,
}) async {
  await firestore.collection('today_topic').doc(date).set({
    'date': date,
    'tag': tag,
    'topic': topic,
  });
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TodayTopicRepository todayTopicRepository;

  const String testDate = "2023-10-27";
  const String testTag = "Test Topic Title";
  const String testTopic = "This is the content for the test topic.";

  const String testDateNotExists = "nonExistentDate";

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    todayTopicRepository =
        TodayTopicRepository(firebaseFirestore: fakeFirestore);
  });

  group('getTodayTopic method', () {
    test('Test Case 1: Topic exists for the given date string', () async {
      // --- ARRANGE ---
      // Add a document to the 'today_topic' collection
      await createTodayTopicInFirestore(
        firestore: fakeFirestore,
        date: testDate,
        tag: testTag,
        topic: testTopic,
      );

      // --- ACT ---
      final TodayTopic result =
          await todayTopicRepository.getTodayTopic(testDate);

      // --- ASSERT ---
      expect(result, isNotNull,
          reason: "TodayTopic object should not be null when data exists");
      expect(result.date, testDate,
          reason: "Title should match the data in Firestore");
      expect(result.tag, testTag,
          reason: "Content should match the data in Firestore");
      // If your TodayTopic model has an ID field that gets populated from the document ID:
      // expect(result.id, testDateExists, reason: "ID should match the document ID");
      // Verify other fields like createdAt if they are part of your model and comparison
      expect(result.topic, testTopic,
          reason: "CreatedAt timestamp should match");
    });

    test('Test Case 2: Topic does not exist for the given date string',
        () async {
      // --- ARRANGE ---
      // Firestore is initialized but does not contain a topic for 'nonExistentDate'
      // (No specific setup needed for this case as fakeFirestore is empty by default for this doc)

      // --- ACT & ASSERT ---
      // The repository catches the error from snapshot.data()! and rethrows CustomException
      expect(
        () async => await todayTopicRepository.getTodayTopic(testDateNotExists),
        throwsA(isA<CustomException>()),
        reason:
            "Should throw CustomException when the topic for the date does not exist",
      );
    });
  });
}
