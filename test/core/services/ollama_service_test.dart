import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/core/services/ollama_service.dart';

void main() {
  group('OllamaService', () {
    test('creates with default values', () {
      final service = OllamaService();
      expect(service.baseUrl, 'http://localhost:11434');
      expect(service.model, 'codellama:7b');
    });

    test('creates with custom values', () {
      final service = OllamaService(
        baseUrl: 'http://custom:1234',
        model: 'llama3',
      );
      expect(service.baseUrl, 'http://custom:1234');
      expect(service.model, 'llama3');
    });
  });

  group('ChatMessage', () {
    test('toJson returns correct map', () {
      final message = ChatMessage(role: 'user', content: 'Hello');
      final json = message.toJson();
      expect(json['role'], 'user');
      expect(json['content'], 'Hello');
    });

    test('system factory creates system message', () {
      final message = ChatMessage.system('You are a helpful assistant');
      expect(message.role, 'system');
      expect(message.content, 'You are a helpful assistant');
    });

    test('user factory creates user message', () {
      final message = ChatMessage.user('Hello');
      expect(message.role, 'user');
      expect(message.content, 'Hello');
    });

    test('assistant factory creates assistant message', () {
      final message = ChatMessage.assistant('Hi there!');
      expect(message.role, 'assistant');
      expect(message.content, 'Hi there!');
    });
  });

  group('OllamaException', () {
    test('toString includes message', () {
      final exception = OllamaException('test error');
      expect(exception.toString(), 'OllamaException: test error');
    });

    test('message property is correct', () {
      final exception = OllamaException('test error');
      expect(exception.message, 'test error');
    });
  });
}
