import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background Message ID: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // ⚠️ PENTING: ID Channel diganti agar HP mereset pengaturan suara
  static const String channelIdGeneral = 'general_channel_adzan';

  FlutterLocalNotificationsPlugin get localNotifications => _localNotifications;

  Future<void> init() async {
    // 1. Request Permission (FCM)
    await _requestPermission();

    await _firebaseMessaging.subscribeToTopic('info_kegiatan');
    print(" Berhasil subscribe ke info_kegiatan");

    // 2. Setup Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Global Click Handler (Saat notifikasi lokal diklik)
        if (response.payload != null) {
          handleMessageNavigation(jsonDecode(response.payload!));
        }
      },
    );

    // 3. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle Foreground Messages (Aplikasi sedang dibuka)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground Message Received: ${message.data}");
      _showForegroundNotification(message);
    });

    // 5. Handle Background App Open (Aplikasi di minimize/background lalu diklik notifnya)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Background/Resumed Message Clicked: ${message.data}");
      handleMessageNavigation(message.data);
    });
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
    print('User granted permission: ${settings.authorizationStatus}');
  }


  void handleMessageNavigation(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    final String type = data['type'] ?? '';
    print("🔔 Mencoba Navigasi ke Type: $type");

    if (type == 'kegiatan') {
      Get.toNamed('/jadwalkegiatan');

      Get.snackbar("Info", "Membuka Jadwal Kegiatan",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2));

    } else if (type == 'promo') {
      Get.snackbar("Info", "Membuka Promo",
          backgroundColor: Colors.blue, colorText: Colors.white);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelIdGeneral,
            'Notifikasi Adzan & Kegiatan',
            channelDescription: 'Notifikasi dengan suara Adzan',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,

            sound: const RawResourceAndroidNotificationSound('adzan_sound'),
          ),
          iOS: const DarwinNotificationDetails(

            sound: 'adzan_sound.mp3',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
}