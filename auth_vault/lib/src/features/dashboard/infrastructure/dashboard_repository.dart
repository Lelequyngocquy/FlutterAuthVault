import '../../../core/domain/base_result.dart';
import '../../../core/infrastructure/datasources/network/api/configs/endpoint.dart';
import '../../../core/infrastructure/datasources/network/api/restful_request.dart';
import '../domain/vault_item_entity.dart';

class DashboardRepository {
  final RestfulRequest _rest;
  DashboardRepository(this._rest);
  Future<BaseResult<List<VaultItemEntity>>> getVaultItems() async {
    final res = await _rest.requestData(const EndpointType(
      path: '/api/v1/vault/items',
      method: DioHttpMethod.get,
    ));
    if (res.isSuccess && res.data is List) {
      final list = (res.data as List).map((e) {
        final m = e as Map<String, dynamic>;
        return VaultItemEntity(
          id: m['id']?.toString() ?? '',
          title: m['title']?.toString() ?? '',
          category: m['category']?.toString() ?? '',
          secretSnippet: m['secretSnippet']?.toString() ?? '',
          securityLevel: m['securityLevel']?.toString() ?? 'L1_STANDARD',
          lastAccessed: DateTime.tryParse(m['lastAccessed']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
      return BaseResult.ok(list);
    }
    return BaseResult.err(res.message ?? 'Failed to retrieve vault assets');
  }
}
