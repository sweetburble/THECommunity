import 'dart:convert';

import 'package:THECommu/common/common.dart';
import 'package:http/http.dart' as http;

import 'model/open_ai_model.dart';

class GPTRepository {
  final String apiKey; // API Key를 저장할 멤버 변수

  // 생성자에서 API Key를 요구합니다.
  GPTRepository({
    required this.apiKey,
  }) {
    // API Key 유효성 검사 (선택 사항이지만 권장)
    if (apiKey.isEmpty) {
      logger.w("API Key가 비어있습니다. GPTRepository 기능이 제한될 수 있습니다.");
      // 또는 throw Exception("API Key는 비어 있을 수 없습니다.");
    }
  }

  /**
   * ChatGPT 서버 요청
   */
  Future<String> requestSummary(String text) async {
    /// text(피드 내용이) 실질적으로 3줄 이하일 경우, 요약하지 않고 바로 리턴
    if (countSentences(text) <= 3) {
      return "3줄 요약이 필요없는 피드입니다!";
    }

    ChatCompletionModel openAiModel = ChatCompletionModel(
      model: "gpt-4o-mini",
      messages: [
        Messages(
          role: "system",
          content: "You are a three-line summary bot that summarizes whatever text I type into, in three lines of sentences. Please number each line, insert a space and print it out.",
        ),
        Messages(
          role: "user",
          content: text.trim(),
        ),
      ],
      stream: false,
    );
    final url = Uri.https("api.openai.com", "/v1/chat/completions");
    final resp = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode(openAiModel.toJson()),
    );
    logger.d(utf8.decode(resp.bodyBytes));

    if (resp.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(resp.bodyBytes)) as Map;
      // String role = jsonData["choices"][0]["message"]["role"]; // -> "assistant"
      String content = jsonData["choices"][0]["message"]["content"];
      return content;
    } else {
      return "피드 요약에 실패했습니다...";
    }
  }

  /**
   * 정규표현식을 사용하여 피드를 문장 단위로 분할한다.
   * 따라서 피드가 3줄 이하이면, AI 3줄 요약은 하지 않는다.
   */
  int countSentences(String text) {
    // 정규표현식을 사용하여 문장을 분할합니다.
    // (?<!\d)는 앞에 숫자가 없는 경우를 의미합니다 (소수점 제외)
    // (?!\d)는 뒤에 숫자가 없는 경우를 의미합니다 (소수점 제외)
    // [\.\?!]는 마침표, 물음표, 느낌표를 의미합니다
    // \s+는 하나 이상의 공백을 의미합니다
    RegExp regex = RegExp(r'(?<!\d)[\.\?!](?!\d)\s+');

    // 정규표현식에 맞는 부분으로 문자열을 분할합니다
    List<String> sentences = text.split(regex);

    // 빈 문장을 제거합니다
    sentences.removeWhere((sentence) => sentence.trim().isEmpty);

    // 문장의 갯수를 반환합니다
    return sentences.length;
  }
}