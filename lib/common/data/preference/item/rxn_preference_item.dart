import 'package:THECommu/common/data/preference/item/nullable_preference_item.dart';

import '../app_preferences.dart';

class RxnPreferenceItem<T, R extends Rxn<T>> extends NullablePreferenceItem<T> {
  final R _rxnValue;
  bool _isLoaded = false;

  RxnPreferenceItem(super.key, [super.defaultValue])
      : _rxnValue = createRxnValue<T, R>(defaultValue);

  void _load() {
    _isLoaded = true;
    _rxnValue.value = get();
  }

  @override
  void call(T? value) {
    _rxnValue.value = value;
    super.call(value);
  }

  @override
  Future<bool> set(T? value) {
    _rxnValue.value = value;
    return super.set(value);
  }

  @override
  T? get() {
    if (!_isLoaded) {
      _load();
    }
    final value = AppPreferences.getValue<T?>(this);
    if (_rxnValue.value != value) {
      _rxnValue.value = value;
    }
    return _rxnValue.value;
  }

  @override
  Future<bool> delete() {
    return AppPreferences.deleteValue<T?>(this);
  }

  static R createRxnValue<T, R extends Rxn<T>>([T? defaultValue]) {
    switch (T) {
      case const (int):
        return RxnInt(defaultValue as int?) as R;
      case const (double):
        return RxnDouble(defaultValue as double?) as R;
      case const (bool):
        return RxnBool(defaultValue as bool?) as R;
      case const (String):
        return RxnString(defaultValue as String?) as R;
      default:
        return Rxn<T>(defaultValue) as R;
    }
  }
}
