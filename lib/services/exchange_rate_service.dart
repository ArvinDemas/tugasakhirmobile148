/**
 * File: exchange_rate_service.dart
 * Deskripsi: Class service untuk mengambil data kurs mata uang
 * dari v6.exchangerate-api.com.
 */

import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  // --- KONFIGURASI API ---
  final String _apiKey = 'bc6656c1069dc623d97e10e1'; // API Key Anda
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6/';

  // --- FUNGSI UNTUK MENGAMBIL KURS ---
  /**
   * Mengambil data kurs mata uang terbaru berdasarkan mata uang dasar (baseCurrency).
   * Parameter:
   * - baseCurrency: Mata uang dasar (misal 'GBP' untuk Pound Sterling).
   * Mengembalikan:
   * - Future<Map<String, dynamic>>: Map yang berisi nilai tukar (conversion_rates).
   */
  Future<Map<String, dynamic>> getRates(String baseCurrency) async {
    // Susun URL lengkap: https://v6.exchangerate-api.com/v6/API_KEY/latest/MATA_UANG
    final String url = '$_baseUrl$_apiKey/latest/$baseCurrency';
    print('[ExchangeRateService] Requesting: $url'); // Debug print

    try {
      // Lakukan GET request
      final response = await http.get(Uri.parse(url));

      // Cek jika request berhasil (status code 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // Ubah JSON string ke Map

        // Cek apakah API mengembalikan status 'success'
        if (data != null && data['result'] == 'success' && data['conversion_rates'] != null) {
          print('[ExchangeRateService] Rates fetched successfully.');
          // Kembalikan hanya bagian 'conversion_rates'
          return data['conversion_rates'] as Map<String, dynamic>;
        } else {
          // Jika API mengembalikan error (misal key salah, base currency tidak ada)
          final errorType = data != null ? data['error-type'] : 'Unknown error';
          print('[ExchangeRateService] API Error: $errorType');
          throw Exception('Gagal memuat kurs (API Error): $errorType');
        }
      } else {
        // Jika server merespons dengan status code error (404, 500, dll)
        print('[ExchangeRateService] Server Error: ${response.statusCode}');
        throw Exception('Gagal memuat kurs (Server Error: ${response.statusCode})');
      }
    } catch (e) {
      // Tangkap error jaringan (tidak ada internet, dll)
      print('[ExchangeRateService] Network/Parsing Error: $e');
      throw Exception('Gagal terhubung ke server kurs: $e');
    }
  }
}
