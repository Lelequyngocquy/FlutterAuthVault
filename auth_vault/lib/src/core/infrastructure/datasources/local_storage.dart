import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecuredStorage {
  static final SecuredStorage instance = SecuredStorage._();
  SecuredStorage._();
  FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  void init([FlutterSecureStorage? storage]) {
    if (storage != null) _storage = storage;
  }
  void setMockStorage(FlutterSecureStorage mock) {
    _storage = mock;
  }
  Future<String?> get accessToken => _storage.read(key: 'ACCESS_TOKEN');
  Future<void> saveAccessToken(String? val) => _storage.write(key: 'ACCESS_TOKEN', value: val);
  Future<String?> get refreshToken => _storage.read(key: 'REFRESH_TOKEN');
  Future<void> saveRefreshToken(String? val) => _storage.write(key: 'REFRESH_TOKEN', value: val);
  Future<String?> get deviceId async {
    final id = await _storage.read(key: 'DEVICE_ID');
    if (id != null) return id;
    final newId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.write(key: 'DEVICE_ID', value: newId);
    return newId;
  }
  Future<void> clearAll() async {
    await _storage.delete(key: 'ACCESS_TOKEN');
    await _storage.delete(key: 'REFRESH_TOKEN');
  }
}
