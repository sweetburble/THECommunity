import 'dart:io';

import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/dart/extension/enum_extension.dart';
import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:THECommu/data/models/chat/chat_room_model.dart';
import 'package:THECommu/data/models/chat/chat_type_enum.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

/**
 * 1대1 채팅 관련 리포지토리
 */
class ChatRepository {
  final FirebaseFirestore fireStore;
  final FirebaseAuth firebaseAuth;
  final FirebaseStorage storage;

  const ChatRepository({
    required this.fireStore,
    required this.firebaseAuth,
    required this.storage,
  });

  /**
   * 친구 목록에서 친구를 클릭하면, 채팅방 데이터를 생성해서 데이터베이스에 저장
   * 이미 개설된 채팅방이 없다면, 1대1 채팅방 생성
   */
  Future<ChatRoomModel> enterChatFromFriendList({
    required UserModel selectedUserModel, // 내가 클릭한 친구의 데이터
  }) async {
    try {
      final friendUid = selectedUserModel.uid; // 친구의 UID
      final myUid = firebaseAuth.currentUser!.uid; // 나의 UID

      /// 항상 리스트의 0번 인덱스에는 "나의 userModel"이 들어있게 하기 위홤
      // final userModelList = [
      //   await fireStore
      //       .collection("users")
      //       .doc(myUid)
      //       .get()
      //       .then((value) => UserModel.fromMap(value.data()!)),
      //   await fireStore
      //       .collection("users")
      //       .doc(friendUid)
      //       .get()
      //       .then((value) => UserModel.fromMap(value.data()!)),
      // ];
      final userModelList = [myUid, friendUid];

      /// 먼저 이미 해당 친구랑 1대1 채팅방이 있는지 확인하고, 없다면 새로운 chatRoomModel을 반환한다
      final querySnapshot = await fireStore
          .collection('users')
          .doc(myUid)
          .collection('chatting_rooms')
          .where('userList', arrayContains: friendUid)
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return await _createChatRoom(userModelList: userModelList);
      }

      /// 있다면 기존 chatRoomModel을 만들어서 반환한다
      return ChatRoomModel.fromMap(
        map: querySnapshot.docs.first.data(),
        userModelList: userModelList,
      );
    } catch (_) {
      rethrow;
    }
  }

  /**
   * 1대1 채팅방을 만드는 함수
   */
  Future<ChatRoomModel> _createChatRoom({
    required List<String> userModelList,
  }) async {
    try {
      final chatRoomDocRef = fireStore.collection("chatting_rooms").doc();
      final chatRoomModel = ChatRoomModel(
        id: chatRoomDocRef.id,
        lastMessage: "",
        userList: userModelList,
        createAt: Timestamp.now(),
      );

      /// users 컬렉션과 chatting_rooms 컬렉션을 다룰 것이기 때문에 트랜잭션 사용
      await fireStore.runTransaction((transaction) async {
        // 1. chatting_rooms 컬렉션에 "이 채팅방" 문서를 만든다
        transaction.set(chatRoomDocRef, chatRoomModel.toMap());

        for (final userId in userModelList) {
          // 2. users 컬렉션에서 -> 채팅방에 참여한 모든 유저 문서의 하위에
          final usersChatRoomDocRef = fireStore
              .collection('users')
              .doc(userId)
              .collection('chatting_rooms')
              .doc(chatRoomDocRef.id);
          // -> chatting_rooms 컬렉션(= 그 유저가 참여한 모든 채팅방)에 이 채팅방 문서를 만든다
          transaction.set(usersChatRoomDocRef, chatRoomModel.toMap());
        }
      });

      return chatRoomModel;
    } catch (_) {
      rethrow;
    }
  }

  /**
   * "내가" 채팅방에서 채팅(DM) 전송
   * 텍스트 전송 / 이미지 전송 / 동영상 전송 / 답장 전송 -> 4가지 타입이 있다
   */
  Future<void> sendChat({
    String? text,
    File? file,
    required ChatRoomModel chatRoomModel, // 채팅을 작성하고 있는 채팅방 모델
    required UserModel myUserModel, // 내가 채팅을 전송했으니까
    required ChatTypeEnum chatType,
    required ChatModel? replyChatModel, // 답장 채팅일 때
  }) async {
    try {
      if (chatType != ChatTypeEnum.text) {
        text = chatType.fromChatTypeEnumToText();
      }

      /// 가장 먼저 채팅을 보내려는 채팅방의 정보를 업데이트한다
      chatRoomModel = chatRoomModel.copyWith(
        createAt: Timestamp.now(),
        lastMessage: text,
      );

      final chatDocRef = fireStore
          .collection('chatting_rooms')
          .doc(chatRoomModel.id)
          .collection('chats')
          .doc();

      /// 이미지/동영상 전송이라면, 미리 Firebase storage에 저장한다
      if (chatType != ChatTypeEnum.text) {
        String? mimeType = lookupMimeType(file!.path); // 'image/png'
        final metaData = SettableMetadata(contentType: mimeType);
        final fileName = '${Uuid().v1()}.${mimeType!.split('/')[1]}';

        TaskSnapshot taskSnapshot = await storage
            .ref()
            .child("chats") // chats 폴더에
            .child(chatRoomModel.id) // 채팅방 고유 id로 폴더를 하나 만들고,
            .child(fileName) // 그 채팅방 폴더에 파일이 들어갈 폴더를 하나 더 만들어 저장한다
            .putFile(file, metaData);
        text = await taskSnapshot.ref.getDownloadURL(); // 이미지/동영상 전송일 때는, text 필드에 storage 참조 경로가 저장
      }

      final chatModel = ChatModel(
        userId: myUserModel.uid,
        userModel: UserModel.init(), // 채팅를 보낼땐 필요없고, 나중에 지난 채팅들을 가져올 때만 채울 데이터기 때문에
        chattingId: chatDocRef.id,
        text: text!,
        chatType: chatType,
        createAt: Timestamp.now(),
        replyChatModel: replyChatModel, // null 또는 답장 채팅 모델
      );

      await fireStore.runTransaction((transaction) async {
        /// 1. 채팅방 목록(컬렉션) -> 현재 채팅방(문서) -> 채팅방에 속한 채팅 리스트(하위 컬렉션)에 보낼 채팅 "문서"를 추가
        transaction.set(chatDocRef, chatModel.toMap());

        /// 2. (1대1)채팅에 참여하고 있는 각 유저 문서 하위의 채팅방 목록(컬렉션) -> 현재 채팅방(문서)도 업데이트
        for (final userId in chatRoomModel.userList) {
          transaction.set(
            fireStore
                .collection('users')
                .doc(userId)
                .collection('chatting_rooms')
                .doc(chatRoomModel.id),
            chatRoomModel.toMap(),
          );
        }
      });
    } catch (_) {
      rethrow;
    }
  }

  /**
   * 해당 1대1 채팅방의 채팅 내역(List<ChatModel>)을 "한 번" 가져오는 함수 (실시간 업데이트 아님!)
   */
  Future<List<ChatModel>> getChattingList({
    required String chatRoomId,
    String? lastChatId, // 해당 채팅방의 "가장 최근 채팅의 Id"
    String? firstChatId, // 20개씩 조회한 채팅 중 "가장 오래된 채팅의 Id"
  }) async {
    try {
      /// query에 조건부 조건을 붙일 것이기 때문에, snapshot과 분리
      Query<Map<String, dynamic>> query = fireStore
          .collection('chatting_rooms')
          .doc(chatRoomId)
          .collection('chats')
          .orderBy('createAt')
          .limitToLast(20); // 최근 채팅 중 20개만 조회한다는 뜻 (부하 방지)

      if (lastChatId != null) {
        final lastDocRef = await fireStore
            .collection('chatting_rooms')
            .doc(chatRoomId)
            .collection('chats')
            .doc(lastChatId)
            .get();
        // 가장 최근 채팅이 있다면, 새로운 쿼리는 그 채팅 이후에 작성된 채팅 내역만 가져온다
        query = query.startAfterDocument(lastDocRef);
      } else if (firstChatId != null) {
        final firstDocRef = await fireStore
            .collection('chatting_rooms')
            .doc(chatRoomId)
            .collection('chats')
            .doc(firstChatId)
            .get();
        // firstChatId가 있다면, 새로운 쿼리는 그 채팅 이전에 작성된 채팅 내역 20개만 더 가져온다
        query = query.endBeforeDocument(firstDocRef);
      }
      final snapshot = await query.get();

      return await Future.wait(snapshot.docs.map((chatsDoc) async {
        final userModel = await fireStore
            .collection('users')
            .doc(chatsDoc.data()['userId'])
            .get()
            .then((value) => UserModel.fromMap(value.data()!));
        return ChatModel.fromMap(chatsDoc.data(), userModel);
      }).toList());
    } catch (_) {
      rethrow;
    }
  }

  /**
   * "내가" 참여하고 있는, "모든 1대1 채팅방의 데이터를 리스트로 만들어서 반환"한다
   * asyncMap() : Stream() 객체를 하나씩 사용하고, 결과도 Stream()으로 반환한다
   */
  Stream<List<ChatRoomModel>> getChatRoomList({
    required String myUserId, // "나의" userModel
  }) {
    try {
      return fireStore
          .collection('users')
          .doc(myUserId) // 내가 참여하고 있는 1대1 채팅방 중,
          .collection('chatting_rooms')
          .orderBy('createAt', descending: true) // 최근 채팅방이 먼저 오도록
          .snapshots() // Stream을 반환하기 때문에 실시간으로 참여 중인 채팅방을 알 수 있다
          .asyncMap((event) async {
        List<ChatRoomModel> chatRoomModelList = [];

        for (final doc in event.docs) {
          UserModel userModel = UserModel.init();
          final chatData = doc.data();

          List<String> userIdList = List<String>.from(chatData['userList']);

          // 채팅방에서 "내가 아닌" 다른 유저의 userId 값만 저장해서,
          final userId = userIdList.firstWhere(
            (element) => element != myUserId,
          );

          // 그걸 firestore에서 찾아서 userModel 변수에 저장한다
          if (userId.isNotEmpty) {
            userModel = await fireStore
                .collection('users')
                .doc(userId)
                .get()
                .then((value) => UserModel.fromMap(value.data()!));
          }

          // 그 userModel과 다른 데이터로 채팅방 모델 객체를 만들어서 리스트에 추가한다
          final chatRoomModel = ChatRoomModel.fromMap(
            map: chatData,
            userModelList: [myUserId, userModel.uid],
          );

          chatRoomModelList.add(chatRoomModel);
        }

        return chatRoomModelList;
      });
    } catch (_) {
      rethrow;
    }
  }

  /**
   * 채팅방 나가기 로직
   */
  Future<void> exitChatRoom({
    required ChatRoomModel chatRoomModel,
    required String myUserId,
  }) async {
    try {
      final chatRoomDocRef =
          fireStore.collection('chatting_rooms').doc(chatRoomModel.id);

      // 3번에서 사용하는, 삭제할 채팅방의 참조 주소
      final exitChatRoomDocRef = fireStore
          .collection('users')
          .doc(myUserId)
          .collection('chatting_rooms')
          .doc(chatRoomModel.id);

      fireStore.runTransaction((transaction) async {
        /// 1. chatting_rooms(컬렉션) -> 해당 채팅방(문서) -> userList 필드에서 내 UID만 삭제
        transaction.update(chatRoomDocRef, {
          'userList': FieldValue.arrayRemove([myUserId]),
        });

        /// 2. users(컬렉션)의 "상대방 문서"에서 -> 하위 chatting_rooms(컬렉션)의 해당 채팅방(문서)에서 -> 나의 UID를 빈 문자열로 변환
        for (final userId in chatRoomModel.userList) {
          if (userId == myUserId || userId.isEmpty) continue;
          final friendChatRoomDocRef = fireStore
              .collection('users')
              .doc(userId)
              .collection('chatting_rooms')
              .doc(chatRoomModel.id);
          transaction.update(friendChatRoomDocRef, {
            'userList': FieldValue.arrayRemove([myUserId]),
          });
          transaction.update(friendChatRoomDocRef, {
            'userList': FieldValue.arrayUnion([""]),
            'createAt': Timestamp.now(),
          });
        }

        /// 3. users(컬렉션)의 "내 문서"에서 -> 하위 chatting_rooms(컬렉션)에서 -> 해당 채팅방(문서) 삭제
        transaction.delete(exitChatRoomDocRef);
      });
    } catch (_) {
      rethrow;
    }
  }
}
