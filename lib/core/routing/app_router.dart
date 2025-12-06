import 'package:flutter/material.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/chats/chats_list_screen.dart';
import '../../presentation/screens/chats/chat_screen.dart';
import '../../presentation/screens/groups/group_create_screen.dart';
import '../../presentation/screens/groups/group_join_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String chats = '/chats';
  static const String chat = '/chat';
  static const String groupCreate = '/group/create';
  static const String groupJoin = '/group/join';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
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

