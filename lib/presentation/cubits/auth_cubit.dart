import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_credentials.dart';
import '../../domain/usecases/usecases.dart';

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserCredentials credentials;
  const AuthAuthenticated(this.credentials);
  @override
  List<Object?> get props => [credentials];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final GetSavedCredentialsUseCase getSavedCredentialsUseCase;
  final LogoutUseCase logoutUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.getSavedCredentialsUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    final result = await getSavedCredentialsUseCase();
    result.fold(
          (failure) => emit(AuthUnauthenticated()),
          (credentials) {
        if (credentials != null) {
          emit(AuthAuthenticated(credentials));
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (credentials) => emit(AuthAuthenticated(credentials)),
    );
  }

  Future<void> logout() async {
    await logoutUseCase();
    emit(AuthUnauthenticated());
  }
}
