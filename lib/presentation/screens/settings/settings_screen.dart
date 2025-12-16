import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/google/google_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Профиль'),
                  subtitle: Text(state.user.email),
                  trailing: const Icon(Icons.chevron_right),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const Divider(),
          BlocBuilder<GoogleBloc, GoogleState>(
            builder: (context, state) {
              final hasToken = state is GoogleSignInSuccess || state is GoogleTokenSubmittedSuccess;
              
              return ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Google OAuth'),
                subtitle: Text(hasToken ? 'Подключено' : 'Не подключено'),
                trailing: hasToken
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.chevron_right),
                onTap: () {
                  if (!hasToken) {
                    context.read<GoogleBloc>().add(GoogleSignInRequested());
                  }
                },
              );
            },
          ),
          BlocListener<GoogleBloc, GoogleState>(
            listener: (context, state) {
              if (state is GoogleSignInSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google OAuth успешно подключен')),
                );
              } else if (state is GoogleError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: ${state.message}')),
                );
              }
            },
            child: const SizedBox.shrink(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Выйти'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Выход'),
                  content: const Text('Вы уверены, что хотите выйти?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        Navigator.of(context).pop();
                      },
                      child: const Text('Выйти'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

