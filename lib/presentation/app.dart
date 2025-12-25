import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../core/routing/app_router.dart';
import '../core/di/service_locator.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/chat/chat_bloc.dart';
import 'bloc/google/google_bloc.dart';
import 'bloc/ai/ai_bloc.dart';

class KyteApp extends StatelessWidget {
  const KyteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final serviceLocator = ServiceLocator();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(
            authRepository: serviceLocator.authRepository,
          ),
        ),
        BlocProvider(
          create: (_) => ChatBloc(
            chatRepository: serviceLocator.chatRepository,
          ),
        ),
        BlocProvider(
          create: (_) => GoogleBloc(
            googleRepository: serviceLocator.googleRepository,
          ),
        ),
        BlocProvider(
          create: (_) => AIBloc(
            aiRepository: serviceLocator.aiRepository,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Kyte Chat',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRouter.generateRoute,
        initialRoute: AppRouter.chats,
      ),
    );
  }
}

