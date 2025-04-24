import 'dart:io';

import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/widget/custom_button_widget.dart';
import 'package:THECommu/riverpods/auth/auth_controller.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * 전화번호 로그인 방법 사용 시 가장 먼저 뜨는 화면
 * 자신의 국가와(국가 코드) + 전화번호를 입력하여 인증번호를 전송하도록 한다
 */
class PhoneNumberInputScreen extends StatefulHookConsumerWidget {
  const PhoneNumberInputScreen({super.key});

  @override
  ConsumerState<PhoneNumberInputScreen> createState() =>
      _PhoneNumberInputScreenState();
}

class _PhoneNumberInputScreenState
    extends ConsumerState<PhoneNumberInputScreen> {
  final countryController = TextEditingController();
  final phoneCodeController = TextEditingController();
  final myPhoneNumberController = TextEditingController();

  // 유효한 전화번호를 입력했는지 검증하기 위해
  final globalKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final countryCode = Platform.localeName.split("_")[1];
    final country = CountryParser.parseCountryCode(countryCode); // countryCode를 넣어주면, Country 객체 반환
    countryController.text = country.name;
    phoneCodeController.text = country.phoneCode;
  }

  @override
  void dispose() {
    countryController.dispose();
    phoneCodeController.dispose();
    myPhoneNumberController.dispose();
    super.dispose();
  }

  /**
   * 입력한 전화번호로 인증번호를 전송한다
   */
  Future<void> sendOTP() async {
    final phoneCode = phoneCodeController.text;
    final phoneNumber = myPhoneNumberController.text;

    final phoneAuthController = ref.read(authControllerProvider.notifier);

    await phoneAuthController.sendOTP(myPhoneNumber: '+$phoneCode$phoneNumber');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // 입력 키보드를 사라지게 하기 위해
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: "loginScreenText1".tr().text.bold.make(),
        ),
        body: Center(
          child: Column(
            children: [
              height20,
              "loginScreenText2".tr().text.make(),
              height20,

              /// 국가 선택 폼
              SizedBox(
                width: 250,
                child: TextFormField(
                  controller: countryController,
                  readOnly: true,
                  // 직접 쓰는 용도가 아니라, showCountryPicker()의 반환값을 사용하기 위해
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  onTap: () => showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    onSelect: (Country country) {
                      countryController.text = country.name;
                      phoneCodeController.text = country.phoneCode;
                    },
                  ),
                ),
              ),
              height20,

              /// 본인 전화번호 입력 폼
              SizedBox(
                width: 250,
                child: Row(
                  // Row 위젯은 항상 children 위젯들의 크기를 확인하는데, TextFormField 위젯은 기본적으로 크기가 정해져있지 않다!
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: phoneCodeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          isDense: true, // 입력 필드의 간격을 줄일 때 사용
                          prefixIconConstraints: BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                          prefixIcon: "+".text.make(),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    width10,
                    Expanded(
                      flex: 2,
                      child: Form( // 유효한 전화번호를 입력했는지 검증하기 위해
                        key: globalKey,
                        child: TextFormField(
                          controller: myPhoneNumberController,
                          decoration: InputDecoration(isDense: true),
                          keyboardType: TextInputType.phone, // 숫자 키보드 표시
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            // 실제 입력도 숫자만 받음
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "loginScreenText1".tr();
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Spacer(),

              CustomButtonWidget(
                buttonText: "next".tr(),
                onPressed: () async {
                  try {
                    FocusScope.of(context).unfocus();

                    final form = globalKey.currentState;
                    if (form == null || !form.validate()) {
                      return;
                    }

                    await sendOTP();
                    if (context.mounted) {
                      context.push("/otp_input");
                    }
                  } catch (e, stackTrace) {
                    MessageDialog(e.toString());
                    logger.e(stackTrace); // 개발자 디버그 용
                  }
                },
              ).pOnly(bottom: 30),
            ],
          ),
        ),
      ),
    );
  }
}
