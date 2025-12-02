import 'package:dio/dio.dart';
import 'package:intl/intl.dart';


class DioService {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://apidl.asepharyana.tech/api'))..interceptors.add(LogInterceptor(
    request: true,
    responseBody: true,
    error: true,
  ));

  Future<Map<String, dynamic>?> fetchJadwal(String kota) async {
    try {
      final response = await dio.get('/search/jadwal-sholat?kota=$kota');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['schedules'] != null && (data['schedules'] as List).isNotEmpty) {
          List<dynamic> schedules = data['schedules'];
          String searchKey        = kota.toUpperCase().trim();
          var bestMatch;

          for (var item in schedules) {
            if (item['lokasi'] == 'KOTA $searchKey') {
              bestMatch = item;
              break;
            }
          }

          if (bestMatch == null) {
            for (var item in schedules) {
              if (item['lokasi'] == 'KAB. $searchKey') {
                bestMatch = item;
                break;
              }
            }
          }

          if (bestMatch == null) {
            for (var item in schedules) {
              String lokasiApi = item['lokasi'];
              if (lokasiApi.contains(' $searchKey')) {
                bestMatch = item;
                break;
              }
            }
          }

          if (bestMatch == null) {
            bestMatch = schedules[0];
          }

          print("Hasil pencarian untuk $kota: Mengambil ${bestMatch['lokasi']}");


          return bestMatch as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error mengambil jadwal: $e');
    }
    return null;
  }

  Future<String> fetchDoaDzikir() async {
    try {
      final now           = DateTime.now();
      final waktuSekarang = DateFormat('HH.mm').format(now);

      final url = 'https://apidl.asepharyana.tech/api/ai/v2/chatgpt?text=doa%20dan%20dzikir%20waktu%20$waktuSekarang&prompt=to%20the%20point%2C%20langsung%20ke%20isi%20dan%20hHINDARI%20tanda%20bintang!%20dan%20anda%20hanya%20membuat%20saran%20yang%20relevan%20dengan%20fitur%20jadwal%20sholat%20buat%20jawaban%20yang%20informatif%20detail%20sertakan%20bacaan%20doanya';

      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['result'];
      } else {
        return 'Gagal mengambil doa & dzikir.';
      }
    } catch (e) {
      return 'Terjadi kesalahan: $e';
    }
  }

}
