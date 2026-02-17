import 'package:flutter_test/flutter_test.dart';
import 'package:brainiac_plus/core/services/instagram_service.dart';

void main() {
  group('InstagramProfile', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': '12345',
        'username': 'testuser',
        'account_type': 'BUSINESS',
        'media_count': 42,
        'followers_count': 1000,
      };
      final profile = InstagramProfile.fromJson(json);
      expect(profile.id, '12345');
      expect(profile.username, 'testuser');
      expect(profile.accountType, 'BUSINESS');
      expect(profile.mediaCount, 42);
      expect(profile.followersCount, 1000);
    });

    test('fromJson handles missing followers_count', () {
      final json = {
        'id': '12345',
        'username': 'testuser',
        'account_type': 'PERSONAL',
        'media_count': 10,
      };
      final profile = InstagramProfile.fromJson(json);
      expect(profile.followersCount, 0);
    });
  });

  group('MediaInsights', () {
    test('fromJson parses metrics correctly', () {
      final json = {
        'data': [
          {
            'name': 'engagement',
            'values': [{'value': 150}],
          },
          {
            'name': 'impressions',
            'values': [{'value': 5000}],
          },
          {
            'name': 'reach',
            'values': [{'value': 3000}],
          },
          {
            'name': 'saved',
            'values': [{'value': 25}],
          },
        ],
      };
      final insights = MediaInsights.fromJson(json);
      expect(insights.engagement, 150);
      expect(insights.impressions, 5000);
      expect(insights.reach, 3000);
      expect(insights.saved, 25);
    });

    test('fromJson handles empty values list', () {
      final json = {
        'data': [
          {
            'name': 'engagement',
            'values': [],
          },
        ],
      };
      final insights = MediaInsights.fromJson(json);
      expect(insights.engagement, 0);
      expect(insights.impressions, 0);
      expect(insights.reach, 0);
      expect(insights.saved, 0);
    });

    test('fromJson handles missing metrics', () {
      final json = {
        'data': [],
      };
      final insights = MediaInsights.fromJson(json);
      expect(insights.engagement, 0);
      expect(insights.impressions, 0);
      expect(insights.reach, 0);
      expect(insights.saved, 0);
    });
  });

  group('InstagramException', () {
    test('toString includes message', () {
      final exception = InstagramException('Auth failed');
      expect(exception.toString(), 'InstagramException: Auth failed');
    });

    test('message property is correct', () {
      final exception = InstagramException('test');
      expect(exception.message, 'test');
    });
  });
}
