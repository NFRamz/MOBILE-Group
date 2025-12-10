import 'package:aisyiyah_smartlife/core/services/notification/notificationService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

class Splashscreen_controller extends GetxController {
  final isLoading     = true.obs;
  final statusMessage = 'Menyiapkan aplikasi...'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      statusMessage.value = 'Menginisialisasi aplikasi...';

      await _getReadyAll();

      statusMessage.value = 'Memeriksa status login...';

      await _checkLoginStatus();

    } catch (e) {
      statusMessage.value = 'Terjadi kesalahan: $e';
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed('/login');
    }
  }

  Future<void> _getReadyAll() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  }


  Future<void> _checkLoginStatus() async {
    final prefs       = await SharedPreferences.getInstance();
    final isLoggedIn  = prefs.getBool('isLoggedIn') ?? false;

    await Future.delayed(const Duration(seconds: 3));

    if (isLoggedIn) {
      Get.offAllNamed('/home');

      _checkTerminatedNotification();
    } else {
      Get.offAllNamed('/login');
    }
  }
  Future<void> _checkTerminatedNotification() async {
    try {
      // Ambil pesan inisial dari Firebase
      RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        print("TERMINATED NOTIF DETECTED: ${initialMessage.data}");

        // Beri jeda sedikit agar UI Home ter-render sempurna
        await Future.delayed(const Duration(milliseconds: 2500));

        // Panggil fungsi navigasi di NotificationService
        NotificationService().handleMessageNavigation(initialMessage.data);
      }
    } catch (e) {
      print("Error checking terminated notification: $e");
    }
  }
}
