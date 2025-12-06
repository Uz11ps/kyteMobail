import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/config/app_config.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/config_validator.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Ошибка инициализации Firebase: $e');
    debugPrint('Убедитесь, что google-services.json и GoogleService-Info.plist настроены');
  }
  
  // Инициализация Push-уведомлений
  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint('Ошибка инициализации Push-уведомлений: $e');
  }
  
  // Проверка конфигурации API
  if (!AppConfig.isConfigured) {
    debugPrint('⚠️  API URLs не настроены!');
    debugPrint('Используйте --dart-define при запуске или обновите app_config.dart');
  }
  
  runApp(const KyteApp());
}

