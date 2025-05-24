import 'dart:async';

import 'package:THECommu/data_model/chat_model.dart';
import 'package:THECommu/data_model/chat_room_model.dart';
import 'package:THECommu/data_model/user_model.dart';
import 'package:THECommu/repository/chat_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

// --- Helper Functions for Firestore Data Setup ---

// Helper to create user data in Firestore
Future<void> createTestUserInFirestore({
  required FakeFirebaseFirestore firestore,
  required String uid,
  String? nickname,
  String? email,
  String? profileImage,
  List<Map<String, dynamic>>? chattingRooms, // Simplified for this test context
}) async {
  await firestore.collection('users').doc(uid).set({
    'uid': uid,
    'nickname': nickname ?? 'Nickname_$uid',
    'email': email ?? '$uid@example.com',
    'profileImage': profileImage ?? 'http://example.com/profile/$uid.png',
    'following': [],
    'followers': [],
    'followingCount': 0,
    'followerCount': 0,
    'feedCount': 0,
    'feedList': [],
    'feedLikeList': [],
  });
  if (chattingRooms != null) {
    for (var roomData in chattingRooms) {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('chatting_rooms')
          .doc(roomData['id']) // Assuming roomData has an 'id' for the chat room
          .set(roomData);
    }
  }
}

// Helper to create chat room data in the main 'chatting_rooms' collection
Future<void> createChatRoomInFirestore({
  required FakeFirebaseFirestore firestore,
  required String chatRoomId,
  required List<String> userUids, // List of UIDs of users in the chat room
  String? lastMessage,
  Timestamp? createAt,
}) async {
  final userRefs = userUids.map((uid) => firestore.collection('users').doc(uid)).toList();
  await firestore.collection('chatting_rooms').doc(chatRoomId).set({
    'id': chatRoomId,
    'userList': userRefs, // Storing DocumentReferences
    'lastMessage': lastMessage ?? '',
    'createAt': createAt ?? Timestamp.now(),
    // Add any other fields ChatRoomModel.fromMap expects
  });
}

// Helper to create chat message data in Firestore
Future<DocumentReference> createChatMessageInFirestore({
  required FakeFirebaseFirestore firestore,
  required String chatRoomId,
  required String userId, // UID of the message sender
  required String text,
  required Timestamp createdAt,
  ChatTypeEnum type = ChatTypeEnum.text,
  String? imageUrl,
}) async {
  final chatMessageRef =
      firestore.collection('chatting_rooms').doc(chatRoomId).collection('chats').doc(); // Auto-generate ID
  await chatMessageRef.set({
    'id': chatMessageRef.id,
    'userId': firestore.collection('users').doc(userId), // DocumentReference to the user
    'text': text,
    'createAt': createdAt,
    'chatType': type.name, // Storing enum as string
    'imageUrl': imageUrl,
    'isRead': false,
    // Add any other fields ChatModel.fromMap expects
  });
  return chatMessageRef;
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseStorage mockStorage;
  late ChatRepository chatRepository;

  const String myUid = 'myUid';
  const String friendUid = 'friendUid';
  const String otherUserUid = 'otherUserUid';

  late UserModel myUserModel;
  late UserModel friendUserModel;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    final mockUser = MockUser(uid: myUid, email: '$myUid@example.com');
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
    mockStorage = MockFirebaseStorage();
    chatRepository = ChatRepository(
      firebaseFirestore: fakeFirestore,
      firebaseAuth: mockAuth,
      firebaseStorage: mockStorage,
    );

    // Create common user models and Firestore documents
    myUserModel = UserModel(uid: myUid, nickname: 'MyNickname', email: '$myUid@example.com');
    friendUserModel = UserModel(uid: friendUid, nickname: 'FriendNickname', email: '$friendUid@example.com');

    await createTestUserInFirestore(firestore: fakeFirestore, uid: myUid, nickname: myUserModel.nickname);
    await createTestUserInFirestore(firestore: fakeFirestore, uid: friendUid, nickname: friendUserModel.nickname);
    await createTestUserInFirestore(firestore: fakeFirestore, uid: otherUserUid, nickname: 'OtherUser');
  });

  group('enterChatFromFriendList method', () {
    test('Test Case 1.1: No existing chat room', () async {
      // --- ARRANGE ---
      // `myUid` and `friendUid` users are created in setUp.
      // No chat room exists initially between them.

      // --- ACT ---
      final ChatRoomModel resultChatRoom =
          await chatRepository.enterChatFromFriendList(selectedUserModel: friendUserModel);

      // --- ASSERT ---
      // 1. Verify new document in 'chatting_rooms' collection
      final newChatRoomId = resultChatRoom.id;
      final chatRoomDoc = await fakeFirestore.collection('chatting_rooms').doc(newChatRoomId).get();
      expect(chatRoomDoc.exists, isTrue, reason: "New chat room should be created in 'chatting_rooms'");
      final chatRoomData = chatRoomDoc.data()!;
      final userListRefs = (chatRoomData['userList'] as List<dynamic>)
          .map((ref) => (ref as DocumentReference).id)
          .toList();
      expect(userListRefs, containsAll([myUid, friendUid]), reason: "Chat room should contain both users");

      // 2. Verify new chat room added to users/{myUid}/chatting_rooms
      final myUserChatRoomLink =
          await fakeFirestore.collection('users').doc(myUid).collection('chatting_rooms').doc(newChatRoomId).get();
      expect(myUserChatRoomLink.exists, isTrue, reason: "Link to chat room should exist for myUid");
      final myUserChatRoomLinkData = myUserChatRoomLink.data()!;
      final myUserLinkUserList = (myUserChatRoomLinkData['userList'] as List<dynamic>)
          .map((ref) => (ref as DocumentReference).id)
          .toList();
      expect(myUserLinkUserList, containsAll([myUid, friendUid]), reason: "myUid's chat room link has correct users");


      // 3. Verify new chat room added to users/{friendUid}/chatting_rooms
      final friendUserChatRoomLink = await fakeFirestore
          .collection('users')
          .doc(friendUid)
          .collection('chatting_rooms')
          .doc(newChatRoomId)
          .get();
      expect(friendUserChatRoomLink.exists, isTrue, reason: "Link to chat room should exist for friendUid");
      final friendUserChatRoomLinkData = friendUserChatRoomLink.data()!;
      final friendUserLinkUserList = (friendUserChatRoomLinkData['userList'] as List<dynamic>)
          .map((ref) => (ref as DocumentReference).id)
          .toList();
      expect(friendUserLinkUserList, containsAll([myUid, friendUid]), reason: "friendUid's chat room link has correct users");


      // 4. Verify returned ChatRoomModel
      expect(resultChatRoom.id, newChatRoomId);
      expect(resultChatRoom.userList.map((user) => user.uid), containsAll([myUid, friendUid]));
      // Add more assertions for ChatRoomModel fields if necessary
    });

    test('Test Case 1.2: Existing chat room', () async {
      // --- ARRANGE ---
      const existingChatRoomId = 'existingChat123';
      // Pre-populate an existing chat room
      await createChatRoomInFirestore(
          firestore: fakeFirestore, chatRoomId: existingChatRoomId, userUids: [myUid, friendUid]);
      // Link this existing chat room to myUid's subcollection
      await fakeFirestore
          .collection('users')
          .doc(myUid)
          .collection('chatting_rooms')
          .doc(existingChatRoomId)
          .set({
        'id': existingChatRoomId,
        'userList': [
          fakeFirestore.collection('users').doc(myUid),
          fakeFirestore.collection('users').doc(friendUid)
        ],
        'lastMessage': 'Old message',
        'createAt': Timestamp.now(),
      });
       // (The repository logic also checks friendUid's subcollection, so link it there too for robustness)
      await fakeFirestore
          .collection('users')
          .doc(friendUid)
          .collection('chatting_rooms')
          .doc(existingChatRoomId)
          .set({
        'id': existingChatRoomId,
        'userList': [
          fakeFirestore.collection('users').doc(myUid),
          fakeFirestore.collection('users').doc(friendUid)
        ],
        'lastMessage': 'Old message',
        'createAt': Timestamp.now(),
      });


      // --- ACT ---
      final ChatRoomModel resultChatRoom =
          await chatRepository.enterChatFromFriendList(selectedUserModel: friendUserModel);

      // --- ASSERT ---
      // 1. Verify no new document in 'chatting_rooms' (count should remain 1)
      final allChatRooms = await fakeFirestore.collection('chatting_rooms').get();
      expect(allChatRooms.docs.length, 1, reason: "No new chat room should be created");

      // 2. Verify returned ChatRoomModel
      expect(resultChatRoom.id, existingChatRoomId, reason: "Returned chat room ID should be the existing one");
      expect(resultChatRoom.userList.map((user) => user.uid), containsAll([myUid, friendUid]));
    });
  });

  group('sendChat method (Text message)', () {
    test('Test Case 2.1: Send a text message', () async {
      // --- ARRANGE ---
      const chatRoomId = 'chat123';
      // Create a chat room for myUid and otherUserUid
      await createChatRoomInFirestore(
          firestore: fakeFirestore, chatRoomId: chatRoomId, userUids: [myUid, otherUserUid]);
      // Link this chat room to both users' subcollections
      final userRefsForLink = [
        fakeFirestore.collection('users').doc(myUid),
        fakeFirestore.collection('users').doc(otherUserUid)
      ];
      await fakeFirestore.collection('users').doc(myUid).collection('chatting_rooms').doc(chatRoomId).set({
        'id': chatRoomId, 'userList': userRefsForLink, 'lastMessage': '', 'createAt': Timestamp.now()
      });
      await fakeFirestore.collection('users').doc(otherUserUid).collection('chatting_rooms').doc(chatRoomId).set({
        'id': chatRoomId, 'userList': userRefsForLink, 'lastMessage': '', 'createAt': Timestamp.now()
      });


      final initialChatRoomModel = ChatRoomModel(
        id: chatRoomId,
        userList: [myUserModel, UserModel(uid: otherUserUid, nickname: 'OtherUser')], // Populated UserModels
        lastMessage: '',
        createAt: Timestamp.now(),
      );
      const messageText = "Hello, world!";

      // --- ACT ---
      await chatRepository.sendChat(
        text: messageText,
        chatRoomModel: initialChatRoomModel,
        myUserModel: myUserModel,
        chatType: ChatTypeEnum.text,
        replyChatModel: null,
      );

      // --- ASSERT ---
      // 1. Verify new chat message in chatting_rooms/chat123/chats
      final chatsSnapshot =
          await fakeFirestore.collection('chatting_rooms').doc(chatRoomId).collection('chats').get();
      expect(chatsSnapshot.docs.length, 1, reason: "One chat message should be created");
      final chatMessageData = chatsSnapshot.docs.first.data();
      expect(chatMessageData['text'], messageText);
      expect(chatMessageData['userId'], fakeFirestore.collection('users').doc(myUid));
      expect(chatMessageData['chatType'], ChatTypeEnum.text.name);

      // 2. Verify lastMessage and createAt updates in chatting_rooms/chat123
      final mainChatRoomDoc = await fakeFirestore.collection('chatting_rooms').doc(chatRoomId).get();
      expect(mainChatRoomDoc.data()?['lastMessage'], messageText);
      expect(mainChatRoomDoc.data()?['createAt'], isA<Timestamp>()); // Should be updated

      // 3. Verify updates in users/myUid/chatting_rooms/chat123
      final myUserChatRoomLink =
          await fakeFirestore.collection('users').doc(myUid).collection('chatting_rooms').doc(chatRoomId).get();
      expect(myUserChatRoomLink.data()?['lastMessage'], messageText);

      // 4. Verify updates in users/otherUserUid/chatting_rooms/chat123
      final otherUserChatRoomLink = await fakeFirestore
          .collection('users')
          .doc(otherUserUid)
          .collection('chatting_rooms')
          .doc(chatRoomId)
          .get();
      expect(otherUserChatRoomLink.data()?['lastMessage'], messageText);
    });
  });

  group('getChattingList method (Initial Load)', () {
    test('Test Case 3.1: Fetch initial list of chat messages', () async {
      // --- ARRANGE ---
      const chatRoomId = 'chatRoomForGetList';
      await createChatRoomInFirestore(
          firestore: fakeFirestore, chatRoomId: chatRoomId, userUids: [myUid, otherUserUid]);

      // Create messages
      await createChatMessageInFirestore(
          firestore: fakeFirestore, chatRoomId: chatRoomId, userId: myUid, text: "Msg1", createdAt: Timestamp(100, 0));
      await createChatMessageInFirestore(
          firestore: fakeFirestore, chatRoomId: chatRoomId, userId: otherUserUid, text: "Msg2", createdAt: Timestamp(200, 0));
      await createChatMessageInFirestore(
          firestore: fakeFirestore, chatRoomId: chatRoomId, userId: myUid, text: "Msg3", createdAt: Timestamp(300, 0));

      // --- ACT ---
      final List<ChatModel> chatList =
          await chatRepository.getChattingList(chatRoomId: chatRoomId, lastChatId: null, firstChatId: null);

      // --- ASSERT ---
      expect(chatList.length, 3, reason: "Should fetch all 3 messages");

      // Verify order (ascending by createAt, as per current repo logic)
      expect(chatList[0].text, "Msg1");
      expect(chatList[1].text, "Msg2");
      expect(chatList[2].text, "Msg3");

      // Verify userModel population
      expect(chatList[0].userModel, isNotNull);
      expect(chatList[0].userModel!.uid, myUid);
      expect(chatList[0].userModel!.nickname, 'MyNickname');

      expect(chatList[1].userModel, isNotNull);
      expect(chatList[1].userModel!.uid, otherUserUid);
      expect(chatList[1].userModel!.nickname, 'OtherUser');
    });
  });

   group('getChatRoomList method (Stream snapshot processing)', () {
    test('Test Case 4.1: Process a snapshot of chat rooms', () async {
      // --- ARRANGE ---
      const chatRoom1Id = 'userChatRoom1';
      const chatRoom2Id = 'userChatRoom2';
      final friendXUid = 'friendXUid'; // Friend in chatRoom1
      final friendYUid = 'friendYUid'; // Friend in chatRoom2

      await createTestUserInFirestore(firestore: fakeFirestore, uid: friendXUid, nickname: 'FriendX');
      await createTestUserInFirestore(firestore: fakeFirestore, uid: friendYUid, nickname: 'FriendY');

      // Create chat room links in users/myUid/chatting_rooms
      // These documents will be the source for the stream
      final myUserChatRoomsCollection = fakeFirestore.collection('users').doc(myUid).collection('chatting_rooms');
      await myUserChatRoomsCollection.doc(chatRoom1Id).set({
        'id': chatRoom1Id,
        'userList': [fakeFirestore.collection('users').doc(myUid), fakeFirestore.collection('users').doc(friendXUid)],
        'lastMessage': 'Hi X',
        'createAt': Timestamp(100,0),
      });
      await myUserChatRoomsCollection.doc(chatRoom2Id).set({
        'id': chatRoom2Id,
        'userList': [fakeFirestore.collection('users').doc(myUid), fakeFirestore.collection('users').doc(friendYUid)],
        'lastMessage': 'Hello Y',
        'createAt': Timestamp(200,0), // Newer
      });
      
      // (Optional but good for consistency: create actual chat rooms in 'chatting_rooms' collection)
      await createChatRoomInFirestore(firestore: fakeFirestore, chatRoomId: chatRoom1Id, userUids: [myUid, friendXUid], lastMessage: "Hi X", createAt: Timestamp(100,0));
      await createChatRoomInFirestore(firestore: fakeFirestore, chatRoomId: chatRoom2Id, userUids: [myUid, friendYUid], lastMessage: "Hello Y", createAt: Timestamp(200,0));


      // --- ACT ---
      final Stream<List<ChatRoomModel>> chatRoomListStream = chatRepository.getChatRoomList(myUserId: myUid);

      // --- ASSERT ---
      // Expect the stream to emit a list containing the chat rooms
      // Order should be by 'createAt' descending (if repo sorts that way)
      await expectLater(
        chatRoomListStream,
        emits((List<ChatRoomModel> roomList) {
          if (roomList.length != 2) return false;
          // Assuming descending order of createAt by repository
          final roomWithY = roomList.firstWhere((room) => room.id == chatRoom2Id); // Newest
          final roomWithX = roomList.firstWhere((room) => room.id == chatRoom1Id); // Older

          expect(roomWithY.lastMessage, 'Hello Y');
          expect(roomWithY.userList.any((user) => user.uid == friendYUid && user.nickname == 'FriendY'), isTrue);
          expect(roomWithY.userList.any((user) => user.uid == myUid), isTrue);


          expect(roomWithX.lastMessage, 'Hi X');
          expect(roomWithX.userList.any((user) => user.uid == friendXUid && user.nickname == 'FriendX'), isTrue);
          expect(roomWithX.userList.any((user) => user.uid == myUid), isTrue);
          
          return true;
        }),
      );
    });
  });

}
