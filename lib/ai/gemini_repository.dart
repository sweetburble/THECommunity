import 'dart:convert'; // JSON 인코딩/디코딩을 위한 라이브러리
import 'package:http/http.dart' as http; // HTTP 요청을 위한 라이브러리

import 'package:logger/logger.dart';

class GeminiRepository {
  final String apiKey; // Gemini API Key를 저장할 멤버 변수
  final logger = Logger();

  // 생성자에서 API Key를 요구합니다.
  GeminiRepository({
    required this.apiKey,
  }) {
    // API Key 유효성 검사
    if (apiKey.isEmpty) {
      logger.w("경고: API Key가 비어있습니다. GeminiRepository 기능이 제한될 수 있습니다.");
    }
  }

  /**
   * Gemini API 서버에 텍스트 요약을 요청합니다.
   * @param text 요약할 원본 텍스트
   * @return 요약된 텍스트 또는 오류 메시지
   */
  Future<String> requestSummary(String text) async {
    /// text(피드 내용이) 실질적으로 3줄 이하일 경우, 요약하지 않고 바로 리턴합니다.
    if (countSentences(text) <= 3) {
      return "3줄 요약이 필요없는 피드입니다!";
    }

    // 사용할 Gemini 모델 이름을 지정합니다.
    const String modelName = "gemini-2.5-flash-preview-04-17";

    // Gemini API 엔드포인트 URL을 구성합니다. API Key는 쿼리 파라미터로 추가합니다.
    final url = Uri.https(
      "generativelanguage.googleapis.com", // Gemini API 호스트
      "/v1beta/models/$modelName:generateContent", // 요청 경로 및 모델 지정
      {"key": apiKey}, // API Key 파라미터
    );

    // Gemini API 요청 본문을 구성합니다.
    // 시스템 프롬프트와 사용자 텍스트를 결합하여 전달합니다.
    final requestBody = {
      "systemInstruction": {"parts": [{"text": "You are a three-line summary bot that summarizes whatever text I type into, in three lines of sentences. Please number each line, insert a space and print it out. Please write all the answers in Korean."}]},
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              // 시스템 지침과 실제 요약 요청 텍스트를 함께 전달합니다.
              "text":
              "Summarize below Text:\n${text.trim()}"
            }
          ]
        }
      ],
      // 필요에 따라 생성 관련 설정을 추가할 수 있다.
      "generationConfig": {
        "thinkingConfig": { "thinkingBudget": 0 },
        "maxOutputTokens": 1024, // 최대 출력 토큰 수
        // "temperature": 0.7, // 다양성 조절 (0.0 ~ 1.0)
        // "topP": 0.9, // Top-p 샘플링
        // "topK": 40, // Top-k 샘플링
      }
    };

    try {
      // HTTP POST 요청을 보냅니다.
      final http.Response resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json", // 요청 본문의 타입은 JSON
        },
        body: jsonEncode(requestBody), // 요청 본문을 JSON 문자열로 인코딩
      );

      // 응답 로깅 (디버깅 시 유용)
      logger.d("Gemini API Response Status: ${resp.statusCode}");
      logger.d("Gemini API Response Body: ${utf8.decode(resp.bodyBytes)}");


      if (resp.statusCode == 200) {
        // 요청 성공 시 응답 본문을 JSON으로 디코딩합니다.
        final jsonData = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

        // Gemini API 응답 구조에 따라 요약된 텍스트를 추출합니다.
        // 일반적인 성공 응답: jsonData['candidates'][0]['content']['parts'][0]['text']
        if (jsonData.containsKey('candidates') &&
            jsonData['candidates'] is List &&
            (jsonData['candidates'] as List).isNotEmpty &&
            jsonData['candidates'][0].containsKey('content') &&
            jsonData['candidates'][0]['content'].containsKey('parts') &&
            jsonData['candidates'][0]['content']['parts'] is List &&
            (jsonData['candidates'][0]['content']['parts'] as List).isNotEmpty &&
            jsonData['candidates'][0]['content']['parts'][0].containsKey('text')) {
          return jsonData['candidates'][0]['content']['parts'][0]['text'] as String;
        } else {
          logger.e("Gemini API 응답 형식이 예상과 다릅니다: ${jsonData.toString()}");
          return "피드 요약에 실패했습니다. (응답 형식 오류)";
        }
      } else {
        // API 요청 실패 시 오류 메시지를 처리합니다.
        final errorData = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        String errorMessage = "피드 요약에 실패했습니다. (상태 코드: ${resp.statusCode})";
        if (errorData.containsKey('error') && errorData['error'] is Map) {
          final errorDetails = errorData['error'] as Map<String, dynamic>;
          if (errorDetails.containsKey('message')) {
            errorMessage += " 원인: ${errorDetails['message']}";
          }
        }
        logger.e("Gemini API Error: $errorMessage \nResponse: ${errorData.toString()}");
        return errorMessage;
      }
    } catch (e) {
      // 네트워크 오류 등 예외 발생 시 처리합니다.
      logger.e("Gemini API 요청 중 예외 발생: $e");
      return "피드 요약 중 오류가 발생했습니다.";
    }
  }

  /**
   * 정규표현식을 사용하여 텍스트를 문장 단위로 분할하고, 문장의 개수를 반환합니다.
   * 피드가 3줄(문장) 이하이면 AI 요약을 수행하지 않기 위한 검사 로직입니다.
   * @param text 분석할 텍스트
   * @return 문장의 개수
   */
  int countSentences(String text) {
    // 정규표현식을 사용하여 문장을 분할합니다.
    // (?<!\d)는 앞에 숫자가 없는 경우를 의미합니다 (소수점 제외).
    // (?!\d)는 뒤에 숫자가 없는 경우를 의미합니다 (소수점 제외).
    // [\.\?!]는 마침표, 물음표, 느낌표를 의미합니다.
    // \s+는 하나 이상의 공백을 의미합니다.
    RegExp regex = RegExp(r'(?<!\d)[\.\?!](?!\d)\s+');

    // 정규표현식에 맞는 부분으로 문자열을 분할합니다.
    List<String> sentences = text.split(regex);

    // 분할 후 생성될 수 있는 빈 문자열을 제거합니다.
    sentences.removeWhere((sentence) => sentence.trim().isEmpty);

    // 문장의 개수를 반환합니다.
    return sentences.length;
  }
}

/**
 * --- 테스트를 위한 간단한 main 함수 (실제 앱에서는 사용하지 않음) ---
 */
void main() async {

  // 여기에 실제 Gemini API Key를 입력하세요.
  final geminiRepo = GeminiRepository(apiKey: "test_gemini_key");
  final testText1 = "이것은 테스트 문장입니다. 두 번째 문장이 이어집니다. 그리고 세 번째 문장으로 마무리합니다. 네 번째 문장도 있습니다.";
  final testText2 = "짧은 글입니다.";
  final testText3 = "This is a sample text for summarization. It has several sentences to check the functionality. The goal is to get a three-line summary. Let's see how it works. This is the fifth sentence. And the sixth one.";


  print("\n--- 테스트 1 (4문장 이상) ---");
  String summary1 = await geminiRepo.requestSummary(testText1);
  print("원본: $testText1");
  print("요약 결과:\n$summary1");

  print("\n--- 테스트 2 (3문장 이하) ---");
  String summary2 = await geminiRepo.requestSummary(testText2);
  print("원본: $testText2");
  print("요약 결과:\n$summary2");

  print("\n--- 테스트 3 (영문 텍스트) ---");
  String summary3 = await geminiRepo.requestSummary(testText3);
  print("원본: $testText3");
  print("요약 결과:\n$summary3");
}