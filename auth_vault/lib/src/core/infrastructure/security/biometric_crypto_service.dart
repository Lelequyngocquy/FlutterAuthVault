import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

class BiometricCryptoService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return canCheck || isDeviceSupported;
  }
  Future<bool> authenticateBiometrics({String reason = 'Authenticate for Vault Access'}) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
  String signChallenge(String nonce, String deviceId) {
    final raw = '$nonce:$deviceId:secure_vault_hardware_key';
    final bytes = utf8.encode(raw);
    final digest = sha256.convert(bytes);
    return 'sig_${digest.toString()}';
  }
}
