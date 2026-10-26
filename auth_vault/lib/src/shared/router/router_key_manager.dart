import 'package:flutter/material.dart';

class GlobalKeyManager {
  static final instance = GlobalKeyManager();
  final GlobalKey<NavigatorState> root = GlobalKey<NavigatorState>(debugLabel: 'root_key');
}

class RouterPath {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
}
