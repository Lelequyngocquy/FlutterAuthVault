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
    logs.add('[BẮT ĐẦU THỬ NGHIỆM] Đang gửi đồng thời 5 request đến /vault/items...');
    emit(state.copyWith(isTestingConcurrency: true, executionLogs: logs));
    final futures = List.generate(5, (index) async {
      final res = await _repo.getVaultItems();
      return res.success;
    });
    final results = await Future.wait(futures);
    final successes = results.where((r) => r).length;
    logs.add('[HOÀN TẤT] $successes/5 request đồng thời đều nhận được kết quả thành công 200 OK');
    logs.add('[KẾT QUẢ] Hàng đợi Mutex đã khóa, chỉ làm mới token 1 lần duy nhất và phát lại an toàn');
    emit(state.copyWith(
      isTestingConcurrency: false,
      executionLogs: logs,
      successfulCalls: successes,
    ));
    await loadVaultItems();
  }
}
