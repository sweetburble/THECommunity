import 'package:THECommu/common/common.dart';
import 'package:THECommu/riverpods/auth/auth_controller.dart';
import 'package:THECommu/screen/dialog/d_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * 자신의 전화번호로 전송된 인증번호를 입력하는 화면
 */
class OTPInputScreen extends ConsumerWidget {
  const OTPInputScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: "optScreenText1".tr().text.bold.make(),
        ),
        body: Center(
          child: Column(
            children: [
              height20,
              "optScreenText2".tr().text.make(),
              height10,
              Container(
                width: 240,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.green),
                  ),
                ),
                child: OtpTextField(
                  margin: EdgeInsets.zero,
                  numberOfFields: 6,
                  fieldWidth: 35,
                  textStyle: TextStyle(fontSize: 20),
                  hasCustomInputDecoration: true,
                  decoration: InputDecoration(
                    hintText: "-",
                    counterText: "",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onSubmit: (value) async {
                    try {
                      await ref.read(authControllerProvider.notifier).verifyOTP(userOTP: value);

                      if (context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    } catch (e, stackTrace) {
                      MessageDialog(e.toString());
                      logger.e(stackTrace);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
