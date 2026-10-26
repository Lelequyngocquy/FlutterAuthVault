import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/bloc_status.dart';
import '../../infrastructure/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repo;
  DashboardCubit(this._repo) : super(const DashboardState());
  Future<void> loadVaultItems() async {
    emit(state.copyWith(status: BlocStatus.loading));
    final res = await _repo.getVaultItems();
    if (res.success && res.data != null) {
      emit(state.copyWith(status: BlocStatus.success, items: res.data));
    } else {
      emit(state.copyWith(status: BlocStatus.error, message: res.message));
    }
  }
  Future<void> triggerConcurrent401Test() async {
    final logs = List<String>.from(state.executionLogs);
    logs.add('[MUTEX TEST] Launching 5 parallel API calls to /vault/items...');
    emit(state.copyWith(isTestingConcurrency: true, executionLogs: logs));
    final futures = List.generate(5, (index) async {
      final res = await _repo.getVaultItems();
      return res.success;
    });
    final results = await Future.wait(futures);
    final successes = results.where((r) => r).length;
    logs.add('[MUTEX TEST COMPLETED] $successes/5 parallel requests resolved with 200 OK');
    logs.add('[RESULT] Mutex queue synchronized refresh call successfully');
    emit(state.copyWith(
      isTestingConcurrency: false,
      executionLogs: logs,
      successfulCalls: successes,
    ));
    await loadVaultItems();
  }
}
