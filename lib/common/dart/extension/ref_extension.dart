import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

extension on Ref<Object?> {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer(duration, () {
      link.close();
    });
  }
}
/**
 * 피드의 링크를 {duration} 동안 살려놓았다가,
 * 시간 안에 다시 접속하면 -> 그대로 피드을 보여주고
 * 시간이 지났다면 -> 서버에서 다시 데이터를 받아와 보여준다
 *
 * Ref 객체는 프로바이더(provider)와 관련된 데이터를 관리하고 수명 주기를 제어하는 데 사용된다.
    구체적인 역할 3가지
    1. Ref에 기능 추가:
    Dart의 확장(extension) 기능을 활용하여 Ref<Object?> 클래스에 새로운 메서드인 cacheFor(Duration duration)을 추가했다.
    이 메서드는 특정 기간 동안 Ref 객체를 유지(keep alive)한 후 자동으로 제거(close)하도록 설계되었다.
    2. 메서드 동작:
    keepAlive() 메서드는 Riverpod의 AutoDispose 프로바이더에서 수명을 연장할 수 있도록 하는 기능이다.
    cacheFor 메서드는 지정된 duration 동안 Ref 객체를 유지하고, 이후에는 link.close()를 호출하여 수명을 종료한다.
    3. 유틸리티 제공:
    이 확장은 Riverpod에서 특정 프로바이더를 일정 시간 동안 캐싱하거나 유지해야 할 때 유용하게 사용할 수 있다.
    예를 들어, 네트워크 요청 결과나 계산 비용이 높은 데이터를 일정 시간 동안 유지하고 싶을 때 활용할 수 있다.
 */
