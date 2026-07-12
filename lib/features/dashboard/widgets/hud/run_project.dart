import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/navigation_service.dart';
import '../../../terminal/controllers/terminal_controller.dart';
import '../../services/project_runner.dart';

/// Launches [path] by running its build/run command in the embedded terminal
/// and switching to the terminal tab, so the user watches real output —
/// builds, launch, and any errors — instead of a silent detached process.
void runProject(BuildContext context, WidgetRef ref, String path) {
  final command = ProjectRunner.commandFor(path);
  ref.read(terminalProvider.notifier).executeCommand(command);
  // Pop back to the dashboard (if on a pushed route) and open the terminal.
  NavigationService().navigateToTab(context, NavigationService.tabTerminal);
}
