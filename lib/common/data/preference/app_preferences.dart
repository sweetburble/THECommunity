import 'package:THECommu/common/theme/custom_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'item/preference_item.dart';

export 'package:get/get_rx/get_rx.dart';
export 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

/**
 * SharedPreference를 쓸 때, 최대한 반복되는 코드를 줄이기 위해 제네릭으로 만든 커스텀 클래스!
 * 사용방법 : prefs.dart에 원하는 key-value을 만들어 사용한다.
 *
 * 종류는 item 폴더에 4종류가 있다.
 */
class AppPreferences {
  static const String prefix = 'AppPreference.';

  static late final SharedPreferences _prefs;

  static String getPrefKey(PreferenceItem item) {
    return '${AppPreferences.prefix}${item.key}';
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    return;
  }

  static bool checkIsNullable<T>() => null is T;

  static Future<bool> setValue<T>(PreferenceItem<T> item, T? value) async {
    final String key = getPrefKey(item);
    final isNullable = checkIsNullable<T>();

    if (isNullable && value == null) {
      // null을 세팅한다는 것은 값을 지운다는 의미로 해석. 필요에 따라 변경해서 쓰시면 됩니다
      return _prefs.remove(item.key);
    }

    if (isNullable) {
      switch (T.toString()) {
        case "int?":
          return _prefs.setInt(key, value as int);
        case "String?":
          return _prefs.setString(key, value as String);
        case "double?":
          return _prefs.setDouble(key, value as double);
        case "bool?":
          return _prefs.setBool(key, value as bool);
        case "List<String>?":
          return _prefs.setStringList(key, value as List<String>);
        case "DateTime?":
          return _prefs.setString(key, (value as DateTime).toIso8601String());
        default:
          if (value is Enum) {
            return _prefs.setString(key, value.name);
          } else {
            throw Exception('$T 타입에 대한 저장 transform 함수를 추가해 주세요.');
          }
      }
    } else {
      switch (T) {
        case const (int):
          return _prefs.setInt(key, value as int);
        case const (String):
          return _prefs.setString(key, value as String);
        case const (double):
          return _prefs.setDouble(key, value as double);
        case const (bool):
          return _prefs.setBool(key, value as bool);
        case const (List<String>):
          return _prefs.setStringList(key, value as List<String>);
        case const (DateTime):
          return _prefs.setString(key, (value as DateTime).toIso8601String());
        default:
          if (value is Enum) {
            return _prefs.setString(key, value.name);
          } else {
            throw Exception('$T 타입에 대한 저장 transform 함수를 추가해 주세요.');
          }
      }
    }
  }

  static Future<bool> deleteValue<T>(PreferenceItem<T> item) async {
    final String key = getPrefKey(item);
    return _prefs.remove(key);
  }

  static T getValue<T>(PreferenceItem<T> item) {
    final String key = getPrefKey(item);
    switch (T) {
      case const (int):
        return _prefs.getInt(key) as T? ?? item.defaultValue;
      case const (String):
        return _prefs.getString(key) as T? ?? item.defaultValue;
      case const (double):
        return _prefs.getDouble(key) as T? ?? item.defaultValue;
      case const (bool):
        return _prefs.getBool(key) as T? ?? item.defaultValue;
      case const (List<String>):
        return _prefs.getStringList(key) as T? ?? item.defaultValue;
      default:
        return transform(T, _prefs.getString(key)) ?? item.defaultValue;
    }
  }

  static T? transform<T>(Type t, String? value) {
    if (value == null) {
      return null;
    }

    bool isNullableType = checkIsNullable<T>();
    if (isNullableType) {
      switch (t.toString()) {
        case "CustomTheme?":
          return CustomTheme.values.asNameMap()[value] as T?;
        case "DateTime?":
          return DateTime.parse(value) as T?;
        default:
          throw Exception('$t 타입에 대한 transform 함수를 추가해 주세요.');
      }
    } else {
      switch (t) {
        case CustomTheme _:
          return CustomTheme.values.asNameMap()[value] as T?;
        case DateTime _:
          return DateTime.parse(value) as T?;
        default:
          throw Exception('$t 타입에 대한 transform 함수를 추가해 주세요.');
      }
    }
  }
}
