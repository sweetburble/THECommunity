import 'package:THECommu/common/util/local_notifications.dart';
import 'package:THECommu/common/util/logger.dart';
import 'package:THECommu/firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'common/data/preference/app_preferences.dart';

/**
 * 유저의 폰에 저장되어 있는 연락처에 접근할 수 있도록 권한 요청
 */
Future<void> requestPermission() async {
  // [필수] 연락처 권한을 요청한다, 변수에는 권한을 허락/거부 했는지 저장된다, 다양한 거부 타입이 있다
  final contactPermissionStatus = await Permission.contacts.request();

  // [필수] 알림 권한을 요청한다 -> flutter_local_notifications 패키지가 푸시 메시지를 보내기 위해 사용한다
  final notificationsPermissionStatus = await LocalNotifications.requestNotificationsPermission() ?? false;

  // 연락처 or 알림 권한 상태가 거부/영구 거부일 때는 기기의 앱 설정 화면으로 이동하여, 사용자가 직접 허용하도록 한다
  if (contactPermissionStatus.isDenied || contactPermissionStatus.isPermanentlyDenied || notificationsPermissionStatus == false) {
    await openAppSettings();
    SystemNavigator.pop(); // "앱 밖"으로 나갔던 화면을 뒤로가기 한다
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppPreferences.init();

  /// Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase Remote Config 인스턴스 가져오기
  final remoteConfig = FirebaseRemoteConfig.instance;

  // Remote Config를 Fetch하는 간격 설정 (너무 짧으면 제한될 수 있음, 개발 중에는 짧게 설정 가능)
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(minutes: 1), // Fetch 타임아웃
    minimumFetchInterval: const Duration(hours: 1), // 최소 Fetch 간격 (프로덕션에서는 더 길게)
  ));

  // 앱 내 기본값 설정 (네트워크 연결 실패 또는 첫 실행 시 사용될 값)
  // 중요: 여기에 실제 API Key를 넣으면 안 된다! 빈 문자열이나 플레이스홀더 사용
  await remoteConfig.setDefaults(const {
    // Firebase 콘솔의 매개변수 키와 동일하게
    "openai_api_key": "",
    "gemini_api_key": "",
  });

  // Remote Config 값 가져오기 및 활성화 (앱 시작 시 시도)
  try {
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    // 실패 시 기본값 사용 또는 에러 처리 로직
    logger.w('Remote Config fetch failed: $e');
  }

  // local_notifications.dart 초기화
  await LocalNotifications.init();

  /// 연락처+알림 권한 요청
  await requestPermission();

  runApp(EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('ko')],
    fallbackLocale: const Locale('en'),
    path: 'assets/translations',
    useOnlyLangCode: true,
    child: ProviderScope(child: const App()),
  ));
}
