import '../../../core/domain/base_result.dart';
import '../../../core/infrastructure/datasources/local_storage.dart';
import '../../../core/infrastructure/datasources/network/api/configs/endpoint.dart';
import '../../../core/infrastructure/datasources/network/api/restful_request.dart';
import '../domain/user_entity.dart';

class AuthRepository {
  final RestfulRequest _rest;
  AuthRepository(this._rest);
  Future<BaseResult<UserEntity>> login({
    required String username,
    String? password,
    String? pin,
    required String deviceId,
  }) async {
    final res = await _rest.requestData(EndpointType(
      path: '/api/v1/auth/login',
      method: DioHttpMethod.post,
      params: {
        'username': username,
        'password': ?password,
        'pin': ?pin,
        'deviceId': deviceId,
      },
    ));
    if (res.isSuccess && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      await SecuredStorage.instance.saveAccessToken(tokens['accessToken']?.toString());
      await SecuredStorage.instance.saveRefreshToken(tokens['refreshToken']?.toString());
      return BaseResult.ok(UserEntity(
        id: userJson['id']?.toString() ?? '',
        username: userJson['username']?.toString() ?? '',
        role: userJson['role']?.toString() ?? '',
        deviceId: userJson['deviceId']?.toString(),
      ));
    }
    return BaseResult.err(res.message ?? 'Authentication failed');
  }
  Future<String?> getBiometricChallenge(String deviceId) async {
    final res = await _rest.requestData(EndpointType(
      path: '/api/v1/auth/biometric/challenge',
      method: DioHttpMethod.get,
      queryParameters: {'deviceId': deviceId},
    ));
    if (res.isSuccess && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      return data['nonce']?.toString();
    }
    return null;
  }
  Future<BaseResult<UserEntity>> verifyBiometric({
    required String deviceId,
    required String nonce,
    required String signature,
  }) async {
    final res = await _rest.requestData(EndpointType(
      path: '/api/v1/auth/biometric/verify',
      method: DioHttpMethod.post,
      params: {
        'deviceId': deviceId,
        'nonce': nonce,
        'signature': signature,
      },
    ));
    if (res.isSuccess && res.data != null) {
      final data = res.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>;
      await SecuredStorage.instance.saveAccessToken(tokens['accessToken']?.toString());
      await SecuredStorage.instance.saveRefreshToken(tokens['refreshToken']?.toString());
      return BaseResult.ok(UserEntity(
        id: userJson['id']?.toString() ?? '',
        username: userJson['username']?.toString() ?? '',
        role: userJson['role']?.toString() ?? '',
        deviceId: userJson['deviceId']?.toString(),
      ));
    }
    return BaseResult.err(res.message ?? 'Biometric verification rejected');
  }
  Future<void> logout() async {
    final rft = await SecuredStorage.instance.refreshToken;
    if (rft != null) {
      await _rest.requestData(EndpointType(
        path: '/api/v1/auth/logout',
        method: DioHttpMethod.post,
        params: {'refreshToken': rft},
      ));
    }
    await SecuredStorage.instance.clearAll();
  }
}
