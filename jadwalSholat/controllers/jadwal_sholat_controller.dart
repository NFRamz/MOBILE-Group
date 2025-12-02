import 'package:aisyiyah_smartlife/modules/jadwalSholat/service/dio.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';




class JadwalSholatController extends GetxController {
  var jadwal        = Rxn<Map<String, dynamic>>();
  var doaDzikir     = ''.obs;
  var isLoading     = false.obs;
  var lokasiSaatIni = 'Mencari Lokasi...'.obs;

  final dioService = DioService();


  Future<void> fetchJadwal() async {
    isLoading.value = true;
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      List<Placemark> convertKoordinatToNamaKota = await placemarkFromCoordinates(position.latitude, position.longitude);
      String getNamaKota                         = convertKoordinatToNamaKota[0].subAdministrativeArea ?? "Pamekasan";
      lokasiSaatIni.value                        = getNamaKota;
      jadwal.value                               = await dioService.fetchJadwal(getNamaKota);

  }

  Future<void> fetchDoaDzikir() async {
    isLoading.value = true;
    doaDzikir.value = await dioService.fetchDoaDzikir();
    isLoading.value = false;
  }

  @override
  void onInit() async {
    super.onInit();
    fetchJadwal();
    fetchDoaDzikir();
  }
}
