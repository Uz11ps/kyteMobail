import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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
    on<AuthPhoneCodeSendRequested>(_onAuthPhoneCodeSendRequested);
    on<AuthPhoneRegisterRequested>(_onAuthPhoneRegisterRequested);
    on<AuthPhoneLoginRequested>(_onAuthPhoneLoginRequested);
    on<AuthGuestLoginRequested>(_onAuthGuestLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Добавляем таймаут для проверки авторизации
      final isAuthenticated = await authRepository.isAuthenticated()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('⚠️  Таймаут проверки авторизации');
              return false;
            },
          );
      if (isAuthenticated) {
        final user = await authRepository.getCurrentUser()
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('⚠️  Таймаут получения пользователя');
                return null;
              },
            );
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('❌ Ошибка проверки авторизации: $e');
      // При ошибке считаем пользователя неавторизованным
      emit(AuthUnauthenticated());
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
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthPhoneCodeSendRequested(
    AuthPhoneCodeSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPhoneVerificationCode(event.phone);
      emit(AuthPhoneCodeSent());
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthPhoneRegisterRequested(
    AuthPhoneRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.registerWithPhone(
        event.phone,
        event.code,
        name: event.name,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthPhoneLoginRequested(
    AuthPhoneLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.loginWithPhone(
        event.phone,
        event.code,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onAuthGuestLoginRequested(
    AuthGuestLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.loginAsGuest();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
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
      emit(AuthError(message: e.toString()));
    }
  }
}

