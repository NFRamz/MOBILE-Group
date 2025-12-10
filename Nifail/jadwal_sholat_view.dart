// lib/view/jadwal_view.dart
import 'package:aisyiyah_smartlife/modules/jadwalSholat/controllers/jadwal_sholat_controller.dart';
import 'package:aisyiyah_smartlife/core/values/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class JadwalSholatView extends StatelessWidget {
  const JadwalSholatView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(JadwalSholatController());

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => controller.toggleTestMode(),
          child: const Text("Jadwal Sholat"),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.warmWhite,
        actions: [
          IconButton(
              icon: const Icon(Icons.map),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                color: AppColors.softCream_2,
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.lokasiSaatIni.value,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(dataJadwal['daerah'] ?? '-',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey)),
                      const Divider(height: 30),

                      ...waktu.entries.map((waktuSholat) =>
                          _buildRow(waktuSholat.key, waktuSholat.value)),

                      const SizedBox(height: 20),

                      Card(
                        color: AppColors.warmWhite,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Doa & Dzikir Waktu Sekarang',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                              const SizedBox(height: 10),
                              Obx(() => controller.doaDzikir.value.isEmpty
                                  ? const Text('Memuat doa...',
                                  style: TextStyle(color: Colors.grey))
                                  : Text(controller.doaDzikir.value,
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.4))),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- AREA TOMBOL TEST (RAHASIA) ---
              Obx(() => Visibility(
                visible: controller.isTestMode.value,
                child: Column(
                  children: [
                    // Tombol 1: Test Bunyi Sekarang
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, // Warna Oranye
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => controller.triggerImmediateTest(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("TEST BUNYI (SEKARANG)"),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tombol 2: Test Jadwal 1 Menit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent, // Warna Merah
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => controller.triggerTestNotif(),
                        icon: const Icon(Icons.timer),
                        label: const Text("TEST JADWAL (1 MENIT LAGI)"),
                      ),
                    ),
                  ],
                ),
              )),

            ],
          ),
        );
      }),
    );
  }

  Widget _buildRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text('$value',
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}