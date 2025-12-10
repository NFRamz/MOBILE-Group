import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

//notif

import 'package:googleapis_auth/auth_io.dart';

class JadwalKegiatanController extends GetxController {
  final supabase = Supabase.instance.client;

  final userRole    = Rx<String?>(null);
  final userDaerah  = Rx<String?>(null);
  final userRanting = Rx<String?>(null);

  // utk List dropdown ranting
  final rantingList = <String>[].obs;

  final kegiatanFuture = Rx<Future<List<Map<String, dynamic>>>?>(null);
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadInitialData();
    });
  }

  Future<T> fetchWithTimeout<T>(Future<T> future) async {
    return await Future.any([
      future,
      Future.delayed(const Duration(seconds: 5), () {
        throw TimeoutException("Supabase timeout 5 detik");

      })
    ]);
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;

    try {
      await fetchWithTimeout(fetchUserData());
      kegiatanFuture.value = fetchWithTimeout(fetchKegiatanData());
    } catch (e) {
      print("Timeout,load mode offline(hive)");
      final offline         = await loadKegiatanOffline();
      kegiatanFuture.value  = Future.value(offline);
    }

    isLoading.value = false;
  }
//=================== NOTIF ===============
  Future<String> _getAccessToken() async {
    // ⚠️ PASTE ISI FILE JSON SERVICE ACCOUNT ANDA DI BAWAH INI ⚠️
    // Pastikan formatnya Map<String, dynamic> seperti contoh.
    // Ganti seluruh isi map di bawah dengan isi file JSON yg anda download.
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "aisyiyah-smart-life",
      "private_key_id": "13bdeb97124",
      "private_key": "-----BEGIN PRIVATE KEY-----\k6NzQ1A2LxhRkGyUN6+Tyo0cW8Hv0YjUul6Pw\nyMJxDXojcUMeD6JS7FTsV8kRjsQjYQO1Lyx6/oQoJYvtU83ubHJ5DoxwY2pvs5Wo\nBQ5BkjackUlE+CGWK2AZsDJG\n-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk",
      "client_id": "1151",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk",
      "universe_domain": "googleapis.com"
    };


    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    try {
      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );
      // Ambil token dan tutup client agar tidak memory leak
      final credentials = await client.credentials;
      client.close();
      return credentials.accessToken.data;
    } catch (e) {
      print("❌ Error Auth Google: $e");
      throw e;
    }
  }

  Future<void> sendFCMNotification(String title, String body) async {
    try {
      // 1. Dapatkan Access Token (Berubah tiap jam)
      final String accessToken = await _getAccessToken();

      // Ambil Project ID dari JSON di atas (bisa hardcode atau ambil dari map)
      // Contoh: 'aisyiyah-smart-life'
      // Pastikan sesuai dengan project_id di file JSON
      const String projectId = 'aisyiyah-smart-life';

      // 2. URL HTTP v1
      final String endpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      // 3. Kirim Request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Pakai Bearer Token
        },
        body: jsonEncode({
          "message": {
            "topic": "info_kegiatan", // Target Topic
            "notification": {
              "title": title,
              "body": body,
            },
            "data": {
              "type": "kegiatan", // Payload data untuk navigasi
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Notifikasi V1 Berhasil Dikirim!");
      } else {
        print("❌ Gagal Kirim V1: ${response.body}");
      }
    } catch (e) {
      print("❌ Error Send FCM V1: $e");
    }
  }
//=================== NOTIF  END ===============


  Future<void> exportToExcel() async {
    try {
      // 1. Cek apakah data sudah siap
      final currentList = await kegiatanFuture.value;

      if (currentList == null || currentList.isEmpty) {
        Get.snackbar("Info", "Tidak ada data kegiatan untuk diexport.",
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      isLoading.value = true; // Tampilkan loading indikator (opsional)

      // 2. Buat File Excel
      var excel = Excel.createExcel();

      // Rename Sheet 1
      String sheetName = 'Rekap Kegiatan';
      Sheet sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      // 3. Buat Header (Tanpa ID sesuai permintaan)
      // Urutan kolom kita atur agar enak dibaca
      List<String> headers = [
        'No',
        'Nama Kegiatan',
        'Tipe',
        'Tanggal',
        'Jam',
        'Lokasi',
        'Ranting',
        'Daerah'
      ];

      // Masukkan Header ke baris pertama
      sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

      // 4. Masukkan Data (Looping)
      int no = 1;

      // Sortir data berdasarkan tanggal terbaru (opsional, biar rapi)
      currentList.sort((a, b) => DateTime.parse(b['tanggal']).compareTo(DateTime.parse(a['tanggal'])));

      for (var row in currentList) {
        // Parsing Tanggal & Jam dari format ISO database
        DateTime dt = DateTime.parse(row['tanggal']);
        String tglStr = DateFormat('dd-MM-yyyy').format(dt);
        String jamStr = DateFormat('HH:mm').format(dt);

        // Mapping data database ke kolom Excel
        List<CellValue> dataRow = [
          IntCellValue(no++),
          TextCellValue(row['namaKegiatan'] ?? '-'),
          TextCellValue(row['tipe'] ?? '-'),
          TextCellValue(tglStr),
          TextCellValue(jamStr),
          TextCellValue(row['lokasi'] ?? '-'),
          TextCellValue(row['ranting'] ?? '-'), // Jika null (kegiatan Daerah), isi '-'
          TextCellValue(row['daerah'] ?? '-'),
        ];

        sheet.appendRow(dataRow);
      }

      // 5. Simpan file ke folder temporary
      var fileBytes = excel.save();
      var directory = await getTemporaryDirectory();

      // Nama file unik dengan timestamp
      String timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      String fileName = "Rekap_Kegiatan_Aisyiyah_$timestamp.xlsx";

      File file = File("${directory.path}/$fileName")
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      isLoading.value = false;

      // 6. Share File (Memicu dialog Android/iOS)
      // User bisa pilih "Save to Files" atau kirim ke WA
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Berikut adalah Rekap Kegiatan Aisyiyah per $timestamp',
      );

    } catch (e) {
      isLoading.value = false;
      print("Error Export: $e");
      Get.snackbar("Gagal", "Terjadi kesalahan saat export excel.",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> saveKegiatanOffline(List<Map<String, dynamic>> list) async {
    final box = Hive.box('kegiatanBox');
    await box.put('items', list);
  }

  Future<List<Map<String, dynamic>>> loadKegiatanOffline() async {
    final box   = Hive.box('kegiatanBox');
    final data  = box.get('items');

    if (data is List) {
      return data.map((row) {
        return Map<String, dynamic>.from(row as Map);
      }).toList();
    }

    return [];
  }

  Future<void> fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;

        final result = await supabase.from('profiles').select('role, daerah, ranting').eq('id', user!.id).maybeSingle();

        userRole.value    = result?['role'] as String?;
        userDaerah.value  = result?['daerah'] as String?;
        userRanting.value = result?['ranting'] as String?;


      kegiatanFuture.value  = fetchKegiatanData();
      isLoading.value       = false;
    } catch (_) {
      isLoading.value = false;
      Get.snackbar('Error', 'Gagal memuat data pengguna', backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }


  Future<List<Map<String, dynamic>>> fetchKegiatanData() async {
    try {
      final role    = userRole.value;
      final daerah  = userDaerah.value;
      final ranting = userRanting.value;

      if (role == null || daerah == null) return [];

      List<Map<String, dynamic>> fetched = [];

      if (role == 'Pimpinan Daerah') {
        final res = await supabase.from('kegiatan').select().eq('daerah', daerah).order('tanggal', ascending: true);

        fetched = List<Map<String, dynamic>>.from(res);
      } else {
        final resDesa   = await supabase.from('kegiatan').select().eq('ranting', ranting ?? '').eq('daerah', daerah);
        final resDaerah = await supabase.from('kegiatan').select().eq('tipe', 'Daerah').eq('daerah', daerah);

        final listA = List<Map<String, dynamic>>.from(resDesa);
        final listB = List<Map<String, dynamic>>.from(resDaerah);

        final map = <String, Map<String, dynamic>>{};
        for (final row in [...listA, ...listB]) {
          final key = (row['id'] ?? '').toString();
          map[key]  = row;
        }

        fetched = map.values.toList();
      }

      //Hive
      await saveKegiatanOffline(fetched);

      return fetched;
    } catch (e) {
      print("⚠️ Supabase error, load offline: $e");

      return loadKegiatanOffline();
    }
  }


  String formatTanggal(String timestampIso) {
    final dt = DateTime.parse(timestampIso);
    return DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID').format(dt);
  }

  bool userCanEditRow(Map<String, dynamic> kegiatanRow) {
    final role    = userRole.value;
    final daerah  = userDaerah.value;
    final ranting = userRanting.value;

    if (role == 'Pimpinan Daerah') {
      return (kegiatanRow['tipe'] == 'Daerah') && (kegiatanRow['daerah']?.toString() == daerah);
    }
    if (role == 'AdminDesa') {
      return (kegiatanRow['tipe'] == 'Desa') && (kegiatanRow['daerah']?.toString() == daerah) && (kegiatanRow['ranting']?.toString() == ranting);
    }
    return false;
  }


  Future<void> saveKegiatan({String? namaKegiatan, String? lokasi, DateTime? tanggal, String? tipe, String? desa, String? rantingInput, String? docId,}) async {
    try {
      final role    = userRole.value;
      final daerah  = userDaerah.value;
      final ranting = userRanting.value;

      String tipe;
      String? lokasiRanting;

      if (role == 'Pimpinan Daerah') {
        tipe          = 'Daerah';
        lokasiRanting = null;
      } else if (role == 'AdminDesa') {
        tipe          = 'Desa';
        lokasiRanting = ranting;
      } else {
        throw 'Anda tidak memiliki izin untuk menambah kegiatan.';
      }

      final newData = <String, dynamic>{'namaKegiatan': namaKegiatan, 'lokasi'  : lokasi, 'tanggal' : tanggal?.toIso8601String(), 'tipe'    : tipe, 'daerah'  : daerah, 'ranting' : lokasiRanting};

      if (docId == null) {
        await supabase.from('kegiatan').insert(newData);

        String tglIndo = DateFormat('dd MMM, HH:mm').format(tanggal!);
        await sendFCMNotification("Kegiatan Baru: $namaKegiatan", "Lokasi: $lokasi, Pukul: $tglIndo");
      } else {
        final updateData = Map<String, dynamic>.from(newData);
        if (role == 'Pimpinan Daerah') {
          updateData['tipe']    = 'Daerah';
          updateData['daerah']  = daerah;
          updateData['ranting'] = null;
        } else {
          updateData['tipe']    = 'Desa';
          updateData['daerah']  = daerah;
          updateData['ranting'] = ranting;
        }

        await supabase.from('kegiatan').update(updateData).eq('id', docId);
      }

      await tutupMiniDialog();
      Get.snackbar('Sukses', 'Kegiatan berhasil disimpan!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Gagal menyimpan kegiatan: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


  Future<void> deleteKegiatan(String docId) async {
    try {
      await supabase.from('kegiatan').delete().eq('id', docId);
      await tutupMiniDialog();

      Get.snackbar('Sukses', 'Kegiatan berhasil dihapus', backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus kegiatan: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


  Future<void> refreshData() async {
    isLoading.value      = true;
    kegiatanFuture.value = fetchKegiatanData();
    isLoading.value      = false;
  }

  Future<void> tutupMiniDialog() async {
    Get.back();
    await refreshData();

  }


  bool get showEditButton => userRole.value == 'Pimpinan Daerah' || userRole.value == 'AdminDesa';
}
