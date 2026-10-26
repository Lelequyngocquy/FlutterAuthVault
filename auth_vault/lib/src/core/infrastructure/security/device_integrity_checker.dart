import 'package:flutter/foundation.dart';

class IntegrityReport {
  final bool isSecure;
  final bool isRootedOrJailbroken;
  final bool isEmulator;
  final bool isDevMode;
  const IntegrityReport({
    required this.isSecure,
    required this.isRootedOrJailbroken,
    required this.isEmulator,
    required this.isDevMode,
  });
}

class DeviceIntegrityChecker {
  static Future<IntegrityReport> evaluateDevice() async {
    bool isDev = kDebugMode;
    bool isEmu = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) && isDev;
    bool isRooted = false;
    bool secure = !isRooted && !isEmu;
    return IntegrityReport(
      isSecure: secure,
      isRootedOrJailbroken: isRooted,
      isEmulator: isEmu,
      isDevMode: isDev,
    );
  }
}
