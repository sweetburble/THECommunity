/**
 * 유저 데이터모델
 */
class UserModel {
  final String uid; // 유저의 고유 식별 아이디 (랜덤하게 부여됨)
  final String nickname; // 유저 닉네임
  final String email; // 유저 이메일
  final String? profileImage; // 유저 프로필 이미지
  final int feedCount; // 유저가 작성한 피드 수
  final List<String> followers; // 유저의 팔로워 리스트
  final List<String> following; // 유저가 팔로잉한 다른 유저 리스트
  final List<String> feedLikeList; // 유저가 좋아요 누른 피드 리스트

  const UserModel({
    required this.uid,
    required this.nickname,
    required this.email,
    required this.profileImage,
    required this.feedCount,
    required this.followers,
    required this.following,
    required this.feedLikeList,
  });

  factory UserModel.init() {
    return const UserModel(
      uid: '',
      nickname: '',
      email: '',
      profileImage: null,
      feedCount: 0,
      followers: [],
      following: [],
      feedLikeList: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'email': email,
      'profileImage': profileImage,
      'feedCount': feedCount,
      'followers': followers,
      'following': following,
      'feedLikeList': feedLikeList,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      nickname: map['nickname'],
      email: map['email'],
      profileImage: map['profileImage'],
      feedCount: map['feedCount'],
      followers: List<String>.from(map['followers']),
      following: List<String>.from(map['following']),
      feedLikeList: List<String>.from(map['feedLikeList']),
    );
  }

  UserModel copyWith({
    String? uid,
    String? nickname,
    String? email,
    String? profileImage,
    int? feedCount,
    List<String>? followers,
    List<String>? following,
    List<String>? feedLikeList,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      profileImage: profileImage,
      feedCount: feedCount ?? this.feedCount,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      feedLikeList: feedLikeList ?? this.feedLikeList,
    );
  }

  @override
  String toString() {
    return 'UserModel{uid: $uid, nickname: $nickname, email: $email, profileImage: $profileImage, feedCount: $feedCount, followers: $followers, following: $following, feedLikeList: $feedLikeList}';
  }
}
