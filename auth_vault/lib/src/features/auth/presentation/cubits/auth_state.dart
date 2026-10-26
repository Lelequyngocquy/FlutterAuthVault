import '../../../../core/domain/bloc_status.dart';
import '../../../../core/presentation/blocs/base_state.dart';
import '../../domain/user_entity.dart';

class AuthState extends BaseState {
  final UserEntity? user;
  final bool isBiometricAvailable;
  final bool isPinFallbackMode;
  const AuthState({
    super.status,
    super.message,
    this.user,
    this.isBiometricAvailable = false,
    this.isPinFallbackMode = false,
  });
  @override
  AuthState copyWith({
    BlocStatus? status,
    String? message,
    UserEntity? user,
    bool? isBiometricAvailable,
    bool? isPinFallbackMode,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: message ?? this.message,
      user: user ?? this.user,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isPinFallbackMode: isPinFallbackMode ?? this.isPinFallbackMode,
    );
  }
  @override
  List<Object?> get props => [status, message, user, isBiometricAvailable, isPinFallbackMode];
}
