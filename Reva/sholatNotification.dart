import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class SholatNotification {
  static final SholatNotification _instance = SholatNotification._internal();
  factory SholatNotification() => _instance;
  SholatNotification._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String channelIdAdzan = 'adzan_channel_v3';

  String _currentLokasi = "Anda";

  Future<void> init() async {
    // 1. Init Timezone Database
    tz.initializeTimeZones();

    // 2. Dapatkan lokasi timezone device (WIB/WITA/WIT) agar akurat
    try {
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));
    } catch (e) {
      print("Gagal set local timezone, fallback to UTC/Default: $e");
    }

    // 3. Setup Android Settings (Pastikan file icon ada di android/app/src/main/res/drawable/app_icon.png atau @mipmap/ic_launcher)
    // 'app_icon' atau '@mipmap/ic_launcher' sesuaikan dengan icon app anda
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // 4. Setup iOS Settings
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 5. Inisialisasi Plugin
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notifikasi diklik: ${response.payload}");
      },
    );

    // 6. Request Permission (Wajib untuk Android 13+)
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission(); // Untuk alarm tepat waktu
    }
  }

  void updateLokasi(String loc) {
    _currentLokasi = loc;
  }

  Future<void> scheduleSholatNotification(String namaSholat, String jam) async {
    try {
      final now = DateTime.now();
      final timeParts = jam.split(':');
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      // Buat DateTime berdasarkan timezone lokal (bukan UTC)
      final tz.TZDateTime nowLocal = tz.TZDateTime.now(tz.local);

      tz.TZDateTime scheduleDate = tz.TZDateTime(
        tz.local,
        nowLocal.year,
        nowLocal.month,
        nowLocal.day,
        hour,
        minute,
      );

      // Jika waktu sudah lewat hari ini, jadwalkan besok
      if (scheduleDate.isBefore(nowLocal)) {
        scheduleDate = scheduleDate.add(const Duration(days: 1));
      }

      print("Menjadwalkan $namaSholat pada $scheduleDate (Zona: ${tz.local.name})");

      await _localNotifications.zonedSchedule(
        namaSholat.hashCode, // ID Unik berdasarkan nama sholat
        'Waktunya $namaSholat',
        'Segera tunaikan ibadah sholat $namaSholat untuk wilayah $_currentLokasi',
        scheduleDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelIdAdzan,
            'Jadwal Sholat',
            channelDescription: 'Pengingat waktu sholat dan adzan',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('adzan_sound'), // Pastikan file ada di raw
            playSound: true,
            ticker: 'Waktunya Sholat',
          ),
          iOS: DarwinNotificationDetails(
            sound: 'adzan_sound.caf',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Wajib agar on time di mode doze
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Agar berulang setiap hari di jam yg sama
      );
    } catch (e) {
      print("Error scheduling prayer: $e");
    }
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    print("Semua notifikasi lama dibersihkan.");
  }

  Future<void> showTestAdzanNow() async {
    print("Mencoba menampilkan notifikasi langsung...");
    await _localNotifications.show(
      999,
      'Test Adzan',
      'Ini adalah test suara adzan.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelIdAdzan,
          'Jadwal Sholat',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('adzan_sound'),
          playSound: true,
        ),
      ),
    );
  }
}
