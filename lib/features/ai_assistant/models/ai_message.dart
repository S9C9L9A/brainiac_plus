/// AI Chat Message model
class AiMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isError;
  final String? codeSnippet;
  final List<String>? filesPaths;

  AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
    this.codeSnippet,
    this.filesPaths,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
        'codeSnippet': codeSnippet,
        'filesPaths': filesPaths,
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) => AiMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isError: json['isError'] as bool? ?? false,
        codeSnippet: json['codeSnippet'] as String?,
        filesPaths: (json['filesPaths'] as List?)?.cast<String>(),
      );
}

/// User message
AiMessage userMessage(String content) => AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );

/// Assistant message
AiMessage assistantMessage(
  String content, {
  String? codeSnippet,
  List<String>? filesPaths,
}) =>
    AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
      codeSnippet: codeSnippet,
      filesPaths: filesPaths,
    );

/// Error message
AiMessage errorMessage(String content) => AiMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
      isError: true,
    );
