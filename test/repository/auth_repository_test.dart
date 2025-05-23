import 'dart:typed_data';

import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/repository/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockUser extends Mock implements User {
  @override
  final bool emailVerified;
  @override
  final String uid;

  MockUser({this.emailVerified = false, this.uid = 'test_uid'});
}

class MockUserCredential extends Mock implements UserCredential {
  @override
  final User? user;

  MockUserCredential({this.user});
}

class MockTaskSnapshot extends Mock implements TaskSnapshot {}

void main() {
  late AuthRepository authRepository;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseStorage mockStorage;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockStorage = MockFirebaseStorage();
    fakeFirestore = FakeFirebaseFirestore();
    authRepository = AuthRepository(
      firebaseAuth: mockAuth,
      firebaseStorage: mockStorage,
      firebaseFirestore: fakeFirestore,
    );
  });

  group('AuthRepository Tests', () {
    group('signIn method', () {
      const String testEmail = 'test@example.com';
      const String testPassword = 'password123';

      test('Test Case 1.1: Successful sign-in with a verified email', () async {
        final mockUser = MockUser(emailVerified: true);
        final mockUserCredential = MockUserCredential(user: mockUser);

        when(() => mockAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockUserCredential);

        await expectLater(authRepository.signIn(email: testEmail, password: testPassword), completes);
      });

      test('Test Case 1.2: Attempted sign-in with an unverified email', () async {
        final mockUser = MockUser(emailVerified: false);
        final mockUserCredential = MockUserCredential(user: mockUser);

        when(() => mockAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        try {
          await authRepository.signIn(email: testEmail, password: testPassword);
        } catch (e) {
          expect(e, isA<CustomException>());
          expect((e as CustomException).message, '인증되지 않은 이메일');
        }

        verify(() => mockUser.sendEmailVerification()).called(1);
        verify(() => mockAuth.signOut()).called(1);
      });

      test('Test Case 1.3: Attempted sign-in with a non-existent user', () async {
        when(() => mockAuth.signInWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenThrow(FirebaseAuthException(code: 'user-not-found', message: 'User not found'));

        try {
          await authRepository.signIn(email: testEmail, password: testPassword);
        } catch (e) {
          expect(e, isA<CustomException>());
          expect((e as CustomException).message, contains('User not found'));
        }
      });
    });

    group('signUp method', () {
      const String testEmail = 'newuser@example.com';
      const String testPassword = 'newpassword123';
      const String testNickname = 'NewUser';
      final Uint8List testProfileImage = Uint8List(0);

      test('Test Case 2.1: Successful sign-up with a profile image', () async {
        final mockUser = MockUser(uid: 'new_user_uid');
        final mockUserCredential = MockUserCredential(user: mockUser);
        final mockTaskSnapshot = MockTaskSnapshot();
        const String downloadUrl = 'http://example.com/profile.jpg';

        when(() => mockAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});

        // Mock FirebaseStorage
        final ref = mockStorage.ref();
        final profileImagesRef = ref.child('profile_images');
        final userImageRef = profileImagesRef.child(mockUser.uid);
        when(() => mockStorage.ref().child('profile_images').child(mockUser.uid).putData(testProfileImage))
            .thenAnswer((_) async => mockTaskSnapshot);
        when(() => mockTaskSnapshot.ref.getDownloadURL()).thenAnswer((_) async => downloadUrl);
        
        // Mock FirebaseFirestore - Using FakeFirebaseFirestore, direct calls will be recorded
        // No explicit when() needed for fakeFirestore.collection().doc().set()

        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await authRepository.signUp(
          email: testEmail,
          password: testPassword,
          nickname: testNickname,
          profileImage: testProfileImage,
        );

        verify(() => mockAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
        verify(() => mockUser.sendEmailVerification()).called(1);
        verify(() => mockStorage.ref().child('profile_images').child(mockUser.uid).putData(testProfileImage)).called(1);
        verify(() => mockTaskSnapshot.ref.getDownloadURL()).called(1);
        
        // Verify Firestore write
        final doc = await fakeFirestore.collection('users').doc(mockUser.uid).get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['email'], testEmail);
        expect(doc.data()?['nickname'], testNickname);
        expect(doc.data()?['profileImage'], downloadUrl);

        verify(() => mockAuth.signOut()).called(1);
      });

      test('Test Case 2.2: Successful sign-up without a profile image', () async {
        final mockUser = MockUser(uid: 'new_user_uid_no_image');
        final mockUserCredential = MockUserCredential(user: mockUser);

        when(() => mockAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockUserCredential);
        when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});
        // No storage interaction expected
        when(() => mockAuth.signOut()).thenAnswer((_) async {});


        await authRepository.signUp(
          email: testEmail,
          password: testPassword,
          nickname: testNickname,
          profileImage: null,
        );

        verify(() => mockAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);
        verify(() => mockUser.sendEmailVerification()).called(1);
        
        verifyNever(() => mockStorage.ref().child(any()).child(any()).putData(any()));
        verifyNever(() => mockStorage.ref().child(any()).child(any()).child(any()).putData(any()));


        final doc = await fakeFirestore.collection('users').doc(mockUser.uid).get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['email'], testEmail);
        expect(doc.data()?['nickname'], testNickname);
        expect(doc.data()?['profileImage'], isNull);
        
        verify(() => mockAuth.signOut()).called(1);
      });


      test('Test Case 2.3: Attempted sign-up with an email that already exists', () async {
        when(() => mockAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenThrow(FirebaseAuthException(code: 'email-already-in-use', message: 'Email already in use.'));

        try {
          await authRepository.signUp(
            email: testEmail,
            password: testPassword,
            nickname: testNickname,
            profileImage: null,
          );
        } catch (e) {
          expect(e, isA<CustomException>());
          expect((e as CustomException).message, contains('Email already in use.'));
        }
        verifyNever(() => mockAuth.signOut());
      });
    });

    group('signOut method', () {
      test('Test Case 3.1: Successful sign-out', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await authRepository.signOut();

        verify(() => mockAuth.signOut()).called(1);
      });
    });
  });
}
