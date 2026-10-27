import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthResult {
  final bool success;
  final String? errorMessage;
  const BiometricAuthResult.success() : success = true, errorMessage = null;
  const BiometricAuthResult.failure(this.errorMessage) : success = false;
}

class BiometricCryptoService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (e) {
      debugPrint('[BIOMETRIC] isBiometricAvailable exception: $e');
      return false;
    }
  }
  Future<BiometricAuthResult> authenticateBiometrics({String reason = 'Authenticate for Vault Access'}) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('[BIOMETRIC] canCheck: $canCheck, isSupported: $isSupported, biometrics: $biometrics');
      if (!canCheck && !isSupported) {
        return const BiometricAuthResult.failure('Device does not support biometrics');
      }
      if (biometrics.isEmpty && !canCheck) {
        return const BiometricAuthResult.failure('No biometrics enrolled in device Settings');
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
      if (!authenticated) {
        return const BiometricAuthResult.failure('Biometric scan canceled or unverified');
      }
      return const BiometricAuthResult.success();
    } on PlatformException catch (e) {
      debugPrint('[BIOMETRIC PLATFORM ERR] code: ${e.code}, msg: ${e.message}');
      if (e.code == 'NotEnrolled') {
        return const BiometricAuthResult.failure('No fingerprint enrolled in device settings');
      }
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return const BiometricAuthResult.failure('Biometric locked out. Please unlock with phone PIN');
      }
      return BiometricAuthResult.failure(e.message ?? 'Biometric verification error (${e.code})');
    } catch (e) {
      debugPrint('[BIOMETRIC ERR] $e');
      return BiometricAuthResult.failure(e.toString());
    }
  }
  String signChallenge(String nonce, String deviceId) {
    final raw = '$nonce:$deviceId:secure_vault_hardware_key';
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    return 'sig_${digest.toString()}';
  }
}
