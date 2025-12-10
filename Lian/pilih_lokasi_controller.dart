import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'jadwal_sholat_controller.dart';

class PilihLokasiController extends GetxController {
  final MapController mapController = MapController();

  var latitude         = 0.0.obs;
  var longitude        = 0.0.obs;
  var accuracy         = 0.0.obs;
  var speed            = 0.0.obs;
  var timestamp        = ''.obs;
  var isGpsMode        = true.obs;
  var currentPosition  = LatLng(-7.0, 110.0).obs;
  var isLoadingAddress = false.obs;


  StreamSubscription<Position>? _positionStream;

  @override
  void onInit() {
    super.onInit();
    startLiveTracking();
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    super.onClose();
  }

  void toggleMode(bool value) {
    isGpsMode.value = value;
    stopTracking();
    startLiveTracking();
  }

  void stopTracking() {
    _positionStream?.cancel();
  }

  void tombolLokasiSaya() => mapController.move(currentPosition.value, 19.0);

  Future<void> setLokasiJadwal() async {
    isLoadingAddress.value = true;
    try {

      List<Placemark> ambilNamaKota = await placemarkFromCoordinates(latitude.value, longitude.value);

      if (ambilNamaKota.isNotEmpty) {
        String namaKota = ambilNamaKota[0].subAdministrativeArea ?? "KAB. PAMEKASAN";
        namaKota        = namaKota.replaceAll("Kabupaten ", "").replaceAll("Kota ", "");

        final cariJadwalSholatController               = Get.find<JadwalSholatController>();
        cariJadwalSholatController.lokasiSaatIni.value = namaKota;
        var newData = await cariJadwalSholatController.dioService.fetchJadwal(namaKota);
        cariJadwalSholatController.jadwal.value = newData;

        Get.back();
        Get.snackbar("Berhasil", "Lokasi diubah ke $namaKota", backgroundColor: Colors.green, colorText: Colors.white);

      }
    } catch (e) {
      Get.snackbar("Error", "Gagal mendapatkan nama kota", backgroundColor: Colors.red, colorText: Colors.white);}
    finally {
      isLoadingAddress.value = false;
    }
  }

  void startLiveTracking() async {
    LocationSettings locationSettings = LocationSettings(accuracy: isGpsMode.value ? LocationAccuracy.best : LocationAccuracy.low, distanceFilter: 0);

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {

      currentPosition.value = LatLng(position.latitude, position.longitude);
      latitude.value        = position.latitude;
      longitude.value       = position.longitude;
      accuracy.value        = position.accuracy;
      speed.value           = position.speed;
      timestamp.value       = DateTime.now().toString();
    });
  }
}