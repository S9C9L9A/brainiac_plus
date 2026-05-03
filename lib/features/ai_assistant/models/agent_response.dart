class AgentResponse {
  final String content;
  final String? codeSnippet;
  final List<String>? filesPaths;

  const AgentResponse({
    required this.content,
    this.codeSnippet,
    this.filesPaths,
  });
}
