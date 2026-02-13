import 'dart:io';

/// Platform detection utilities for cross-platform automation
class PlatformHelper {
  static bool get isLinux => Platform.isLinux;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isIOS => Platform.isIOS;
  
  static bool get isDesktop => isLinux || isWindows || isMacOS;
  static bool get isMobile => isAndroid || isIOS;
  
  static bool get supportsBrowserAutomation => isLinux || isWindows || isMacOS;
  static bool get supportsADB => isAndroid;
  static bool get supportsProcessExecution => isDesktop;
  
  static String get platformName {
    if (isLinux) return 'Linux';
    if (isAndroid) return 'Android';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isIOS) return 'iOS';
    return 'Unknown';
  }
}
