import 'package:brainiac_plus/features/settings/services/endpoint_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validator = EndpointValidator();

  group('EndpointValidator — normalization', () {
    test('adds the http scheme when missing', () {
      final v = validator.validate('localhost:8080');
      expect(v.error, isNull);
      expect(v.normalized, 'http://localhost:8080');
    });

    test('strips trailing slashes', () {
      expect(
        validator.validate('http://localhost:8080/').normalized,
        'http://localhost:8080',
      );
      expect(
        validator.validate('http://localhost:8080///').normalized,
        'http://localhost:8080',
      );
    });

    test('keeps https, ports, IPs and base paths', () {
      expect(
        validator.validate('https://my.server:11434/v1/').normalized,
        'https://my.server:11434/v1',
      );
      expect(
        validator.validate('192.168.1.10:11434').normalized,
        'http://192.168.1.10:11434',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        validator.validate('  http://localhost:8080  ').normalized,
        'http://localhost:8080',
      );
    });

    test('empty input clears the endpoint without an error', () {
      final v = validator.validate('   ');
      expect(v.normalized, isNull);
      expect(v.error, isNull);
    });
  });

  group('EndpointValidator — rejection', () {
    test('rejects unsupported schemes', () {
      expect(validator.validate('ftp://server:21').error, isNotNull);
    });

    test('rejects URLs without a host', () {
      expect(validator.validate('http://').error, isNotNull);
    });

    test('rejects garbage input', () {
      expect(validator.validate('not a url!!').error, isNotNull);
    });
  });
}
