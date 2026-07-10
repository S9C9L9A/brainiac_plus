import 'package:brainiac_plus/core/platform/package_service.dart';
import 'package:brainiac_plus/features/packages/controllers/package_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePackageService extends PackageService {
  List<PackageInfo> aptPackages = [];
  String installResult = 'Package installed successfully';
  String removeResult = 'Package removed successfully';
  int listCalls = 0;

  @override
  Future<List<PackageInfo>> listAptPackages() async {
    listCalls++;
    return aptPackages;
  }

  @override
  Future<List<PackageInfo>> listSnapPackages() async => [];

  @override
  Future<String> installPackage(String packageName, String source) async =>
      installResult;

  @override
  Future<String> removePackage(String packageName, String source) async =>
      removeResult;
}

PackageInfo pkg(String name) =>
    PackageInfo(name: name, version: '1.0', isInstalled: true, source: 'apt');

void main() {
  late FakePackageService service;
  late PackageController controller;

  setUp(() async {
    service = FakePackageService();
    controller = PackageController(packageService: service);
    // Let the initial loadPackages() from the constructor settle.
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'successful install reloads the list and surfaces the message',
    () async {
      service.aptPackages = [pkg('htop')];
      final listCallsBefore = service.listCalls;

      await controller.installPackage('htop', 'apt');

      expect(service.listCalls, listCallsBefore + 1);
      expect(controller.state.packages.map((p) => p.name), contains('htop'));
      expect(controller.state.lastOperationMessage, contains('success'));
      expect(controller.state.error, isNull);
      expect(controller.state.isLoading, isFalse);
    },
  );

  test('failed install surfaces the error and does not reload', () async {
    service.installResult = 'Installation failed: no candidate';
    final listCallsBefore = service.listCalls;

    await controller.installPackage('ghost-pkg', 'apt');

    expect(service.listCalls, listCallsBefore);
    expect(controller.state.error, contains('Installation failed'));
    expect(controller.state.isLoading, isFalse);
  });

  test('failed removal surfaces the error', () async {
    service.removeResult = 'Removal failed: dependency issue';

    await controller.removePackage('libfoo', 'apt');

    expect(controller.state.error, contains('Removal failed'));
    expect(controller.state.isLoading, isFalse);
  });

  test('clearError resets the error', () async {
    service.installResult = 'Error: boom';
    await controller.installPackage('x', 'apt');
    expect(controller.state.error, isNotNull);

    controller.clearError();

    expect(controller.state.error, isNull);
  });
}
