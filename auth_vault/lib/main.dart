import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'src/common/configs/injection.dart';
import 'src/common/constants/colors.dart';
import 'src/core/infrastructure/datasources/local_storage.dart';
import 'src/core/infrastructure/security/app_lifecycle_privacy_observer.dart';
import 'src/core/infrastructure/security/biometric_crypto_service.dart';
import 'src/core/infrastructure/security/session_timeout_manager.dart';
import 'src/features/auth/infrastructure/repository/auth_repository.dart';
import 'src/features/auth/presentation/cubits/auth_cubit.dart';
import 'src/features/dashboard/infrastructure/dashboard_repository.dart';
import 'src/features/dashboard/presentation/cubits/dashboard_cubit.dart';
import 'src/shared/router/app_router.dart';
import 'src/shared/router/router_key_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SecuredStorage.instance.init();
  setupDependencyInjection();
  runApp(const VaultPassApp());
}

class VaultPassApp extends StatelessWidget {
  const VaultPassApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(getIt<AuthRepository>(), getIt<BiometricCryptoService>()),
        ),
        BlocProvider<DashboardCubit>(
          create: (_) => DashboardCubit(getIt<DashboardRepository>()),
        ),
      ],
      child: Builder(
        builder: (ctx) {
          return MaterialApp.router(
            title: 'AuthVault',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              scaffoldBackgroundColor: UIColors.canvas,
              brightness: Brightness.dark,
              primaryColor: UIColors.primary,
              colorScheme: const ColorScheme.dark(
                primary: UIColors.primary,
                surface: UIColors.canvasSoft,
              ),
            ),
            routerConfig: AppRouter.instance.router,
            builder: (context, child) {
              return SessionTimeoutManager(
                timeoutDuration: const Duration(seconds: 120),
                onTimeout: () {
                  ctx.read<AuthCubit>().logout();
                  AppRouter.instance.router.go(RouterPath.login);
                },
                child: PrivacyCurtainContainer(
                  key: PrivacyCurtainContainer.globalKey,
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
