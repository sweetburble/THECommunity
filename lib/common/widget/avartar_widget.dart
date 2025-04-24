import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/auth/auth_provider.dart';
import 'package:THECommu/screen/main/tab/profile/f_profile.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:nav/nav.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * 유저의 프로필 이미지를 원으로 표시하는 위젯
 * + 클릭하면 그 유저의 프로필 화면으로 이동한다
 * TODO: 나중에 phoneUserModel이랑 일반 UserModel을 통합하면, CircleAvatar 쓴거 다 이 위젯으로 통합하기
 */
class AvatarWidget extends ConsumerWidget {
  final UserModel userModel;
  final bool isTap; // 이 위젯을 클릭하면 Profile 프래그먼트로 이동하는지/하지 않는지
  final double radius; // 기본값 18

  const AvatarWidget({
    super.key,
    required this.userModel,
    required this.isTap,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String myUid = ref.read(authStateProvider).value!.uid;

    if (isTap) {
      return GestureDetector(
        onTap: () {
          if (myUid != userModel.uid) { // 프로필 이미지를 클릭해서 프로필 화면으로 이동할 때는 "내 프로필"은 제외한다
            Nav.push(ProfileFragment(uid: userModel.uid));
          }
        },
        child: CircleAvatar(
          backgroundImage: userModel.profileImage == null
              ? ExtendedAssetImageProvider('assets/image/profile.png')
                  as ImageProvider
              : ExtendedNetworkImageProvider(userModel.profileImage!),
          radius: radius,
        ),
      );
    }

    return CircleAvatar(
      backgroundImage: userModel.profileImage == null
          ? ExtendedAssetImageProvider('assets/image/profile.png')
              as ImageProvider
          : ExtendedNetworkImageProvider(userModel.profileImage!),
      radius: radius,
    );
  }
}
