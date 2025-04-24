/**
 * 직접 만든 에러 처리 클래스
 */
class CustomException implements Exception {

  final String code; // 에러 코드
  final String message; // 에러 메시지

  CustomException({
    required this.code,
    required this.message
  });

  @override
  String toString() {
    return message;
  }
}


