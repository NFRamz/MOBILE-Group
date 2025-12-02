// lib/view/jadwal_view.dart
import 'package:aisyiyah_smartlife/modules/jadwalSholat/controllers/jadwal_sholat_controller.dart';
import 'package:aisyiyah_smartlife/core/values/AppColors.dart';
import 'package:aisyiyah_smartlife/modules/jadwalSholat/views/pilih_lokasi_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JadwalSholatView extends StatelessWidget {
  const JadwalSholatView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JadwalSholatController());


    return Scaffold(
      appBar: AppBar(title:const Text("Jadwal Sholat"),backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.warmWhite,
        actions: [
          IconButton(icon: const Icon(Icons.map),
            onPressed: () {
              Get.toNamed("/pilihlokasi");
            })
        ],
      ),

      body: Obx(() {
        if (controller.isLoading.value || controller.jadwal.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

          final dataJadwal = controller.jadwal.value!;
          final waktu = dataJadwal['jadwal'];

          return SingleChildScrollView(
            padding : const EdgeInsets.all(16),
            child   : Card(color: AppColors.softCream_2, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child    : Padding(
                padding : const EdgeInsets.all(20),
                child   : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children          : [

                    Text(controller.lokasiSaatIni.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                        dataJadwal['daerah'] ?? '-', // Gunakan ?? '-' untuk jaga-jaga jika null
                        style: const TextStyle(fontSize: 16, color: Colors.grey)
                    ),
                    const Divider(height: 30),

                    ...waktu.entries.map((waktuSholat) => _buildRow(waktuSholat.key, waktuSholat.value)),

                    Card(
                      color    : AppColors.warmWhite,
                      elevation: 3,
                      shape    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child    : Padding(
                        padding : const EdgeInsets.all(16),
                        child   : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Doa & Dzikir Waktu Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),

                            const SizedBox(height: 10),

                            Obx(() =>
                            controller.doaDzikir.value.isEmpty ? const Text('Memuat doa...', style: TextStyle(color: Colors.grey)) : Text(controller.doaDzikir.value, style: const TextStyle(fontSize: 15, height: 1.4))),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),


                  ],
                ),
              ),
            ),
          );
      }),
    );
  }


  Widget _buildRow(String title, dynamic value) {
    return Padding(
      padding : const EdgeInsets.symmetric(vertical: 4),
      child   : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text('$value', style:const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}
