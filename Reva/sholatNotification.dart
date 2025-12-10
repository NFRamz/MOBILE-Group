import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class SholatNotification {
  static final SholatNotification _instance = SholatNotification._internal();
  factory SholatNotification() => _instance;
  SholatNotification._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // PERBAIKAN 1: Ganti ID Channel (Wajib ganti string ini jika ada perubahan config suara)
  static const String channelIdAdzan = 'adzan_channel_v3';

  String _currentLokasi = "Anda";

  Future<void> init() async {
    tz.initializeTimeZones();

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

      // Buat DateTime hari ini sesuai jam sholat
      DateTime scheduleDate = DateTime(now.year, now.month, now.day, hour, minute);

      // PERBAIKAN 2: Logika "Next Day"
      // Jika waktu sholat sudah lewat hari ini (misal skrg jam 13:00, jadwal Subuh 04:00),
      // Maka jadwalkan untuk BESOK jam 04:00.
      if (scheduleDate.isBefore(now)) {
        scheduleDate = scheduleDate.add(const Duration(days: 1));
      }

      print("🔔 Menjadwalkan $namaSholat pada $scheduleDate (Repeat Daily)");

      await _localNotifications.zonedSchedule(
        namaSholat.hashCode,
        'Waktunya $namaSholat',
        'Segera tunaikan ibadah sholat $namaSholat untuk wilayah $_currentLokasi',
        tz.TZDateTime.from(scheduleDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelIdAdzan, // Menggunakan ID baru v3
            'Jadwal Sholat',
            channelDescription: 'Pengingat waktu sholat dan adzan',
            importance: Importance.max,
            priority: Priority.high,
            // Pastikan file 'android/app/src/main/res/raw/adzan_sound.mp3' ADA!
            sound: RawResourceAndroidNotificationSound('adzan_sound'),
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'adzan_sound.caf', // iOS butuh format .caf atau .wav biasanya
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Ulangi setiap hari
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
    await _localNotifications.show(
      999, // ID Random
      'Adzan',
      'Sholat lah sebelum disholatkan.',
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