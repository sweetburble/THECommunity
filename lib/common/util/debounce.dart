import 'dart:async';
import 'package:flutter/material.dart';

/**
 * 디바운스를 직접 구현
 * ※ VoidCallback은 dart:html이 아닌, material 패키지를 사용해야 한다
 */
class Debounce {
  final int milliseconds;
  Timer? _timer;

  Debounce({
    required this.milliseconds,
  });

  void run(VoidCallback voidCallback) {
    if (_timer != null) { // 아직 이전 디바운스의 대기 시간(millseconds)이 끝나지 않았으면, 기다린다
      _timer!.cancel();
    }

    // 타이머가 null이면(= 대기 시간이 없는 상태면), 새로운 디바운스를 만든다 -> 콜백 함수를 실행한다
    _timer = Timer(Duration(milliseconds: milliseconds), voidCallback);

  }
}