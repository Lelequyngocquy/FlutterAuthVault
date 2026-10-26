import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/bloc_status.dart';
import '../../../../core/infrastructure/datasources/local_storage.dart';
import '../../../../core/infrastructure/security/biometric_crypto_service.dart';
import '../../infrastructure/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  final BiometricCryptoService _bio;
  AuthCubit(this._repo, this._bio) : super(const AuthState());
  Future<void> checkBiometricSupport() async {
    final available = await _bio.isBiometricAvailable();
    emit(state.copyWith(isBiometricAvailable: available));
  }
  void togglePinFallback(bool enable) {
    emit(state.copyWith(isPinFallbackMode: enable));
  }
  Future<void> loginWithPassword(String username, String password) async {
    emit(state.copyWith(status: BlocStatus.loading));
    final devId = await SecuredStorage.instance.deviceId;
    final res = await _repo.login(
      username: username,
      password: password,
      deviceId: devId ?? 'dev_unknown',
    );
    if (res.success && res.data != null) {
      emit(state.copyWith(status: BlocStatus.success, user: res.data));
    } else {
      emit(state.copyWith(status: BlocStatus.error, message: res.message));
    }
  }
  Future<void> loginWithPIN(String pin) async {
    emit(state.copyWith(status: BlocStatus.loading));
    final devId = await SecuredStorage.instance.deviceId;
    final res = await _repo.login(
      username: 'admin',
      pin: pin,
      deviceId: devId ?? 'dev_unknown',
    );
    if (res.success && res.data != null) {
      emit(state.copyWith(status: BlocStatus.success, user: res.data));
    } else {
      emit(state.copyWith(status: BlocStatus.error, message: res.message));
    }
  }
  Future<void> loginWithBiometrics() async {
    emit(state.copyWith(status: BlocStatus.loading));
    final devId = await SecuredStorage.instance.deviceId ?? 'dev_unknown';
    final nonce = await _repo.getBiometricChallenge(devId);
    if (nonce == null) {
      emit(state.copyWith(status: BlocStatus.error, message: 'Failed to issue challenge'));
      return;
    }
    final authenticated = await _bio.authenticateBiometrics(reason: 'Verify biometric identity for Vault Access');
    if (!authenticated) {
      emit(state.copyWith(status: BlocStatus.error, message: 'Biometric scan canceled or failed'));
      return;
    }
    final signature = _bio.signChallenge(nonce, devId);
    final res = await _repo.verifyBiometric(
      deviceId: devId,
      nonce: nonce,
      signature: signature,
    );
    if (res.success && res.data != null) {
      emit(state.copyWith(status: BlocStatus.success, user: res.data));
    } else {
      emit(state.copyWith(status: BlocStatus.error, message: res.message));
    }
  }
  Future<void> logout() async {
    await _repo.logout();
    emit(const AuthState());
  }
}
