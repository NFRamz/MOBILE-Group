
import 'package:aisyiyah_smartlife/modules/jadwalSholat/controllers/jadwal_sholat_controller.dart';
import 'package:get/get.dart';

class JadwalSholatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JadwalSholatController>(
          () => JadwalSholatController(),
    );
  }
}