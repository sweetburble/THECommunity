import 'package:THECommu/login/otp_input_screen.dart';
import 'package:THECommu/login/phone_number_input_screen.dart';
import 'package:THECommu/login/signin_screen.dart';
import 'package:THECommu/login/signup_screen.dart';
import 'package:THECommu/screen/DM/chat_screen.dart';
import 'package:THECommu/screen/auth_checker.dart';
import 'package:THECommu/screen/group_chat/create_group_room_screen.dart';
import 'package:THECommu/screen/group_chat/group_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screen/DM/f_dm.dart';

/**
 * app.dart가 사용하는 모든 go_router의 route를 여기에 분리하여 정의
 */
GoRouter makeGoRouter({
  required GlobalKey<NavigatorState> navigatorKey, // Nav을 위한 globalKey
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: "/",
    routes: [
      GoRoute(
        path: "/",
        builder: (context, state) => AuthChecker(),
        // routes: [
        //   GoRoute(
        //     path: "cart/:uid",
        //     builder: (context, state) => CartScreen(
        //       uid: state.pathParameters["uid"] ?? "",
        //     ),
        //   ),
        //   GoRoute(
        //     path: "product",
        //     builder: (context, state) {
        //       return ProductDetailScreen(product: state.extra as Product);
        //     },
        //   ),
        //   GoRoute(
        //     path: "product/add",
        //     builder: (context, state) => ProductAddScreen(),
        //   ),
        // ],
      ),
      GoRoute(
        path: DMFragment.routeName, // "/dm-fragment"
        builder: (context, state) => DMFragment(),
      ),
      GoRoute(
        path: "/phone_num_input",
        builder: (context, state) => PhoneNumberInputScreen(),
      ),
      GoRoute(
        path: "/otp_input",
        builder: (context, state) => OTPInputScreen(),
      ),
      GoRoute(
        path: SigninScreen.routeName, // "/sign-in"
        builder: (context, state) => SigninScreen(),
      ),
      GoRoute(
        path: SignupScreen.routeName, // "/sign-up"
        builder: (context, state) => SignupScreen(),
      ),
      GoRoute(
        path: ChatScreen.routeName, // "/chat-screen"
        builder: (context, state) => ChatScreen(),
      ),
      GoRoute(
        path: CreateGroupRoomScreen.routeName, // "/create-group-room"
        builder: (context, state) => CreateGroupRoomScreen(),
      ),
      GoRoute(
        path: GroupChatScreen.routeName, // "/group-chat-screen"
        builder: (context, state) => GroupChatScreen(),
      ),
    ],
  );
}
