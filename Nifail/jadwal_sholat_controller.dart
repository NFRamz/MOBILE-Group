import 'package:aisyiyah_smartlife/modules/jadwalSholat/service/dio.dart';
import 'package:aisyiyah_smartlife/core/services/notification/sholatNotification.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class JadwalSholatController extends GetxController {
  var jadwal        = Rxn<Map<String, dynamic>>();
  var doaDzikir     = ''.obs;
  var isLoading     = false.obs;
  var lokasiSaatIni = 'Mencari Lokasi...'.obs;
// 1. Variable untuk menyembunyikan tombol
  final isTestMode = false.obs;

  // 2. Fungsi untuk mengaktifkan mode test (seperti Developer Mode Android)
  int _tapCount = 0;


  final dioService = DioService();
  final notificationService = SholatNotification(); // Instance service

  Future<void> fetchJadwal() async {
    isLoading.value = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      List<Placemark> convertKoordinatToNamaKota = await placemarkFromCoordinates(position.latitude, position.longitude);
      String getNamaKota                         = convertKoordinatToNamaKota[0].subAdministrativeArea ?? "Pamekasan";

      // Bersihkan nama kota (hilangkan Kab/Kota jika perlu untuk UI)
      lokasiSaatIni.value = getNamaKota;
      notificationService.updateLokasi(getNamaKota);

      final result = await dioService.fetchJadwal(getNamaKota);
      jadwal.value = result;

      // --- LOGIKA NOTIFIKASI SHOLAT ---
      if (result != null && result['jadwal'] != null) {
        // Reset jadwal lama agar tidak duplikat
        await notificationService.cancelAllNotifications();

        final mapJadwal = result['jadwal'];

        // List waktu sholat yang ingin dinotifikasi
        final keys = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

        for (var key in keys) {
          if (mapJadwal[key] != null) {
            // Format Key jadi Capital (Subuh)
            String namaSholat = key[0].toUpperCase() + key.substring(1);
            String jam = mapJadwal[key]; // "04:15"

            // Jadwalkan
            await notificationService.scheduleSholatNotification(namaSholat, jam);
          }
        }
      }
      // --------------------------------

    } catch (e) {
      print("Error location/jadwal: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDoaDzikir() async {
    isLoading.value = true;
    doaDzikir.value = await dioService.fetchDoaDzikir();
    isLoading.value = false;
  }


  void toggleTestMode() {
    _tapCount++;
    if (_tapCount >= 5) { // Ketuk 5 kali untuk munculkan
      isTestMode.value = !isTestMode.value;
      Get.snackbar("Mode Debug", isTestMode.value ? "Fitur Test Aktif" : "Fitur Test Disembunyikan");
      _tapCount = 0;
    }
  }
  // 3. Logika Test Notifikasi (1 Menit ke depan)
  void triggerTestNotif() {
    final now = DateTime.now().add(const Duration(minutes: 1));
    final String jamTest = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    print("🔔 Menjadwalkan Test di jam: $jamTest");

    SholatNotification().scheduleSholatNotification("Test Adzan", jamTest);

    Get.snackbar("Test Dimulai", "Tunggu 1 menit. Kunci layar HP sekarang.",
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM
    );
  }
// Test 2: Bunyi Sekarang (Untuk cek suara & permission)
  void triggerImmediateTest() {
    SholatNotification().showTestAdzanNow();
    Get.snackbar("Info", "Mencoba membunyikan adzan sekarang...");
  }
  @override
  void onInit() async {
    super.onInit();
    // Pastikan service notifikasi diinit (ideally di main.dart, tapi disini safe check)
    // await notificationService.init();
    fetchJadwal();
    fetchDoaDzikir();
  }
}