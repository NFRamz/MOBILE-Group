import 'package:aisyiyah_smartlife/modules/jadwalKegiatan/controllers/jadwal_kegiatan_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:aisyiyah_smartlife/core/values/AppColors.dart';

class JadwalKegiatanView extends GetView<JadwalKegiatanController> {
  const JadwalKegiatanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title          : const Text('Jadwal Kegiatan'),
        backgroundColor: AppColors.primaryGreen,
        actions: [
          // --- TOMBOL EXPORT EXCEL ---
          Obx(() {
        // Kita gunakan logic 'showEditButton' yang sudah ada
        // Asumsinya: Yang boleh nambah data, boleh rekap data.
        if (controller.showEditButton) {
      return IconButton(
        icon: const Icon(Icons.file_download_outlined, color: Colors.white),
        tooltip: 'Export ke Excel',
        onPressed: () => controller.exportToExcel(),
      );
    }
    return const SizedBox.shrink();
  }),

    const SizedBox(width: 8), // Sedikit jarak
    ],
    ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh : controller.refreshData,
          child     : FutureBuilder<List<Map<String, dynamic>>>(
            future    : controller.kegiatanFuture.value,
            builder   : (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Belum ada kegiatan. Tarik untuk refresh.'),
                );
              }

              final List<Map<String, dynamic>> allDocs = snapshot.data!;

              allDocs.sort((a, b) {
                final ta = DateTime.parse(a['tanggal']);
                final tb = DateTime.parse(b['tanggal']);
                return tb.compareTo(ta);
              });

              return ListView(
                padding: const EdgeInsets.all(8),
                children: allDocs.map((doc) {
                  return _buildKegiatanCard(context, doc);
                }).toList(),
              );
            },
          ),
        );
      }),

      floatingActionButton: Obx(() {
        if (!controller.showEditButton) return const SizedBox.shrink();
        return FloatingActionButton(
          backgroundColor : AppColors.primaryGreen,
          child           : const Icon(Icons.add),
          onPressed       : () => _showKegiatanDialog(context, null),
        );
      }),
    );
  }

  Widget _buildKegiatanCard(BuildContext context, Map<String, dynamic> doc) {
    final data = doc;
    final bool isDaerah = data['tipe'] == 'Daerah';

    final tanggalIso        = data['tanggal'];
    final tanggalFormatted  = controller.formatTanggal(tanggalIso);

    return Card(
      margin    : const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color     : AppColors.warmWhite,
      shape     : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation : 2,
      child     : InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (controller.userCanEditRow(doc)) {
            _showKegiatanDialog(context, doc);
          }
        },
        child     : Padding(
          padding : EdgeInsets.all(16.0),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['namaKegiatan'] ?? 'Tanpa Nama',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  Chip(
                    backgroundColor:
                    isDaerah ? Colors.orange.shade700 : AppColors.primaryGreen,
                    label: Text(data['tipe'], style:TextStyle(color: Colors.white)),
                  )
                ],
              ),

              const Divider(height: 24),

              _infoRow(Icons.calendar_today, tanggalFormatted),
              const SizedBox(height: 8),

              _infoRow(Icons.home, data['lokasi']),
              const SizedBox(height: 8),

              _infoRow(Icons.location_on, "${data['ranting'] ?? '-'}, ${data['daerah'] ?? '-'}"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        )
      ],
    );
  }

  //tmabah kegiatan
  void _showKegiatanDialog(BuildContext context, Map<String, dynamic>? doc) {
    final bool isEditing = doc != null;

    final role = controller.userRole.value;

    final TextEditingController namaController    = TextEditingController(text: doc?['namaKegiatan']);
    final TextEditingController lokasiController  = TextEditingController(text: doc?['lokasi']);

    DateTime selectedDate   = (doc != null) ? DateTime.parse(doc['tanggal']) : DateTime.now();
    TimeOfDay selectedTime  = TimeOfDay.fromDateTime(selectedDate);

    String selectedTipe = role == 'Pimpinan Daerah' ? 'Daerah' : 'Desa';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing ? "Edit Kegiatan" : "Tambah Kegiatan"),

            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: namaController,
                    decoration: InputDecoration(labelText: "Nama Kegiatan"),
                  ),
                  TextField(
                    controller: lokasiController,
                    decoration: InputDecoration(labelText: "Lokasi"),
                  ),

                  const SizedBox(height: 16),

                  //pilih tanggal
                  ListTile(
                    title   : Text("Tanggal: ${DateFormat('d MMMM yyyy').format(selectedDate)}"),
                    trailing: const Icon(Icons.calendar_month),
                    onTap   : () async {
                      final picked = await showDatePicker(
                        context     : context,
                        initialDate : selectedDate,
                        firstDate   : DateTime(2025),
                        lastDate    : DateTime(2045),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),

                  //pilih waktu
                  ListTile(
                    title   : Text("Waktu: ${selectedTime.format(context)}"),
                    trailing: const Icon(Icons.access_time),
                    onTap   : () async {
                      final picked = await showTimePicker(
                        context     : context,
                        initialTime : selectedTime,
                      );
                      if (picked != null){
                        setStateDialog(() {
                          selectedTime = picked;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  Text("Tipe: $selectedTipe", style: const TextStyle(fontWeight: FontWeight.bold))
                ],
              ),
            ),

            actions: [
              if (isEditing && controller.userCanEditRow(doc))
                TextButton(
                  onPressed: () => controller.deleteKegiatan(doc['id']),
                  child    : const Text("Hapus", style : TextStyle(color: Colors.red))),

              TextButton(
                onPressed: () => Get.back(),
                child: const Text("Batal"),
              ),

              ElevatedButton(
                child: const Text("Simpan"),
                onPressed: () async {
                  if (namaController.text.isEmpty || lokasiController.text.isEmpty) {
                    Get.snackbar("Error", "Nama dan lokasi wajib diisi", backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }

                  //Gabung tanggal,waktu
                  final combinedDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);

                  await controller.saveKegiatan(
                    namaKegiatan: namaController.text,
                    lokasi      : lokasiController.text,
                    tanggal     : combinedDateTime,
                    tipe        : selectedTipe,
                    desa        : role == 'AdminDesa' ? controller.userRanting.value : null,
                    docId       : isEditing ? doc['id'] : null,
                  );
                },
              ),
            ],
          );
        });
      },
    );
  }
}
