import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthGoogleLoginRequested>(_onAuthGoogleLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isAuthenticated = await authRepository.isAuthenticated();
      if (isAuthenticated) {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      // Убираем префикс "Exception: " если он есть
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.register(
        event.email,
        event.password,
        name: event.name,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      // Убираем префикс "Exception: " если он есть
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.loginWithGoogle(
        event.idToken,
        event.accessToken,
        event.email,
        event.name,
        picture: event.picture,
        googleId: event.googleId,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      String errorMessage = 'Ошибка входа через Google';
      try {
        if (e != null) {
          try {
            final errorStr = e.toString();
            if (errorStr.isNotEmpty && errorStr != 'null') {
              errorMessage = errorStr;
              if (errorMessage.startsWith('Exception: ')) {
                errorMessage = errorMessage.substring(11);
              }
            }
          } catch (toStringError) {
            // Если toString() сам выбрасывает ошибку, используем сообщение по умолчанию
            debugPrint('❌ Ошибка при вызове toString() в AuthBloc: $toStringError');
          }
        }
      } catch (parseError) {
        // Если проверка e != null выбрасывает ошибку, используем сообщение по умолчанию
        debugPrint('❌ Ошибка при проверке ошибки в AuthBloc: $parseError');
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      String errorMessage = 'Ошибка выхода';
      try {
        if (e != null) {
          try {
            final errorStr = e.toString();
            if (errorStr.isNotEmpty && errorStr != 'null') {
              errorMessage = errorStr;
            }
          } catch (toStringError) {
            // Если toString() сам выбрасывает ошибку, используем сообщение по умолчанию
            debugPrint('❌ Ошибка при вызове toString() в logout: $toStringError');
          }
        }
      } catch (parseError) {
        // Если проверка e != null выбрасывает ошибку, используем сообщение по умолчанию
        debugPrint('❌ Ошибка при проверке ошибки в logout: $parseError');
      }
      emit(AuthError(message: errorMessage));
    }
  }
}

