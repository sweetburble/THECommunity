/**
 * Dart에는 없는, 컬렉션에 관한 커스텀 함수를 저장해놓았다
 *
 * 1. 리스트 내 두개의 원소 스왑
 */

extension ListExtension<T> on List<T> {
  void swap(int origin, int target) {
    final temp1 = this[target];
    this[target] = this[origin];
    this[origin] = temp1;
  }

  Stream<T> toStream() => Stream.fromIterable(this);
}
