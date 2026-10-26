import 'package:flutter_test/flutter_test.dart';
import 'package:vault_pass_mobile/src/core/infrastructure/security/biometric_crypto_service.dart';
import 'package:vault_pass_mobile/src/core/infrastructure/security/device_integrity_checker.dart';

void main() {
  test('DeviceIntegrityChecker returns evaluated report', () async {
    final report = await DeviceIntegrityChecker.evaluateDevice();
    expect(report.isRootedOrJailbroken, isFalse);
    expect(report.isDevMode, isNotNull);
  });
  test('BiometricCryptoService signs challenge with SHA-256 digest', () {
    final service = BiometricCryptoService();
    final sig1 = service.signChallenge('nonce_123', 'device_456');
    final sig2 = service.signChallenge('nonce_123', 'device_456');
    final sig3 = service.signChallenge('nonce_999', 'device_456');
    expect(sig1, startsWith('sig_'));
    expect(sig1, equals(sig2));
    expect(sig1, isNot(equals(sig3)));
  });
}
