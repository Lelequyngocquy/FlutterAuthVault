import 'package:get_it/get_it.dart';
import '../../core/infrastructure/datasources/network/api/restful_request.dart';
import '../../core/infrastructure/security/biometric_crypto_service.dart';
import '../../features/auth/infrastructure/repository/auth_repository.dart';
import '../../features/dashboard/infrastructure/dashboard_repository.dart';

final getIt = GetIt.instance;

void setupDependencyInjection() {
  getIt.registerLazySingleton<RestfulRequest>(() => RestfulRequest());
  getIt.registerLazySingleton<BiometricCryptoService>(
    () => BiometricCryptoService(),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt<RestfulRequest>()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(getIt<RestfulRequest>()),
  );
}
