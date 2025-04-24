import 'dart:io';

import 'package:THECommu/common/dart/extension/enum_extension.dart';
import 'package:THECommu/data/models/chat/chat_model.dart';
import 'package:THECommu/data/models/chat/chat_type_enum.dart';
import 'package:THECommu/data/models/chat/group_chat_room_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

/**
 * 그룹 채팅 관련 리포지토리
 */
class GroupChatRepository {
  final FirebaseFirestore fireStore;
  final FirebaseStorage storage;

  const GroupChatRepository({
    required this.fireStore,
    required this.storage,
  });

  /**
   * 그룹 채팅방 생성
   */
  Future<GroupChatRoomModel> createGroupChatRoom({
    required String groupChatRoomName, // 그룹 채팅방 이름
    required File? groupChatRoomImage, // 그룹 채팅방 대표 이미지
    required List<String> selectedFriendList,
    required UserModel myUserModel, // 나의 유저 모델
  }) async {
    String? photoURL; // Firebase Storage에 저장할 그룹 채팅방 대표 이미지의 참조 주소
    try {
      final groupChatRoomDocRef =
          fireStore.collection('group_chat_rooms').doc();

      if (groupChatRoomImage != null) {
        /// 최신 Firebase는 자체적으로 파일 타입을 파악해서 메타데이터에 넣어준다 -> MIME 사용 안함

        final snapshot = await storage
            .ref()
            .child("group_chat_rooms")
            .child(groupChatRoomDocRef.id)
            .putFile(groupChatRoomImage);
        photoURL = await snapshot.ref.getDownloadURL();
      }

      /// 그룹 채팅에 참여할 유저 리스트 (나 제외)
      final userList = await Future.wait(selectedFriendList.map(
        (friendUID) async {
          final friendUid = friendUID; // 친구의 UID

          return await fireStore
              .collection("users")
              .doc(friendUid)
              .get()
              .then((value) => UserModel.fromMap(value.data()!));
        },
      ).toList());
      userList.add(myUserModel); // 유저 리스트의 "마지막"에 나를 추가한다

      // TODO: 임시
      selectedFriendList.add(myUserModel.uid);

      final groupChatRoomModel = GroupChatRoomModel(
        id: groupChatRoomDocRef.id,
        userList: selectedFriendList,
        lastMessage: "",
        createAt: Timestamp.now(),
        groupRoomName: groupChatRoomName,
        groupRoomImageUrl: photoURL,
      );

      /// users 컬렉션과 group_chat_rooms 컬렉션을 다룰 것이기 때문에 트랜잭션 사용
      await fireStore.runTransaction((transaction) async {
        // 1. group_chat_rooms 컬렉션에 "이 채팅방 문서"를 추가한다
        transaction.set(groupChatRoomDocRef, groupChatRoomModel.toMap());

        for (final userModel in userList) {
          // 2. users 컬렉션에서 -> 그룹 채팅방에 참여한 모든 유저 문서의 하위에
          final usersGroupChatRoomDocRef = fireStore
              .collection('users')
              .doc(userModel.uid)
              .collection('group_chat_rooms')
              .doc(groupChatRoomDocRef.id);
          // -> group_chat_rooms 컬렉션(= 그 유저가 참여한 모든 그룹 채팅방)에 이 채팅방 문서를 만든다
          transaction.set(usersGroupChatRoomDocRef, groupChatRoomModel.toMap());
        }
      });

      return groupChatRoomModel;
    } catch (_) {
      if (photoURL != null) {
        await storage.refFromURL(photoURL).delete();
      }
      rethrow;
    }
  }

  /**
   * "내가" 그룹 채팅방에서 채팅(DM) 전송
   * 텍스트 전송 / 이미지 전송 / 동영상 전송 / 답장 전송 -> 4가지 타입이 있다
   */
  Future<void> sendChat({
    String? text,
    File? file,
    required GroupChatRoomModel groupChatRoomModel, // 채팅을 작성하고 있는 채팅방 모델
    required UserModel myUserModel, // 내가 채팅을 전송했으니까
    required ChatTypeEnum chatType,
    required ChatModel? replyChatModel, // 답장 채팅일 때
  }) async {
    try {
      if (chatType != ChatTypeEnum.text) {
        text = chatType.fromChatTypeEnumToText();
      }

      /// 가장 먼저 채팅을 보내려는 채팅방의 정보를 업데이트한다
      groupChatRoomModel = groupChatRoomModel.copyWith(
        createAt: Timestamp.now(),
        lastMessage: text,
      );

      final chatDocRef = fireStore
          .collection('group_chat_rooms')
          .doc(groupChatRoomModel.id)
          .collection('chats')
          .doc();

      /// 이미지/동영상 전송이라면, 미리 Firebase storage에 저장한다
      if (chatType != ChatTypeEnum.text) {
        String? mimeType = lookupMimeType(file!.path); // 'image/png'
        final metaData = SettableMetadata(contentType: mimeType);
        final fileName = '${Uuid().v1()}.${mimeType!.split('/')[1]}';

        TaskSnapshot taskSnapshot = await storage
            .ref()
            .child("group_chat_rooms") // group_chat_rooms 폴더에
            .child(groupChatRoomModel.id) // 채팅방 고유 id로 폴더를 하나 만들고,
            .child(fileName) // 그 채팅방 폴더에 파일이 들어갈 폴더를 하나 더 만들어 저장한다
            .putFile(file, metaData);
        text = await taskSnapshot.ref
            .getDownloadURL(); // 이미지/동영상 전송일 때는, text 필드에 storage 참조 경로가 저장
      }

      final chatModel = ChatModel(
        userId: myUserModel.uid,
        userModel: UserModel.init(),
        // 채팅를 보낼땐 필요없고, 나중에 지난 채팅들을 가져올 때만 채울 데이터기 때문에
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
        for (final userId in groupChatRoomModel.userList) {
          transaction.set(
            fireStore
                .collection('users')
                .doc(userId)
                .collection('group_chat_rooms')
                .doc(groupChatRoomModel.id),
            groupChatRoomModel.toMap(),
          );
        }
      });
    } catch (_) {
      rethrow;
    }
  }

  /**
   * "내가" 참여하고 있는, "모든 그룹 채팅방의 데이터를 리스트로 만들어서 반환"한다
   * asyncMap() : Stream() 객체를 하나씩 사용하고, 결과도 Stream()으로 반환한다
   */
  Stream<List<GroupChatRoomModel>> getGroupChatRoomList({
    required String myUserId, // "나의" userModel
  }) {
    try {
      return fireStore
          .collection('users')
          .doc(myUserId) // 내가 참여하고 있는 그룹 채팅방 중,
          .collection('group_chat_rooms')
          .orderBy('createAt', descending: true) // 최근 채팅방이 먼저 오도록
          .snapshots() // Stream을 반환하기 때문에 실시간으로 참여 중인 채팅방을 알 수 있다
          .asyncMap((event) async {
        List<GroupChatRoomModel> groupChatRoomList = [];

        for (final doc in event.docs) {
          final groupChatRoomData = doc.data();

          List<String> userIdList = List<String>.from(groupChatRoomData['userList']);

          // 그 userModel과 다른 데이터로 "그룹 채팅방 모델"을 만들어서 리스트에 추가한다
          final groupChatRoomModel = GroupChatRoomModel.fromMap(
            map: groupChatRoomData,
            userList: userIdList,
          );

          groupChatRoomList.add(groupChatRoomModel);
        }

        return groupChatRoomList;
      });
    } catch (_) {
      rethrow;
    }
  }

  /**
   * 해당 그룹 채팅방의 채팅 내역(List<ChatModel>)을 "한 번" 가져오는 함수 (실시간 업데이트 아님!)
   */
  Future<List<ChatModel>> getChattingList({
    required String groupChatRoomId,
    String? lastChatId, // 해당 채팅방의 "가장 최근 채팅의 Id"
    String? firstChatId, // 20개씩 조회한 채팅 중 "가장 오래된 채팅의 Id"
  }) async {
    try {
      /// query에 조건부 조건을 붙일 것이기 때문에, snapshot과 분리
      Query<Map<String, dynamic>> query = fireStore
          .collection('group_chat_rooms')
          .doc(groupChatRoomId)
          .collection('chats')
          .orderBy('createAt')
          .limitToLast(20); // 최근 채팅 중 20개만 조회한다는 뜻 (부하 방지)

      if (lastChatId != null) {
        final lastDocRef = await fireStore
            .collection('group_chat_rooms')
            .doc(groupChatRoomId)
            .collection('chats')
            .doc(lastChatId)
            .get();
        // 가장 최근 채팅이 있다면, 새로운 쿼리는 그 채팅 이후에 작성된 채팅 내역만 가져온다
        query = query.startAfterDocument(lastDocRef);
      } else if (firstChatId != null) {
        final firstDocRef = await fireStore
            .collection('group_chat_rooms')
            .doc(groupChatRoomId)
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
   * 채팅방 나가기 로직
   */
  Future<void> exitChatRoom({
    required GroupChatRoomModel groupChatRoomModel,
    required String myUserId,
  }) async {
    try {
      final chatRoomDocRef =
          fireStore.collection('group_chat_rooms').doc(groupChatRoomModel.id);

      // 3번에서 사용하는, 삭제할 채팅방의 참조 주소
      final exitChatRoomDocRef = fireStore
          .collection('users')
          .doc(myUserId)
          .collection('group_chat_rooms')
          .doc(groupChatRoomModel.id);

      fireStore.runTransaction((transaction) async {
        /// 1. group_chat_rooms(컬렉션) -> 해당 채팅방(문서) -> userList 필드에서 내 UID만 삭제
        transaction.update(chatRoomDocRef, {
          'userList': FieldValue.arrayRemove([myUserId]),
        });

        /// 2. users(컬렉션)의 "상대방 문서"에서 -> 하위 group_chat_rooms(컬렉션)의 해당 채팅방(문서)에서 -> 나의 UID를 빈 문자열로 변환
        for (final userId in groupChatRoomModel.userList) {
          if (userId == myUserId || userId.isEmpty) continue;

          final friendChatRoomDocRef = fireStore
              .collection('users')
              .doc(userId)
              .collection('group_chat_rooms')
              .doc(groupChatRoomModel.id);

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
