import 'dart:typed_data';

import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/exceptions/custom_exception.dart';
import 'package:THECommu/riverpods/auth/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:validators/validators.dart';

class SignupScreen extends StatefulHookConsumerWidget {
  static const String routeName = "/sign-up";

  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final TextEditingController _emailEditingController = TextEditingController();
  final TextEditingController _nameEditingController = TextEditingController();
  final TextEditingController _passwordEditingController = TextEditingController();

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  Uint8List? _image; // unsigned integer, 이미지나 동영상같은 바이너리 데이터를 취급할 때 사용
  bool _isEnabled = true; // 회원가입 버튼을 누르면, 가입이 진행되는 동안 다른 위젯을 비활성화하기 위해

  /**
   * 유저 프로필 이미지 선택
   */
  Future<void> selectImage() async {
    ImagePicker imagePicker = ImagePicker();
    // XFile : 안드로이드라던가 ios 기기의 파일 시스템에 접근할 수 있는 클래스
    XFile? file = await imagePicker.pickImage(
      // 이 함수가 실행되면, 갤러리 화면이 열린다 -> 사진을 선택하지 않으면 null
      source: ImageSource.gallery,
      maxHeight: 512, // 사진의 해상도를 512 x 512로 낮춘다
      maxWidth: 512,
    );

    if (file != null) {
      Uint8List newImage = await file.readAsBytes();

      /// setState()안에 async - await를 쓰면 안된다. 따라서 await file.readAsBytes();를 밖으로 뺐다.
      setState(() {
        _image = newImage;
      });
    }
  }

  @override
  void dispose() {
    _emailEditingController.dispose();
    _nameEditingController.dispose();
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
                // 여기서 역정렬, 아래 children에서도 다시 한번 역정렬해서 키보드가 가리지 않게 조치
                children: [
                  // 로고
                  SvgPicture.asset(
                    'assets/image/icon/더커뮤로고_블랙.svg',
                    height: 80,
                  ),
                  height20,
                  // 프로필 사진
                  Container(
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundImage: _image == null
                              ? const AssetImage("assets/image/profile.png")
                              : MemoryImage(_image!), // Uint8List의 데이터를 사용해서 이미지를 만들어 준다
                        ),
                        Positioned(
                          // Stack 내부에서 카메라 아이콘의 위치를 정한다
                          left: 80,
                          bottom: -10,
                          child: IconButton(
                            onPressed: () async {
                              await selectImage();
                            },
                            icon: const Icon(Icons.add_a_photo),
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  height30,

                  // 이메일
                  TextFormField(
                    enabled: _isEnabled,
                    controller: _emailEditingController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "이메일",
                      prefixIcon: Icon(Icons.email),
                      filled: true,
                    ),
                    validator: (value) {
                      // TextFormField의 검증 로직을 직접 작성한다
                      // 1. 아무것도 입력하지 않았을 때
                      // 2. 공백을 입력했을 때 -> 문자열.isEmpty
                      // 3. 이메일 형식이 아닐 때 -> validators 패키지 사용
                      if (value == null ||
                          value.trim().isEmpty ||
                          !isEmail(value.trim())) {
                        return "올바른 이메일을 입력해주세요.";
                      }
                      return null;
                    },
                  ),
                  height20,

                  // 닉네임
                  TextFormField(
                    enabled: _isEnabled,
                    controller: _nameEditingController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "닉네임",
                      prefixIcon: Icon(Icons.account_circle),
                      filled: true,
                    ),
                    validator: (value) {
                      // 3. 이름은 3글자~10글자 사이
                      if (value == null || value.trim().isEmpty) {
                        return "올바른 닉네임을 입력해주세요.";
                      }
                      if (value.length < 3 || value.length > 10) {
                        return "닉네임은 최소 3글자, 최대 10글자까지 입력 가능합니다.";
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
                      labelText: "비밀번호",
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

                  // 패스워드 확인
                  TextFormField(
                    enabled: _isEnabled,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "비밀번호 확인",
                      prefixIcon: Icon(Icons.lock_clock),
                      filled: true,
                    ),
                    validator: (value) {
                      // 3. 6글자 이상이어야 함 -> Firebase의 설정과 같음
                      if (_passwordEditingController.text != value) {
                        return "패스워드가 일치하지 않습니다.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // 회원가입 버튼
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

                            try {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signUp(
                                      email: _emailEditingController.text,
                                      password: _passwordEditingController.text,
                                      nickname: _nameEditingController.text,
                                      profileImage: _image);

                              if (context.mounted) {
                                context.showSnackbar("인증 메일을 전송했습니다.", isFloating: true);
                                context.pop();
                              }

                            } on CustomException catch (e) {
                              setState(() {
                                _isEnabled = true;
                              });
                              if (context.mounted) context.showErrorSnackbar(e.toString());
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 20),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: "회원가입".text.makeWithDefaultFont(),
                  ),
                  height10,

                  // 로그인 화면 이동
                  TextButton(
                    onPressed: _isEnabled
                        ? () => context.pop()
                        : null,
                    child: "이미 회원이신가요? 로그인하기".text.size(16).makeWithDefaultFont(),
                  ),
                ].reversed.toList(),
              ).pSymmetric(h: 30),
            ),
          ),
        ),
      ),
    );
  }
}
