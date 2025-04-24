/**
 * Message 모델
 */
class Messages {
  late final String role;
  late final String content;

  Messages({
    required this.role,
    required this.content,
  });

  factory Messages.fromJson(Map<String, dynamic> json) {
    return Messages(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  Map<String, String> toMap() {
    return {
      "role": role,
      "content": content,
    };
  }

  Messages copyWith({
    String? role,
    String? content,
  }) {
    return Messages(
      role: role ?? this.role,
      content: content ?? this.content,
    );
  }
}

/**
 * ChatCompletion 모델, API 통신을 위한 모델이다
 */
class ChatCompletionModel {
  late final String model;
  late final List<Messages> messages;
  late final bool stream;

  ChatCompletionModel({
    required this.model,
    required this.messages,
    required this.stream,
  });

  ChatCompletionModel.fromJson(Map<String, dynamic> json) {
    model = json['model'] as String;
    messages = List.from(json["messages"]).map((e) => Messages.fromJson(e)).toList();
    stream = json['stream'] as bool;
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'messages': messages.map((e) => e.toJson()).toList(),
      'stream': stream,
    };
  }
}