import 'package:brainiac_plus/routes/app_routes.dart';
import 'package:brainiac_plus/routes/route_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backWrapTitle — back-less tab routes get a back bar', () {
    test('tab screens without their own back button are wrapped', () {
      expect(
        RouteGenerator.backWrapTitle(AppRoutes.fileManager),
        'File Manager',
      );
      expect(RouteGenerator.backWrapTitle(AppRoutes.terminal), 'Terminal');
      expect(RouteGenerator.backWrapTitle(AppRoutes.packages), 'Packages');
      expect(RouteGenerator.backWrapTitle(AppRoutes.settings), 'Settings');
    });

    test('detail screens (own back) and unknown routes are not wrapped', () {
      expect(RouteGenerator.backWrapTitle(AppRoutes.cpuDetail), isNull);
      expect(RouteGenerator.backWrapTitle(AppRoutes.gpuDetail), isNull);
      expect(RouteGenerator.backWrapTitle(AppRoutes.dashboard), isNull);
      expect(RouteGenerator.backWrapTitle('/nope'), isNull);
      expect(RouteGenerator.backWrapTitle(null), isNull);
    });
  });
}
