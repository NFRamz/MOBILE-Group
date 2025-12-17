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

  final isTestMode = false.obs;
  int _tapCount = 0;

  final dioService = DioService();
  final notificationService = SholatNotification();

  @override
  void onInit() async {
    super.onInit();
    // 1. WAJIB INIT NOTIFIKASI DULU
    await notificationService.init();

    // 2. Baru ambil data
    fetchJadwal();
    fetchDoaDzikir();
  }

  Future<void> fetchJadwal() async {
    isLoading.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> convertKoordinatToNamaKota = await placemarkFromCoordinates(position.latitude, position.longitude);
      String getNamaKota = convertKoordinatToNamaKota[0].subAdministrativeArea ?? "Pamekasan";
      String namaKota_siapKirim = normalizeKota(getNamaKota);

      lokasiSaatIni.value = getNamaKota;
      notificationService.updateLokasi(getNamaKota);

      final result = await dioService.fetchJadwal(namaKota_siapKirim);
      jadwal.value = result;

      if (result != null && result['jadwal'] != null) {
        await notificationService.cancelAllNotifications();
        final mapJadwal = result['jadwal'];
        final keys = ['subuh', 'dzuhur', 'ashar', 'maghrib', 'isya'];

        for (var key in keys) {
          if (mapJadwal[key] != null) {
            String namaSholat = key[0].toUpperCase() + key.substring(1);
            String jam = mapJadwal[key];
            await notificationService.scheduleSholatNotification(namaSholat, jam);
          }
        }
      }
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
    if (_tapCount >= 5) {
      isTestMode.value = !isTestMode.value;
      Get.snackbar("Mode Debug", isTestMode.value ? "Fitur Test Aktif" : "Fitur Test Disembunyikan");
      _tapCount = 0;
    }
  }

  void triggerTestNotif() {
    final now = DateTime.now().add(const Duration(minutes: 1));
    final String jamTest = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    print("Menjadwalkan Test di jam: $jamTest");

    // Panggil fungsi schedule
    SholatNotification().scheduleSholatNotification("Test Adzan", jamTest);

    Get.snackbar("Test Dimulai", "Tunggu 1 menit. Notifikasi akan muncul pukul $jamTest",
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM
    );
  }

  void triggerImmediateTest() {
    SholatNotification().showTestAdzanNow();
    Get.snackbar("Info", "Mencoba membunyikan adzan sekarang...");
  }
}

String normalizeKota(String kota) {
  return kota.trim().replaceFirst(
    RegExp(r'^(Kabupaten |KABUPATEN |Kab\. |KAB\. |Kab |KAB |Kota |KOTA )'),
    '',
  );
}
