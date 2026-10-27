import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();
  static const String appName = 'AuthVault Mobile';
  static const String appVersion = '1.0.0';
  static const int sessionTimeoutSeconds = 120;
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://localhost:8080';
    return 'http://localhost:8080';
  }
}
