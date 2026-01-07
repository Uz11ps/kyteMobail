import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase инициализирован');
  } catch (e) {
    debugPrint('⚠️  Ошибка инициализации Firebase: $e');
    debugPrint('Убедитесь, что google-services.json и GoogleService-Info.plist настроены');
  }
}








