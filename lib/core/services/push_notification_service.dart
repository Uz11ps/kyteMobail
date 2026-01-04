import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Пропускаем инициализацию на веб-платформе
    if (kIsWeb) {
      debugPrint('ℹ️  Push-уведомления недоступны на веб-платформе');
      return;
    }
    
    try {
      // Инициализация FirebaseMessaging только для мобильных платформ
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Проверка доступности Firebase
      // Запрос разрешений на уведомления
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Инициализация локальных уведомлений
        await _initializeLocalNotifications();

        // Получение FCM токена
        _fcmToken = await _firebaseMessaging!.getToken();
        
        // Обработка токена обновления
        _firebaseMessaging!.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          // Отправить новый токен на сервер
        });

        // Обработка сообщений в foreground
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Обработка нажатий на уведомления
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

        // Проверка, было ли приложение открыто из уведомления
        final initialMessage = await _firebaseMessaging!.getInitialMessage();
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      }
    } catch (e) {
      // Firebase не настроен - это нормально для демо режима
      debugPrint('Push-уведомления недоступны: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Настройка канала для Android
    if (!kIsWeb && Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Обработка навигации при нажатии на уведомление
    final data = message.data;
    if (data.containsKey('chatId')) {
      // Навигация к чату
      // Это должно быть реализовано через глобальный навигатор или BLoC
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Обработка нажатия на локальное уведомление
    final payload = response.payload;
    if (payload != null) {
      // Навигация к чату
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: android != null
              ? AndroidNotificationDetails(
                  'high_importance_channel',
                  'High Importance Notifications',
                  channelDescription: 'This channel is used for important notifications.',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: android.smallIcon,
                )
              : null,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging != null) {
      await _firebaseMessaging!.subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging != null) {
      await _firebaseMessaging!.unsubscribeFromTopic(topic);
    }
  }
}

