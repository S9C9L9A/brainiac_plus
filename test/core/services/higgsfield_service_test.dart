import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/core/services/higgsfield_service.dart';

void main() {
  group('GeneratedContent', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'gen-123',
        'type': 'image',
        'status': 'completed',
        'url': 'https://example.com/image.png',
        'thumbnail_url': 'https://example.com/thumb.png',
        'metadata': {'width': 1024, 'height': 1024},
        'created_at': '2026-01-01T10:00:00.000Z',
      };
      final content = GeneratedContent.fromJson(json);
      expect(content.id, 'gen-123');
      expect(content.type, 'image');
      expect(content.status, 'completed');
      expect(content.url, 'https://example.com/image.png');
      expect(content.thumbnailUrl, 'https://example.com/thumb.png');
      expect(content.metadata, isNotNull);
      expect(content.createdAt, DateTime.utc(2026, 1, 1, 10, 0));
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'gen-456',
        'type': 'video',
        'status': 'processing',
        'created_at': '2026-01-01T10:00:00.000Z',
      };
      final content = GeneratedContent.fromJson(json);
      expect(content.url, isNull);
      expect(content.thumbnailUrl, isNull);
      expect(content.metadata, isNull);
    });

    test('isCompleted returns true for completed status', () {
      final content = GeneratedContent(
        id: 'gen-1',
        type: 'image',
        status: 'completed',
        createdAt: DateTime.now(),
      );
      expect(content.isCompleted, true);
      expect(content.isProcessing, false);
      expect(content.isFailed, false);
    });

    test('isProcessing returns true for processing status', () {
      final content = GeneratedContent(
        id: 'gen-1',
        type: 'video',
        status: 'processing',
        createdAt: DateTime.now(),
      );
      expect(content.isProcessing, true);
      expect(content.isCompleted, false);
    });

    test('isFailed returns true for failed status', () {
      final content = GeneratedContent(
        id: 'gen-1',
        type: 'image',
        status: 'failed',
        createdAt: DateTime.now(),
      );
      expect(content.isFailed, true);
      expect(content.isCompleted, false);
    });
  });

  group('HiggsfieldException', () {
    test('toString includes message', () {
      final exception = HiggsfieldException('Generation failed');
      expect(exception.toString(), 'HiggsfieldException: Generation failed');
    });

    test('message property is correct', () {
      final exception = HiggsfieldException('test');
      expect(exception.message, 'test');
    });
  });
}
