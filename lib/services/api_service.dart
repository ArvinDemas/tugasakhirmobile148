/**
 * File: api_service.dart
 * Deskripsi: Class service untuk API-Sports F1 (Versi PRO).
 *
 * FIX:
 * - Mengganti header 'x-rapidapi-key' & 'host' menjadi 'x-apisports-key'
 * (sesuai untuk langganan Pro langsung, BUKAN RapidAPI).
 * - Mengganti 'as Map' dengan 'Map.from()' dan pengecekan 'is Map'
 * di _getLastRaceInfo dan _getWinnerRanking untuk mencegah TypeCastError.
 * - Memperbaiki endpoint 'rankings/startinggrid' (tanpa underscore).
 */

import 'dart:convert'; // Untuk jsonDecode
import 'package:http/http.dart' as http; // Untuk HTTP request
import 'dart:async'; // Untuk TimeoutException

class ApiService {
  // --- KONFIGURASI API ---
  final String _baseUrl = 'https://v1.formula-1.api-sports.io/';
  final String _apiKey = '75ab196bd9fff881953b261a11be2df4'; // API Key Pro Anda
  
  // Gunakan Tahun Musim Saat Ini (Public)
  final String currentSeasonYear = DateTime.now().year.toString(); // Akan jadi "2025"

  // --- FUNGSI HELPER INTERNAL ---
  Future<dynamic> _getRequest(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    print('[ApiService] Requesting (API-Sports): $uri');

    // --- FIX: Ganti Headers ke API-Sports Pro (bukan RapidAPI) ---
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'x-apisports-key': _apiKey,
      // 'x-rapidapi-key': _apiKey, // HAPUS
      // 'x-rapidapi-host': 'v1.formula-1.api-sports.io', // HAPUS
    };

    if (_apiKey.isEmpty || _apiKey == 'MASUKKAN_API_KEY_KAMU_DISINI') {
       print('[ApiService] ERROR: API Key kosong!');
       throw Exception('API Key API-Sports belum dimasukkan!');
    }

    try {
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // --- TAMBAHKAN LOGGING RAW RESPONSE ---
        print('[ApiService] Raw Response Body: ${response.body}');
        final decodedBody = jsonDecode(response.body);

        // Cek error dari API Sports
         if (decodedBody is Map && decodedBody.containsKey('errors') && (decodedBody['errors'] as List).isNotEmpty) {
           // Versi API-Sports Pro mungkin mengembalikan List di 'errors'
           final errorsData = decodedBody['errors'] as List;
           String errorMessage = errorsData.toString();
           
           if (errorsData.isNotEmpty && errorsData[0] is Map) {
              final errorMap = errorsData[0] as Map;
              if (errorMap.containsKey('token')) {
                 errorMessage = 'API Key Error: ${errorMap['token']}';
              } else if (errorMap.containsKey('requests')) {
                 errorMessage = 'API Limit Error: ${errorMap['requests']}';
              }
              //... tambahkan cek error lain jika perlu
           } else if (errorsData.isNotEmpty && errorsData[0] is String) {
              errorMessage = errorsData[0]; // Kadang error hanya string
           }

           print('[ApiService] API Error Response: $errorMessage');
           throw Exception('API Error: $errorMessage');
         }

        // Data utama
        if (decodedBody is Map && decodedBody.containsKey('response')) {
          print('[ApiService] Request successful, returning response data.');
          if (decodedBody['response'] is List) {
             return decodedBody['response'];
          } else {
             print('[ApiService] WARNING: Expected List in "response" key, but got ${decodedBody['response'].runtimeType}');
             return [];
          }
        }
        
         if (decodedBody is List) {
           print('[ApiService] Response is a List, returning directly.');
           return decodedBody;
         }

        print('[ApiService] WARNING: Unexpected API Response Structure: $decodedBody');
        return [];

      } else {
        print('[ApiService] ERROR: Request failed with status ${response.statusCode}. Body: ${response.body}');
        throw Exception('Gagal memuat data (${response.statusCode})');
      }
    } catch (e) {
      print('[ApiService] ERROR during API request execution: $e');
      if (e is TimeoutException) {
         throw Exception('Koneksi ke server API timeout. Coba lagi.');
      }
      if (e is http.ClientException) {
         throw Exception('Gagal terhubung ke server. Periksa koneksi internet Anda.');
      }
      rethrow;
    }
  }

  // --- FUNGSI PUBLIK (API PRO) ---

  Future<List<dynamic>> getNextRace() async {
    const endpoint = 'races';
    final queryParams = {
      'season': currentSeasonYear,
      'next': '1',
    };
    print('[ApiService] Fetching next race for $currentSeasonYear...');
    return await _getRequest(endpoint, queryParams: queryParams);
  }

  // (Fungsi getTeamId tidak dipanggil oleh getHomeData, bisa dibiarkan)
  Future<int?> getTeamId(String teamName) async {
     const endpoint = 'teams';
     final queryParams = { 'name': teamName };
     print('[ApiService] Fetching Team ID for $teamName...');
     final response = await _getRequest(endpoint, queryParams: queryParams);
     if (response is List && response.isNotEmpty && response[0] is Map) {
        final teamId = response[0]['id'];
        if (teamId != null) {
           print('[ApiService] Team ID for $teamName found: $teamId');
           return teamId as int;
        }
     }
     print('[ApiService] Team ID for $teamName NOT found.');
     return null;
  }


  Future<List<dynamic>> getDriverRankings() async {
    const endpoint = 'rankings/drivers';
    final queryParams = {
      'season': currentSeasonYear,
    };
    print('[ApiService] Fetching driver RANKINGS for $currentSeasonYear...');
    return await _getRequest(endpoint, queryParams: queryParams);
  }

  Future<List<dynamic>> getConstructorStandings() async {
    const endpoint = 'rankings/teams';
    final queryParams = {
      'season': currentSeasonYear,
    };
    print('[ApiService] Fetching constructor standings for $currentSeasonYear...');
    return await _getRequest(endpoint, queryParams: queryParams);
  }

   Future<Map<String, dynamic>?> _getLastRaceInfo() async {
     const endpoint = 'races';
     Map<String, String> queryParams = { 'season': currentSeasonYear, 'last': '1' };
     print('[ApiService] Fetching last race info for $currentSeasonYear...');
     
     dynamic response = await _getRequest(endpoint, queryParams: queryParams);
     
     // --- FIX: Cek apakah elemen pertama adalah Map ---
     if (response is List && response.isNotEmpty && response[0] is Map) {
       print('[ApiService] Last race info found for $currentSeasonYear.');
       return Map<String, dynamic>.from(response[0]); // Casting aman
     }

     print('[ApiService] No last race found for $currentSeasonYear, trying last year...');
     final lastYear = (DateTime.now().year - 1).toString();
     queryParams = { 'season': lastYear, 'last': '1' };
     response = await _getRequest(endpoint, queryParams: queryParams);
     
     // --- FIX: Cek apakah elemen pertama adalah Map ---
     if (response is List && response.isNotEmpty && response[0] is Map) {
       print('[ApiService] Last race info found for $lastYear.');
       return Map<String, dynamic>.from(response[0]); // Casting aman
     }

     print('[ApiService] No last race found for last year either.');
     return null;
   }


  Future<List<dynamic>> getRaceResults(String raceId) async {
     const endpoint = 'rankings/races';
     final queryParams = { 'race': raceId };
     print('[ApiService] Fetching race results for Race ID: $raceId');
     return await _getRequest(endpoint, queryParams: queryParams);
  }

  Future<List<dynamic>> getStartingGrid(String raceId) async {
     // --- FIX 3: Hapus underscore dari endpoint ---
     const endpoint = 'rankings/startinggrid';
     final queryParams = { 'race': raceId };
     print('[ApiService] Fetching starting grid for Race ID: $raceId');
     return await _getRequest(endpoint, queryParams: queryParams);
  }

  Future<Map<String, dynamic>> getHomeData() async {
     print("[ApiService] Fetching all home data concurrently...");
     try {
       final Map<String, dynamic>? lastRaceInfo = await _getLastRaceInfo();
       
       String lastRaceName = "N/A";

       if (lastRaceInfo != null) {
          final raceId = lastRaceInfo['id']?.toString();
          lastRaceName = lastRaceInfo['competition']?['name'] ?? 'Balapan Terakhir'; 
          
          if (raceId != null) {
             final results = await Future.wait([
               getConstructorStandings(), // [0]
               getDriverRankings(),       // [1]
               getRaceResults(raceId),    // [2]
               getStartingGrid(raceId),   // [3]
             ]);

             return {
               'constructorStandings': results[0],
               'driverRankings': results[1],
               'lastRaceResults': results[2],
               'lastRaceGrid': results[3],
               'lastRaceName': lastRaceName,
             };

          } else { throw Exception("Last race ID was null."); }
       } else { throw Exception("No last race info found."); }
       
     } catch (e) {
        print("[ApiService] Error in getHomeData: $e");
        // Tambahkan info type cast error jika terdeteksi
        if (e is TypeError) {
           print("[ApiService] TypeCast Error Detail: ${e.toString()} \nStackTrace: ${e.stackTrace}");
           throw Exception('Gagal memuat data Home: Terjadi kesalahan tipe data (TypeCast Error). $e');
        }
        throw Exception('Gagal memuat data Home: $e');
     }
  }

} // Akhir Class ApiService

