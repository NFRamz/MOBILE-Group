import 'package:aisyiyah_smartlife/modules/jadwalSholat/controllers/pilih_lokasi_controller.dart';
import 'package:get/get.dart';

class PilihLokasiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PilihLokasiController>(
          () => PilihLokasiController(),
    );
  }
}