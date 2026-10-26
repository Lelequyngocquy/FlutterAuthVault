import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String username;
  final String role;
  final String? deviceId;
  const UserEntity({
    required this.id,
    required this.username,
    required this.role,
    this.deviceId,
  });
  @override
  List<Object?> get props => [id, username, role, deviceId];
}
