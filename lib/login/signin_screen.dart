import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/riverpods/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:validators/validators.dart';

import '../../common/common.dart';
import 'signup_screen.dart';

class SigninScreen extends StatefulHookConsumerWidget {
  static const String routeName = "/sign-in";

  const SigninScreen({super.key});

  @override
  ConsumerState<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends ConsumerState<SigninScreen> {
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final TextEditingController _emailEditingController = TextEditingController();
  final TextEditingController _passwordEditingController = TextEditingController();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _isEnabled = true; // 로그인 버튼을 누르면, 로그인이 진행되는 동안 다른 위젯을 비활성화하기 위해

  @override
  void dispose() {
    _emailEditingController.dispose();
    _passwordEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        // FocusScope()로 현재 어디에 focus가 있는지 찾고, unfocus()로 그걸 해제한다
        child: Scaffold(
          body: Center(
            child: Form(
              key: _globalKey,
              // 검증 로직 정책을 설정한다 -> 처음에는 가만히 있다가 회원가입을 누른 순간부터는 지속적으로 체크한다
              autovalidateMode: _autoValidateMode,
              child: ListView(
                shrinkWrap: true,
                // ListView가 내부의 콘텐츠만큼만 크기를 갖는다
                reverse: true,
                // children에 담긴 콘텐츠를 거꾸로 표현한다.
                // 아래를 보면 children에 revered.toList()가 붙어있다. 이는 텍스트폼에 입력할 때 키보드에 가려지지않기 위해서 한 꼼수이다.
                children: [
                  // 로고
                  SvgPicture.asset(
                    'assets/image/icon/더커뮤로고_블랙.svg',
                    height: 80,
                  ),
                  height20,
                  // 이메일
                  TextFormField(
                    enabled: _isEnabled,
                    controller: _emailEditingController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                    ),
                    validator: (value) {
                      // TextFormField의 검증 로직을 직접 작성한다
                      // 1. 아무것도 입력하지 않았을 때
                      // 2. 공백을 입력했을 때 -> 문자열.isEmpty
                      // 3. 이메일 형식이 아닐 때
                      if (value == null ||
                          value.trim().isEmpty ||
                          !isEmail(value.trim())) {
                        return "올바른 이메일을 입력해주세요.";
                      }
                      return null;
                    },
                  ),
                  height20,

                  // 패스워드
                  TextFormField(
                    enabled: _isEnabled,
                    controller: _passwordEditingController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '비밀번호',
                      prefixIcon: Icon(Icons.lock),
                      filled: true,
                    ),
                    validator: (value) {
                      // 3. 6글자 이상이어야 함 -> Firebase의 설정과 같음
                      if (value == null || value.trim().isEmpty) {
                        return "올바른 패스워드를 입력해주세요.";
                      }
                      if (value.length < 6) {
                        return "패스워드는 6글자 이상 입력해주세요.";
                      }
                      return null;
                    },
                  ),
                  height20,

                  // 로그인 버튼
                  ElevatedButton(
                    onPressed: _isEnabled
                        ? () async {
                            final form =
                                _globalKey.currentState; // formState를 반환한다

                            setState(() {
                              // signup_screen에서만 사용하는 변수니까 setState()로도 충분하다
                              _autoValidateMode = AutovalidateMode.always;
                            });

                            // formState는 validate() 함수를 호출해서,
                            // 해당 글로벌 키를 키값으로 갖고 있는 form 위젯 안에 있는 모든 텍스트 폼의 Validator를 일괄적으로 실행한다.
                            if (form == null || !form.validate()) {
                              return;
                            }

                            setState(() {
                              _isEnabled = false;
                            });

                            // 로그인 로직 진행
                            try {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signIn(
                                    email: _emailEditingController.text,
                                    password: _passwordEditingController.text,
                                  );
                            } on CustomException catch (e) {
                              setState(() {
                                _isEnabled = true;
                              });
                              if (context.mounted) context.showErrorSnackbar(e.toString());
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      textStyle: TextStyle(fontSize: 20),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: "로그인".text.makeWithDefaultFont(),
                  ),
                  height10,

                  // 회원가입 화면으로 이동
                  TextButton(
                    onPressed: _isEnabled
                        ? () => context.push(SignupScreen.routeName)
                        : null,
                    child: "회원이 아니신가요? 회원가입하기".text.size(16).makeWithDefaultFont(),
                  ),
                ].reversed.toList(),
              ),
            ).pSymmetric(h: 30),
          ),
        ),
      ),
    );
  }
}
