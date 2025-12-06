import '../config/app_config.dart';
import 'package:flutter/material.dart';

class ConfigValidator {
  static void validateConfig(BuildContext context) {
    if (!AppConfig.isConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Конфигурация не настроена'),
            content: const Text(
              'Пожалуйста, настройте API URLs и Google Client ID.\n\n'
              'Используйте аргументы при запуске:\n'
              '--dart-define=API_BASE_URL=...\n'
              '--dart-define=WS_BASE_URL=...\n'
              '--dart-define=GOOGLE_CLIENT_ID=...\n\n'
              'Или обновите значения в lib/core/config/app_config.dart',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }
}

