import 'package:flutter/material.dart';

import '../../services/project_runner.dart';

/// Launches [path] as a running app and reports the outcome via a snackbar.
/// Shared by the project card and the project detail screen.
Future<void> runProject(BuildContext context, String path) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(
      content: Text('Starting app…'),
      duration: Duration(seconds: 1),
    ),
  );
  final result = await ProjectRunner().launchPath(path);
  messenger.showSnackBar(
    SnackBar(
      content: Text(result.message),
      duration: const Duration(seconds: 3),
    ),
  );
}
