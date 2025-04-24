import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/**
 * flutter_local_notifications 패키지로 푸시 메시지를 구현하기 위한 환경 설정
 */
class LocalNotifications {
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /**
   * 유저에게 알림 권한을 요청하는 함수 -> true/false를 반환
   */
  static Future<bool?> requestNotificationsPermission() async {
    return await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!
        .requestNotificationsPermission();
  }

  /**
   * 실제로 푸시 메시지를 보내는 동작을 하는 함수
   */
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
  }) async {
    // 원래는 적절한 channelId와 channelName을 넣어야 한다!
    const androidNotificationDetails = AndroidNotificationDetails(
      'id', 'name',
    );

    const notificationDetails = NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
  }
}
