import 'package:flutter/material.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/auth/auth_identifier_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/profile_setup_screen.dart';
import '../../presentation/screens/chats/chats_list_screen.dart';
import '../../presentation/screens/chats/chat_screen.dart';
import '../../presentation/screens/groups/group_create_screen.dart';
import '../../presentation/screens/groups/group_join_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String phoneLogin = '/phone-login';
  static const String register = '/register';
  static const String profileSetup = '/profile-setup';
  static const String chats = '/chats';
  static const String chat = '/chat';
  static const String groupCreate = '/group/create';
  static const String groupJoin = '/group/join';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case welcome:
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const AuthIdentifierScreen(mode: AuthIdentifierMode.loginEmail),
        );
      case phoneLogin:
        return MaterialPageRoute(
          builder: (_) => const AuthIdentifierScreen(mode: AuthIdentifierMode.loginEmail),
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );
      case profileSetup:
        return MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
        );
      case chats:
        return MaterialPageRoute(
          builder: (_) => const ChatsListScreen(),
        );
      case chat:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: args?['chatId'] as String? ?? '',
            chatName: args?['chatName'] as String? ?? '',
          ),
        );
      case groupCreate:
        return MaterialPageRoute(
          builder: (_) => const GroupCreateScreen(),
        );
      case groupJoin:
        return MaterialPageRoute(
          builder: (_) => const GroupJoinScreen(),
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
        );
    }
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('404')),
      body: const Center(child: Text('Страница не найдена')),
    );
  }
}

