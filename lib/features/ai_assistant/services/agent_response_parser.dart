import '../models/agent_response.dart';

class AgentResponseParser {
  AgentResponse parse(String response) {
    var content = response;
    String? codeSnippet;
    List<String>? files;

    final codeRegex = RegExp(r'```dart\n([\s\S]*?)```');
    final codeMatch = codeRegex.firstMatch(response);
    if (codeMatch != null) {
      codeSnippet = codeMatch.group(1)?.trim();
      content = response.replaceFirst(codeRegex, '[Code snippet attached]');
    }

    final fileRegex = RegExp(r'lib/[\w/]+\.dart');
    final fileMatches = fileRegex.allMatches(response);
    if (fileMatches.isNotEmpty) {
      files = fileMatches.map((m) => m.group(0)!).toList();
    }

    return AgentResponse(
      content: content,
      codeSnippet: codeSnippet,
      filesPaths: files,
    );
  }
}
