/**
 * File: news_screen.dart
 * Deskripsi: Halaman tab "News" yang menampilkan daftar artikel berita.
 * Menggunakan data statis (mock data) karena API-Sports tidak menyediakannya.
 * Card berita bisa diklik untuk membuka halaman detail.
 */

import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {

  // --- DATA BERITA STATIS (MOCK DATA) ---
  // Ini adalah data pengganti API berita.
  // TODO: Ganti path gambar dengan asset yang valid di 'assets/images/'
  final List<Map<String, dynamic>> _mockNewsArticles = [
    {
      "id": 1,
      "title": "Albon Optimis dengan Upgrade Baru Williams di GP Miami",
      "source": "Autosport",
      "date": "30 Oktober 2025",
      "imagePath": "assets/images/news_albon.png", // Ganti dengan asset Anda
      
      "content": "Alex Albon merasa optimis bahwa paket upgrade terbaru yang dibawa Williams Racing ke Grand Prix Miami akhir pekan ini akan memberikan peningkatan performa yang signifikan. Tim asal Grove tersebut berfokus pada perbaikan downforce di tikungan kecepatan rendah..." // Tambahkan teks lebih panjang jika perlu
    },
    {
      "id": 2,
      "title": "Sargeant Berjuang Keras Amankan Kursi untuk Musim Depan",
      "source": "PlanetF1",
      "date": "29 Oktober 2025",
      "imagePath": "assets/images/news_sargeant.png", // Ganti dengan asset Anda
      "content": "Logan Sargeant mengakui bahwa tekanannya meningkat untuk membuktikan kemampuannya dan mengamankan kursinya di Williams untuk musim depan. Pembalap asal Amerika Serikat itu menunjukkan beberapa kemajuan tetapi masih tertinggal dari rekan setimnya..."
    },
    {
      "id": 3,
      "title": "Williams Targetkan Poin Ganda di Balapan Berikutnya",
      "source": "Motorsport.com",
      "date": "28 Oktober 2025",
      "imagePath": "assets/images/news_team.png", // Ganti dengan asset Anda
      "content": "Setelah nyaris meraih poin di balapan terakhir, Team Principal Williams Racing, James Vowles, menetapkan target ambisius untuk meraih poin ganda di Grand Prix mendatang. 'Mobil kami memiliki kecepatan, kami hanya perlu eksekusi yang sempurna,' ujarnya..."
    },
     {
      "id": 4,
      "title": "Analisis Teknis: Mengapa Sasis Baru Williams Penting?",
      "source": "The Race",
      "date": "27 Oktober 2025",
      "imagePath": "assets/images/news_factory.png", // Ganti dengan asset Anda
      "content": "Williams akhirnya memperkenalkan sasis cadangan ketiga mereka, sebuah langkah krusial yang sempat tertunda. Analis teknis kami membedah mengapa sasis baru ini bukan hanya sekadar cadangan, tetapi juga membawa perbaikan bobot yang vital..."
    },
  ];

  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita Williams'), // Judul halaman
        centerTitle: true,
      ),
      // Gunakan ListView.builder untuk menampilkan daftar artikel
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0), // Padding di sekitar list
        itemCount: _mockNewsArticles.length, // Jumlah artikel
        itemBuilder: (context, index) {
          // Ambil data satu artikel
          final article = _mockNewsArticles[index];
          // Bangun card untuk artikel
          return _buildNewsCard(context, theme, article);
        },
      ),
    );
  }

  // --- WIDGET HELPER UNTUK CARD BERITA ---
  /**
   * Membangun satu Card untuk artikel berita.
   * Card ini dibungkus InkWell agar bisa diklik.
   */
  Widget _buildNewsCard(BuildContext context, ThemeData theme, Map<String, dynamic> article) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Jarak antar card
      child: Card(
        // Card (background dari tema)
        clipBehavior: Clip.antiAlias, // Potong gambar sesuai radius card
        child: InkWell( // Membuat card bisa diklik
          onTap: () {
            // Aksi saat card diklik: Navigasi ke halaman detail
            print("[NewsScreen] Artikel '${article['title']}' ditekan.");
            Navigator.pushNamed(
              context,
              '/news-detail', // Rute ke halaman detail
              arguments: article, // Kirim data artikel (Map)
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Gambar Artikel ---
              Image.asset(
                article['imagePath'], // Path dari data statis
                height: 180, // Tinggi gambar
                width: double.infinity, // Lebar penuh
                fit: BoxFit.cover, // Penuhi area gambar
                // Error builder jika asset gambar tidak ditemukan
                errorBuilder: (context, error, stackTrace) {
                   print("Error loading news image: ${article['imagePath']}, $error");
                   return Container(
                     height: 180,
                     color: theme.colorScheme.surfaceVariant,
                     child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)),
                   );
                },
              ),
              
              // --- Teks Info (Judul, Sumber, Tanggal) ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul Artikel
                    Text(
                      article['title'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600, // Semi-bold
                        color: theme.colorScheme.onSurface, // Putih
                      ),
                      maxLines: 2, // Maksimal 2 baris
                      overflow: TextOverflow.ellipsis, // Tampilkan '...'
                    ),
                    const SizedBox(height: 12),
                    // Sumber dan Tanggal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sumber Berita
                        Text(
                          article['source'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary, // Warna ungu (aksen)
                          ),
                        ),
                        // Tanggal Berita
                        Text(
                          article['date'],
                           style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline, // Warna abu-abu
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

