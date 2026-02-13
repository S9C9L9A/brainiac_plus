import 'dart:io';
import '../utils/platform_helper.dart';
import '../../features/automation/models/automation.dart';
import '../../features/automation/models/automation_enums.dart';

/// Core automation engine with platform-aware execution
class AutomationEngine {
  /// Execute automation with dual-mode strategy
  Future<AutomationLog> execute(Automation automation) async {
    final log = AutomationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      automationId: automation.id,
      executionMode: _determineExecutionMode(automation),
      status: AutomationStatus.running,
      startTime: DateTime.now(),
      steps: [],
    );

    try {
      // Determine best execution mode based on platform and preferences
      final mode = _determineExecutionMode(automation);
      
      // Execute based on mode
      final result = await _executeWithMode(automation, mode);
      
      return log.copyWith(
        status: AutomationStatus.completed,
        endTime: DateTime.now(),
        result: result,
        steps: [...log.steps, 'Execution completed successfully'],
      );
    } catch (e) {
      return log.copyWith(
        status: AutomationStatus.failed,
        endTime: DateTime.now(),
        errorMessage: e.toString(),
        steps: [...log.steps, 'Execution failed: ${e.toString()}'],
      );
    }
  }

  /// Determine best execution mode based on platform and service
  AutomationMode _determineExecutionMode(Automation automation) {
    // If hybrid mode, choose best option
    if (automation.preferredMode == AutomationMode.hybrid) {
      // Check if service supports API
      if (automation.service.supportsAPI) {
        return AutomationMode.api;
      }
      
      // Fallback to browser on desktop
      if (PlatformHelper.supportsBrowserAutomation) {
        return AutomationMode.browser;
      }
      
      // Fallback to app on Android
      if (PlatformHelper.supportsADB) {
        return AutomationMode.app;
      }
    }

    // Validate platform supports requested mode
    final mode = automation.preferredMode;
    
    if (mode == AutomationMode.browser && !PlatformHelper.supportsBrowserAutomation) {
      throw UnsupportedError('Browser automation not supported on ${PlatformHelper.platformName}');
    }
    
    if (mode == AutomationMode.app && !PlatformHelper.supportsADB) {
      throw UnsupportedError('App automation not supported on ${PlatformHelper.platformName}');
    }

    return mode;
  }

  /// Execute automation with specified mode
  Future<Map<String, dynamic>> _executeWithMode(
    Automation automation,
    AutomationMode mode,
  ) async {
    switch (mode) {
      case AutomationMode.api:
        return await _executeViaAPI(automation);
      case AutomationMode.browser:
        return await _executeViaBrowser(automation);
      case AutomationMode.app:
        return await _executeViaApp(automation);
      case AutomationMode.hybrid:
        // Try API first
        try {
          return await _executeViaAPI(automation);
        } catch (e) {
          // Fallback to browser/app
          if (PlatformHelper.supportsBrowserAutomation) {
            return await _executeViaBrowser(automation);
          } else if (PlatformHelper.supportsADB) {
            return await _executeViaApp(automation);
          }
          rethrow;
        }
    }
  }

  /// Execute via API (cross-platform)
  Future<Map<String, dynamic>> _executeViaAPI(Automation automation) async {
    // This will be implemented by service-specific handlers
    throw UnimplementedError('API execution not yet implemented for ${automation.service.label}');
  }

  /// Execute via browser automation (Linux/Windows/macOS only)
  Future<Map<String, dynamic>> _executeViaBrowser(Automation automation) async {
    if (!PlatformHelper.supportsBrowserAutomation) {
      throw UnsupportedError('Browser automation not supported on ${PlatformHelper.platformName}');
    }

    // This will be implemented using process_run to launch Chrome with automation
    throw UnimplementedError('Browser automation not yet implemented for ${automation.service.label}');
  }

  /// Execute via app automation (Android only)
  Future<Map<String, dynamic>> _executeViaApp(Automation automation) async {
    if (!PlatformHelper.supportsADB) {
      throw UnsupportedError('App automation not supported on ${PlatformHelper.platformName}');
    }

    // This will be implemented using ADB commands and intents
    throw UnimplementedError('App automation not yet implemented for ${automation.service.label}');
  }

  /// Validate automation can run on current platform
  bool canExecuteOnCurrentPlatform(Automation automation) {
    try {
      _determineExecutionMode(automation);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get recommended execution mode for automation
  AutomationMode getRecommendedMode(Automation automation) {
    return _determineExecutionMode(automation);
  }
}

// Extension to add copyWith to AutomationLog
extension AutomationLogCopyWith on AutomationLog {
  AutomationLog copyWith({
    String? id,
    String? automationId,
    AutomationMode? executionMode,
    AutomationStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? errorMessage,
    Map<String, dynamic>? result,
    List<String>? steps,
  }) {
    return AutomationLog(
      id: id ?? this.id,
      automationId: automationId ?? this.automationId,
      executionMode: executionMode ?? this.executionMode,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
      steps: steps ?? this.steps,
    );
  }
}
