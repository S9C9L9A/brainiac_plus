class AgentProfile {
  final String id;
  final String name;
  final String description;
  final List<String> domainPaths;
  final List<String> keywords;
  final List<String> allowedPaths;
  final String systemPrompt;

  const AgentProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.domainPaths,
    required this.keywords,
    required this.allowedPaths,
    required this.systemPrompt,
  });

  bool matches(String text) {
    final lower = text.toLowerCase();
    return keywords.any((k) => lower.contains(k));
  }
}
