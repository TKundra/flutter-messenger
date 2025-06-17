import 'package:equatable/equatable.dart';
import 'package:messenger/data/model/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      error: error ?? this.error
    );
  }

  @override
  List<Object?> get props => [status, user, error];
}