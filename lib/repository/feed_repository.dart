import 'dart:io';

import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/common/util/logger.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:THECommu/ai/gpt_repository.dart';
import 'package:THECommu/ai/gemini_repository.dart';

/**
 * 이미지 파일은 가장 먼저 Firebase Storage에 저장한 다음, 그곳에서 주는 경로를 FireStore에 저장하는 방식이다
 */
class FeedRepository {
  final FirebaseStorage firebaseStorage;
  final FirebaseFirestore firebaseFirestore;

  final remoteConfig = FirebaseRemoteConfig.instance;

  FeedRepository({
    required this.firebaseStorage,
    required this.firebaseFirestore,
  });

  /**
   * 피드 다수 조회
   * 1) uid == null이면, 모든 사용자의 피드를 조회하고, -> 커뮤니티 화면
   * 2) null이 아니면, 특정 사용자의 피드만 조회한다 -> 프로필 화면
   * 3) feedId를 토대로 페이징도 적용한다 -> "feedId" 피드부터 "feedLength"개 만큼 조회
   */
  Future<List<FeedModel>> getFeedList({
    String? uid,
    String? feedId, // 몇 번째 피드부터 feedLength개씩 조회하는지
    int feedLength = 8,
  }) async {
    try {
      // snapshot을 생성하기 위한 query 생성
      Query<Map<String, dynamic>> query = firebaseFirestore
          .collection('feeds')
          .orderBy('createAt', descending: true)
          .limit(feedLength); // 페이징 적용

      // uid가 null이 아닐 경우 (특정 유저의 피드를 가져올 경우) query에 조건 추가
      if (uid != null) {
        query = query.where('uid', isEqualTo: uid);
      }

      // 마지막으로 조회한 feedId부터 "feedLength"개 만큼 조회
      if (feedId != null) {
        DocumentSnapshot<Map<String, dynamic>> startDocRef =
            await firebaseFirestore.collection('feeds').doc(feedId).get();
        query = query.startAfterDocument(startDocRef);
      }

      // query를 실행하여, snapshot 생성
      QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();

      return await Future.wait(snapshot.docs.map((item) async {
        Map<String, dynamic> data = item.data();

        // feed_model의 writer 멤버 변수는 UserModel 객체이고,
        // fireStore에는 userDocRef(userSnapshot)으로 저장되어 있으므로 따로 변환해야 함
        DocumentReference<Map<String, dynamic>> writerDocRef = data['writer'];
        DocumentSnapshot<Map<String, dynamic>> writerSnapshot =
            await writerDocRef.get();
        UserModel userModel = UserModel.fromMap(writerSnapshot.data()!);

        data['writer'] = userModel;
        return FeedModel.fromMap(data);
      }).toList());
    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }

  /**
   * "내가" "나의 피드"을 삭제
   */
  Future<void> deleteFeed({
    required FeedModel feedModel,
  }) async {
    try {
      /// 1. 이 피드를 좋아요 한 모든 유저들 likes에 접근해서, 이 피드를 삭제한다
      WriteBatch batch = firebaseFirestore.batch();
      DocumentReference<Map<String, dynamic>> feedDocRef =
          firebaseFirestore.collection('feeds').doc(feedModel.feedId);
      DocumentReference<Map<String, dynamic>> writerDocRef =
          firebaseFirestore.collection('users').doc(feedModel.uid);

      // 이 피드를 좋아요한 유저들의 uid 리스트
      List<String> likes = await feedDocRef
          .get()
          .then((value) => List<String>.from(value.data()!['likes']));

      for (var uid in likes) {
        batch.update(firebaseFirestore.collection('users').doc(uid), {
          'feedLikeList': FieldValue.arrayRemove([feedModel.feedId]),
        });
      }

      /// 2. 이 피드(문서) 댓글 폴더(하위 Comment 컬렉션)를 삭제하기 위해서, 일일히 댓글 문서를 전부 삭제한다
      QuerySnapshot<Map<String, dynamic>> commentQuerySnapshot =
          await feedDocRef.collection('comments').get();
      for (var doc in commentQuerySnapshot.docs) {
        batch.delete(doc.reference);
      }

      /// 3. feeds 컬렉션에서 이 피드(문서) 삭제
      batch.delete(feedDocRef);

      /// 4. users 컬렉션에서, 이 피드를 작성한 유저의 feedCount 1 감소
      batch.update(writerDocRef, {
        'feedCount': FieldValue.increment(-1),
      });

      /// 5. 스토리지에 저장된 (피드의) 이미지 파일들도 삭제
      _deleteImage(feedModel.imageUrls);

      await batch.commit();
    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }

  /**
   * "내가" 피드를 업로드
   */
  Future<FeedModel> uploadFeed({
    required List<String> files, // 피드 사진(또는 이미지 파일) 경로 리스트
    required String title, // 피드 제목
    required String content, // 피드 내용
    required String myUid, // 유저 아이디
  }) async {
    // --- 사용자 인증 상태 확인 로직 추가 ---
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      logger.w("경고: 사용자가 로그인되어 있지 않습니다. 피드 업로드를 진행할 수 없습니다."); // logger가 있다면 사용
      throw CustomException(code: "UNAUTHENTICATED", message: "피드를 업로드하려면 로그인이 필요합니다.");
    } else {
      logger.d("현재 로그인된 사용자의 uid : ${currentUser.uid}, 전달받은 uid: $myUid");
    }

    List<String> imageUrls = [];

    // final openaiApiKey = remoteConfig.getString('openai_api_key'); // Firebase 콘솔에 설정한 키
    final geminiApiKey = remoteConfig.getString('gemini_api_key'); // Firebase 콘솔에 설정한 키

    if (geminiApiKey.isEmpty) {
      // API 키를 가져오지 못한 경우의 처리
      logger.w("경고: Remote Config에서 API Key를 가져오지 못했습니다.");
      throw Exception("Remote Config에서 API Key를 가져올 수 없습니다.");
    }

    try {
      /// 예상되는 문제 2. 마지막 유저의 작성글 개수 1 증가를 못했을 때 -> 아예 트랜잭션 롤백
      WriteBatch batch = firebaseFirestore.batch(); // 트랜잭션을 위한 객체

      // uuid는 알파벳 + 숫자로 32글자, -(하이픈) 4글자를 조합해서 만든다. 그 중 버전 1을 사용한다
      String feedId = Uuid().v1();

      // firestore 문서중에서 feeds 컬렉션를 참조할 수 있는 객체 생성
      DocumentReference<Map<String, dynamic>> feedDocRef =
          firebaseFirestore.collection('feeds').doc(feedId);

      // firestore 문서중에서 users 컬렉션를 참조할 수 있는 객체 생성
      DocumentReference<Map<String, dynamic>> userDocRef =
          firebaseFirestore.collection('users').doc(myUid);

      // storage(그 중 feeds 폴더)에 참조할 수 있는 객체 선언
      Reference feedStorageRef = firebaseStorage.ref().child('feeds').child(feedId);

      // List<Future<String>> -> List<String>으로 바꾸기 위해 기다린다는 의미의 함수
      imageUrls = await Future.wait(files.map((item) async {
        String imageId = Uuid().v1();
        TaskSnapshot taskSnapshot = await feedStorageRef.child(imageId).putFile(File(item));
        return await taskSnapshot.ref.getDownloadURL();
      }).toList()); // 스토리지에 저장된 이미지에 접근할 수 있는 경로들을 리스트(imageUrls)에 저장한다

      DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userDocRef.get();
      // userDocRef에서 userSnapshot을 받고, map -> UserModel로 변환해서 저장한다
      UserModel userModel = UserModel.fromMap(userSnapshot.data()!);

      // GPTRepository gptRepository = GPTRepository(apiKey: openaiApiKey);
      GeminiRepository geminiRepository = GeminiRepository(apiKey: geminiApiKey);

      String summary = "";
      // await gptRepository.requestSummary(content.trim()).then((value) {
      //   summary = value;
      // });
      await geminiRepository.requestSummary(content.trim()).then((value) {
        summary = value;
      });

      FeedModel feedModel = FeedModel.fromMap({
        'uid': myUid,
        'feedId': feedId,
        'title': title,
        'content': content,
        'summary': summary,
        'imageUrls': imageUrls,
        'likes': [],
        'commentCount': 0,
        'likeCount': 0,
        'createAt': Timestamp.now(),
        'writer': userModel,
        // 피드를 작성한 유저의 정보를 담고 있는 UserModel 객체, 피드 상단에 프로필 이미지와 닉네임을 띄우기 위해서
        'feedActiveStatus': FeedActiveStatus.cold.name,
      });

      // 첫번째 인수 : 접근하려는 문서, 두번째 인수 : 넣을/수정할 데이터
      batch.set(feedDocRef, feedModel.toMap(userDocRef: userDocRef));

      batch.update(userDocRef, {
        'feedCount': FieldValue.increment(1), // 유저의 작성글 개수 1 증가
      });

      await batch.commit(); // 트랜잭션 커밋
      return feedModel;
    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      _deleteImage(imageUrls);
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      _deleteImage(imageUrls);
      throw CustomException(code: "Exception", message: e.toString());
    }
  }

  /**
   * "내가" 피드 좋아요/취소 동시 구현
   */
  Future<FeedModel> likeFeed({
    required String feedId, // 이 피드 아이디
    required List<String> feedLikes, // 이 피드에 좋아요한 유저들 리스트
    required String myUid, // 본인 uid
    required List<String> userLikes, // 본인이 좋아요한 피드 리스트
  }) async {
    try {
      DocumentReference<Map<String, dynamic>> userDocRef = firebaseFirestore.collection('users').doc(myUid);
      DocumentReference<Map<String, dynamic>> feedDocRef = firebaseFirestore.collection('feeds').doc(feedId);

      /// 1. 피드를 좋아하는 유저 리스트(likes)에 본인 uid가 포함되었는지 확인
      // -> 포함되어 있다면, 좋아요 취소 -> 피드의 likes 필드에서 uid 삭제, 피드의 likeCount 1 감소

      // 1-2. 유저가 좋아하는 피드 리스트(feedLikeList)에 이 피드 feedId가 포함되었는지 확인
      // -> 포함되어 있다면, 좋아요 취소 -> 유저의 feedLikeList 필드에서 feedId 삭제
      // 이번에는 batch 대신 트랜잭션을 사용해서 데이터베이스를 수정할 것이다
      await firebaseFirestore.runTransaction((transaction) async {
        bool isFeedContains = feedLikes.contains(myUid);

        transaction.update(feedDocRef, {
          'likes': isFeedContains
              ? FieldValue.arrayRemove([myUid])
              : FieldValue.arrayUnion([myUid]),
          'likeCount': isFeedContains
              ? FieldValue.increment(-1)
              : FieldValue.increment(1)
        });

        transaction.update(userDocRef, {
          'feedLikeList': userLikes.contains(feedId)
              ? FieldValue.arrayRemove([feedId])
              : FieldValue.arrayUnion([feedId])
        });
      });

      /// 2. 수정된 데이터를 화면에 그리기 위해 -> 좋아요/취소가 반영된 새로운 feedModel을 반환한다
      Map<String, dynamic> feedMapData =
          await feedDocRef.get().then((value) => value.data()!);

      // fireStore에는 feeds 폴더의 "writer"가 Reference로 저장되어 있고, FeedModel에는 UserModel로 저장되어 있기 때문에 변환한다
      DocumentReference<Map<String, dynamic>> writerDocRef =
          feedMapData['writer'];
      Map<String, dynamic> userMapData =
          await writerDocRef.get().then((value) => value.data()!);
      UserModel userModel = UserModel.fromMap(userMapData);
      feedMapData['writer'] = userModel;

      return FeedModel.fromMap(feedMapData);

    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }

  /**
   * 피드 단일 조회 (댓글 작성 ... 등의 로직에 사용)
   */
  Future<FeedModel> getFeed({
    required String feedId, // feedId로 firebase 컬렉션에서 조회
  }) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await firebaseFirestore.collection('feeds').doc(feedId).get();

      Map<String, dynamic> feedModelData = snapshot.data()!;

      // feed_model의 writer 멤버 변수는 UserModel 객체이고,
      // fireStore에는 userDocRef(userSnapshot)으로 저장되어 있으므로 따로 변환해야 함
      DocumentReference<Map<String, dynamic>> writerDocRef = feedModelData['writer'];
      DocumentSnapshot<Map<String, dynamic>> writerSnapshot = await writerDocRef.get();
      UserModel userModel = UserModel.fromMap(writerSnapshot.data()!);

      feedModelData['writer'] = userModel;
      return FeedModel.fromMap(feedModelData);

    } on FirebaseException catch (e) {
      // 1. 파이어베이스 관련 예외
      throw CustomException(code: e.code, message: e.message!);
    } catch (e) {
      // 2. 기타 모든 예외
      throw CustomException(code: "Exception", message: e.toString());
    }
  }

  /**
   * 문제 1. Storage에 이미지는 저장했는데, Firestore에 피드를 저장하지 못했을 때
   * storage에 먼저 저장되었던 이미지를 삭제하는 함수
   */
  Future<void> _deleteImage(List<String> imageUrls) async {
    for (final element in imageUrls) {
      await firebaseStorage.refFromURL(element).delete();
    }
  }
}
