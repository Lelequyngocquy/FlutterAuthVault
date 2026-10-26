import 'package:equatable/equatable.dart';
import '../../domain/bloc_status.dart';

class BaseState extends Equatable {
  final BlocStatus status;
  final String? message;
  const BaseState({
    this.status = BlocStatus.init,
    this.message,
  });
  bool get isLoading => status == BlocStatus.loading;
  bool get isSuccess => status == BlocStatus.success;
  bool get isError => status == BlocStatus.error;
  BaseState copyWith({
    BlocStatus? status,
    String? message,
  }) {
    return BaseState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
  @override
  List<Object?> get props => [status, message];
}
