import 'package:brainiac_plus/core/platform/package_service.dart';
import 'package:brainiac_plus/features/activity/models/activity_entry.dart';
import 'package:brainiac_plus/features/packages/controllers/package_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePackageService extends PackageService {
  List<PackageInfo> aptPackages = [];
  String installResult = 'Package installed successfully';
  String removeResult = 'Package removed successfully';
  String updateResult = 'Package lists updated';
  String upgradeResult = 'Packages upgraded successfully';
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

  @override
  Future<String> updatePackageLists() async => updateResult;

  @override
  Future<String> upgradePackages() async => upgradeResult;
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

  test('failed list update surfaces the error', () async {
    service.updateResult = 'Update failed: mirror unreachable';

    await controller.updateLists();

    expect(controller.state.error, contains('Update failed'));
    expect(controller.state.isLoading, isFalse);
  });

  test('successful upgrade surfaces the message and logs activity', () async {
    final logged = <ActivityEntry>[];
    final c = PackageController(
      packageService: service,
      onActivity: logged.add,
    );
    await Future<void>.delayed(Duration.zero);

    await c.upgradeAll();

    expect(c.state.lastOperationMessage, contains('upgraded'));
    expect(c.state.error, isNull);
    expect(logged.map((e) => e.title), contains('Package upgrade'));

    c.dispose();
  });

  test(
    'install and remove operations are reported to the activity log',
    () async {
      final logged = <ActivityEntry>[];
      final c = PackageController(
        packageService: service,
        onActivity: logged.add,
      );
      await Future<void>.delayed(Duration.zero);

      await c.installPackage('htop', 'apt');
      service.removeResult = 'Removal failed: dependency issue';
      await c.removePackage('libfoo', 'apt');

      expect(logged, hasLength(2));
      expect(logged[0].type, ActivityType.packages);
      expect(logged[0].description, contains('htop'));
      // Failures are logged too — the log is an audit trail.
      expect(logged[1].description, contains('libfoo'));

      c.dispose();
    },
  );
}
