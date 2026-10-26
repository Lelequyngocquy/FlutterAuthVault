import '../../../../core/domain/bloc_status.dart';
import '../../../../core/presentation/blocs/base_state.dart';
import '../../domain/vault_item_entity.dart';

class DashboardState extends BaseState {
  final List<VaultItemEntity> items;
  final List<String> executionLogs;
  final bool isTestingConcurrency;
  final int successfulCalls;
  const DashboardState({
    super.status,
    super.message,
    this.items = const [],
    this.executionLogs = const [],
    this.isTestingConcurrency = false,
    this.successfulCalls = 0,
  });
  @override
  DashboardState copyWith({
    BlocStatus? status,
    String? message,
    List<VaultItemEntity>? items,
    List<String>? executionLogs,
    bool? isTestingConcurrency,
    int? successfulCalls,
  }) {
    return DashboardState(
      status: status ?? this.status,
      message: message ?? this.message,
      items: items ?? this.items,
      executionLogs: executionLogs ?? this.executionLogs,
      isTestingConcurrency: isTestingConcurrency ?? this.isTestingConcurrency,
      successfulCalls: successfulCalls ?? this.successfulCalls,
    );
  }
}
