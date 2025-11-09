import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = "";
  
  // MODEL YANG BENAR sesuai hasil curl Anda
  static const String _model = 'gemini-2.5-flash';
  
  // Endpoint /v1/ (bukan /v1beta/)
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models';

  static const String _systemPrompt = '''
Kamu adalah AI Assistant untuk aplikasi Williams Racing, tim Formula 1.
Nama kamu adalah "Williams AI".

PERSONALITY:
- Ramah, antusias, dan informatif
- Ahli tentang Williams Racing, Formula 1, dan motorsport
- Gunakan emoji yang relevan (🏎️, 🏁, ⚡, 💙)
- Jawab dalam bahasa Indonesia (kecuali user pakai English)
- Singkat tapi informatif (max 3-4 kalimat)

PENGETAHUAN TENTANG WILLIAMS:
- Williams Racing adalah tim Formula 1 yang berbasis di Grove, UK
- Pembalap 2025: Alex Albon dan Franco Colapinto
- Warna tim: Biru dan Putih
- Didirikan oleh Sir Frank Williams
- Sejarah: 9 Konstruktor Championship, 7 Driver Championship

FUNGSI UTAMA:
1. Menjawab pertanyaan tentang Williams Racing dan F1
2. Membantu user menemukan merchandise di Store
3. Memberikan info race schedule dan results
4. Customer service untuk app

GUIDELINES:
- Jika tidak tahu, akui dengan jujur
- Jangan buat info palsu tentang hasil race atau data teknis
- Arahkan ke fitur app yang relevan (Store, News, Arcade)
- Selalu sopan dan membantu
''';

  Future<String> chat({
    required String message,
    List<Map<String, String>>? chatHistory,
  }) async {
    try {
      print('[GeminiService] 🚀 Starting chat...');
      print('[GeminiService] Model: $_model');
      print('[GeminiService] Message: $message');

      List<Map<String, dynamic>> contents = [];

      // Inject system prompt di chat pertama
      if (chatHistory == null || chatHistory.isEmpty) {
        contents.add({
          'parts': [{'text': _systemPrompt}],
          'role': 'user',
        });
        contents.add({
          'parts': [{'text': 'Mengerti! Saya siap membantu sebagai Williams AI! 🏎️💙'}],
          'role': 'model',
        });
      }

      // Add chat history
      if (chatHistory != null) {
        for (var chat in chatHistory) {
          contents.add({
            'parts': [{'text': chat['message']}],
            'role': chat['role'],
          });
        }
      }

      // Add current message
      contents.add({
        'parts': [{'text': message}],
        'role': 'user',
      });

      // Build payload
      final payload = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1500,
          'topP': 0.9,
          'topK': 40,
        },
      };

      // Full URL
      final url = '$_baseUrl/$_model:generateContent?key=$_apiKey';
      print('[GeminiService] Calling: ${url.replaceAll(_apiKey, '***KEY***')}');

      // Make request
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      print('[GeminiService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract text dari response
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content']?['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
          print('[GeminiService] ✅ SUCCESS!');
          print('[GeminiService] Response preview: ${text.substring(0, text.length > 500 ? 500 : text.length)}...');
          
          return text;
        }

        // Handle safety filter
        if (data.containsKey('promptFeedback')) {
          final blockReason = data['promptFeedback']['blockReason'];
          print('[GeminiService] ⚠️ Blocked: $blockReason');
          return 'Maaf, pertanyaan tidak bisa dijawab karena filter keamanan. 🚫 Coba tanya hal lain!';
        }

        print('[GeminiService] ⚠️ Unexpected response: $data');
        throw Exception('Format response tidak valid');

      } else {
        // Error handling
        print('[GeminiService] ❌ Error response: ${response.body}');
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error']?['message'] ?? 'Unknown error';
        
        throw Exception('API Error: $errorMsg');
      }

    } catch (e) {
      print('[GeminiService] ❌ Exception caught: $e');

      if (e.toString().contains('SocketException')) {
        throw Exception('Tidak ada koneksi internet. Cek WiFi/data Anda.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout. Server terlalu lama merespons.');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('Response tidak valid dari server.');
      } else {
        rethrow;
      }
    }
  }

  static List<String> getQuickPrompts() {
    return [
      '🏎️ Siapa pembalap Williams 2025?',
      '📅 Kapan race berikutnya?',
      '🏆 Sejarah Williams Racing',
      '🛍️ Rekomendasikan merchandise',
      '🎮 Info tentang app ini',
    ];
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Selamat pagi';
    } else if (hour < 18) {
      greeting = 'Selamat siang';
    } else {
      greeting = 'Selamat malam';
    }

    return '$greeting! 👋\n\nSaya Williams AI, asisten virtual Anda untuk semua hal tentang Williams Racing! 🏎️💙\n\nAda yang bisa saya bantu?';
  }
}
