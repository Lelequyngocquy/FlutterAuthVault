import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import 'router_key_manager.dart';

class AppRouter {
  AppRouter._();
  static final AppRouter instance = AppRouter._();
  late final GoRouter router = GoRouter(
    initialLocation: RouterPath.login,
    navigatorKey: GlobalKeyManager.instance.root,
    routes: [
      GoRoute(
        path: RouterPath.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouterPath.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}
