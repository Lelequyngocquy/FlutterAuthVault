import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vault_pass_mobile/src/core/domain/base_result.dart';
import 'package:vault_pass_mobile/src/core/domain/bloc_status.dart';
import 'package:vault_pass_mobile/src/core/infrastructure/datasources/local_storage.dart';
import 'package:vault_pass_mobile/src/core/infrastructure/security/biometric_crypto_service.dart';
import 'package:vault_pass_mobile/src/features/auth/domain/user_entity.dart';
import 'package:vault_pass_mobile/src/features/auth/infrastructure/repository/auth_repository.dart';
import 'package:vault_pass_mobile/src/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:vault_pass_mobile/src/features/auth/presentation/cubits/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBiometricCryptoService extends Mock
    implements BiometricCryptoService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockAuthRepository mockRepo;
  late MockBiometricCryptoService mockBio;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'DEVICE_ID': 'dev_mock'});
    SecuredStorage.instance.init();
    mockRepo = MockAuthRepository();
    mockBio = MockBiometricCryptoService();
  });
  group('AuthCubit Unit Tests', () {
    const testUser = UserEntity(
      id: 'usr_001',
      username: 'admin',
      role: 'SECURITY_OFFICER',
      deviceId: 'dev_mock',
    );
    test('Initial state is correct', () {
      final cubit = AuthCubit(mockRepo, mockBio);
      expect(cubit.state.status, equals(BlocStatus.init));
      expect(cubit.state.user, isNull);
      expect(cubit.state.isPinFallbackMode, isFalse);
    });
    blocTest<AuthCubit, AuthState>(
      'togglePinFallback updates mode correctly',
      build: () => AuthCubit(mockRepo, mockBio),
      act: (cubit) => cubit.togglePinFallback(true),
      expect: () => [const AuthState(isPinFallbackMode: true)],
    );
    blocTest<AuthCubit, AuthState>(
      'checkBiometricSupport emits state with availability flag',
      build: () {
        when(
          () => mockBio.isBiometricAvailable(),
        ).thenAnswer((_) async => true);
        return AuthCubit(mockRepo, mockBio);
      },
      act: (cubit) => cubit.checkBiometricSupport(),
      expect: () => [const AuthState(isBiometricAvailable: true)],
    );
    blocTest<AuthCubit, AuthState>(
      'loginWithPassword emits loading then success on valid credentials',
      build: () {
        when(
          () => mockRepo.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => BaseResult.ok(testUser));
        return AuthCubit(mockRepo, mockBio);
      },
      act: (cubit) => cubit.loginWithPassword('admin', 'admin123'),
      expect: () => [
        const AuthState(status: BlocStatus.loading),
        const AuthState(status: BlocStatus.success, user: testUser),
      ],
    );
    blocTest<AuthCubit, AuthState>(
      'loginWithPassword emits loading then error on invalid credentials',
      build: () {
        when(
          () => mockRepo.login(
            username: any(named: 'username'),
            password: any(named: 'password'),
            deviceId: any(named: 'deviceId'),
          ),
        ).thenAnswer((_) async => BaseResult.err('Invalid credentials'));
        return AuthCubit(mockRepo, mockBio);
      },
      act: (cubit) => cubit.loginWithPassword('admin', 'wrong_pass'),
      expect: () => [
        const AuthState(status: BlocStatus.loading),
        const AuthState(
          status: BlocStatus.error,
          message: 'Invalid credentials',
        ),
      ],
    );
    blocTest<AuthCubit, AuthState>(
      'loginWithBiometrics emits error when biometric authentication is canceled',
      build: () {
        when(() => mockRepo.getBiometricChallenge(any())).thenAnswer((_) async => 'nonce_test');
        when(() => mockBio.authenticateBiometrics(reason: any(named: 'reason'))).thenAnswer((_) async => const BiometricAuthResult.failure('Biometric scan canceled by user'));
        return AuthCubit(mockRepo, mockBio);
      },
      act: (cubit) => cubit.loginWithBiometrics(),
      expect: () => [
        const AuthState(status: BlocStatus.loading),
        const AuthState(status: BlocStatus.error, message: 'Biometric scan canceled by user'),
      ],
    );
  });
}
