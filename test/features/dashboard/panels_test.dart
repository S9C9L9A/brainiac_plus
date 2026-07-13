import 'package:brainiac_plus/features/dashboard/widgets/panels/floating_panel.dart';
import 'package:brainiac_plus/features/dashboard/widgets/panels/resizable_split.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResizableSplit', () {
    testWidgets('dragging the divider trades space between the panes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: ResizableSplit(
                initialFraction: 0.5,
                first: Container(key: const Key('a'), color: Colors.red),
                second: Container(key: const Key('b'), color: Colors.blue),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      double widthOf(Key k) => tester.getSize(find.byKey(k)).width;
      final before = widthOf(const Key('a'));
      expect(before, closeTo(495, 5)); // ~ (1000 - 10) * 0.5

      // Drag the divider 150px to the right → first pane grows.
      await tester.drag(
        find.byKey(ResizableSplit.dividerKey),
        const Offset(150, 0),
      );
      await tester.pump();

      final after = widthOf(const Key('a'));
      expect(after, greaterThan(before + 100));
    });

    testWidgets('the divider cannot drag a pane past its min fraction', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: ResizableSplit(
                initialFraction: 0.5,
                minFraction: 0.25,
                first: Container(key: const Key('a')),
                second: Container(key: const Key('b')),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Drag far left, well past the 25% floor.
      await tester.drag(
        find.byKey(ResizableSplit.dividerKey),
        const Offset(-900, 0),
      );
      await tester.pump();

      final w = tester.getSize(find.byKey(const Key('a'))).width;
      expect(w, closeTo(0.25 * (1000 - 10), 5));
    });
  });

  group('FloatingPanel', () {
    Widget host({required VoidCallback onDock, VoidCallback? onClose}) {
      return MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingPanel(
                title: 'SOURCE MAP',
                icon: Icons.hub_outlined,
                onDock: onDock,
                onClose: onClose,
                child: const Text('panel body'),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders its title and body', (tester) async {
      await tester.pumpWidget(host(onDock: () {}));
      expect(find.text('SOURCE MAP'), findsOneWidget);
      expect(find.text('panel body'), findsOneWidget);
    });

    testWidgets('the dock button re-attaches the panel', (tester) async {
      var docked = false;
      await tester.pumpWidget(host(onDock: () => docked = true));
      await tester.tap(find.byTooltip('Dock'));
      await tester.pump();
      expect(docked, isTrue);
    });

    testWidgets('dragging the title bar moves the window', (tester) async {
      await tester.pumpWidget(host(onDock: () {}));
      final before = tester.getTopLeft(find.text('panel body'));
      await tester.drag(find.text('SOURCE MAP'), const Offset(120, 60));
      await tester.pump();
      final after = tester.getTopLeft(find.text('panel body'));
      expect(after.dx, greaterThan(before.dx + 100));
      expect(after.dy, greaterThan(before.dy + 40));
    });

    testWidgets('close is hidden until an onClose is provided', (tester) async {
      await tester.pumpWidget(host(onDock: () {}));
      expect(find.byTooltip('Close'), findsNothing);

      var closed = false;
      await tester.pumpWidget(
        host(onDock: () {}, onClose: () => closed = true),
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pump();
      expect(closed, isTrue);
    });
  });
}
