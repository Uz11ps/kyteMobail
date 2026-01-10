import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../core/routing/app_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Если имя и никнейм отсутствуют, значит это новый пользователь, отправляем на настройку профиля
          final bool hasName = state.user.name != null && state.user.name!.isNotEmpty;
          final bool hasNickname = state.user.nickname != null && state.user.nickname!.isNotEmpty;
          
          if (!hasName && !hasNickname) {
            Navigator.of(context).pushReplacementNamed(AppRouter.profileSetup);
          } else {
            Navigator.of(context).pushReplacementNamed(AppRouter.chats);
          }
        } else if (state is AuthUnauthenticated || state is AuthError) {
          // При ошибке или отсутствии авторизации переходим на экран приветствия
          Navigator.of(context).pushReplacementNamed(AppRouter.welcome);
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Kyte Chat',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

