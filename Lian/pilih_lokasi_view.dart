// lib/view/pilih_lokasi_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import '/modules/jadwalSholat/controllers/pilih_lokasi_controller.dart';
import 'package:aisyiyah_smartlife/core/values/AppColors.dart';

class PilihLokasiView extends StatelessWidget {
  const PilihLokasiView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PilihLokasiController());

    return Scaffold(
      appBar  : AppBar(title : const Text("Pilih Lokasi & Eksperimen"), backgroundColor: AppColors.primaryGreen, foregroundColor: AppColors.warmWhite),

      body: Stack(
        children: [
          Obx(() {
            return FlutterMap(

              mapController: controller.mapController,
              options : MapOptions(initialCenter: controller.currentPosition.value, initialZoom: 15.0, interactionOptions: const InteractionOptions(flags: InteractiveFlag.all)),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.aisyiyah_smartlife'),
                MarkerLayer(
                  markers: [
                    Marker(point: controller.currentPosition.value, width: 80, height: 80, child: const Icon(Icons.location_pin, color: Colors.red, size: 40))
                  ],
                ),
              ],
            );
          }),

          //tombol parani
          Positioned(top: 5, right: 16,
            child: Material(elevation: 4, shape: const CircleBorder(),
              child: InkWell(
                onTap       : () => controller.tombolLokasiSaya(),
                borderRadius: BorderRadius.circular(50),
                child       : Container(width: 56, height: 56, decoration : BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle), child: const Icon(Icons.my_location, color: Colors.white, size: 24))
              ),
            ),
          ),

          // panel bawah
          Positioned(bottom: 20, left: 20, right: 20,
            child   : Card(color : Colors.white.withOpacity(0.95), elevation : 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child   : Padding(
                padding : const EdgeInsets.all(16.0),
                child   : Column(mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Mode Akurasi:", style: TextStyle(fontWeight: FontWeight.bold)),

                        Obx(() => Row(
                          children: [
                            Text(controller.isGpsMode.value ? "GPS" : "Network", style:
                                TextStyle(color: controller.isGpsMode.value ? Colors.blue : Colors.orange, fontWeight: FontWeight.bold)
                            ),

                            Switch(value: controller.isGpsMode.value, onChanged: (val) => controller.toggleMode(val), activeColor: AppColors.primaryGreen)
                          ],
                        )),
                      ],
                    ),
                    const Divider(),

                    // debug
                    Obx(() => Column(
                      children: [
                        _infoRow("Lat/Long", "${controller.latitude.value.toStringAsFixed(5)}, ${controller.longitude.value.toStringAsFixed(5)}"),
                        _infoRow("Akurasi", "${controller.accuracy.value.toStringAsFixed(1)} m"),
                        _infoRow("Update", controller.timestamp.value.split(' ').last),
                      ],
                    )),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,

                      child: Obx(() => ElevatedButton.icon(
                        style     : ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed : controller.isLoadingAddress.value ? null : () => controller.setLokasiJadwal(),
                        icon      : controller.isLoadingAddress.value ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle),
                        label     : Text(controller.isLoadingAddress.value ? "Sedang memuat..." : "Gunakan Lokasi Ini"),
                      )),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}