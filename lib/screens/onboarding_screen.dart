/**
 * File: onboarding_screen.dart
 * Deskripsi: Halaman perkenalan aplikasi yang muncul setelah splash screen.
 * Menampilkan gambar background, teks sambutan, dan tombol untuk menuju halaman login.
 */

import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  // Constructor const
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // initState() dipanggil saat state dibuat
  @override
  void initState() {
    super.initState();
    // Tidak ada inisialisasi video lagi
  }

  // dispose() dipanggil saat state dihancurkan
  @override
  void dispose() {
    // Tidak ada controller video yang perlu di-dispose
    super.dispose();
  }

  // Fungsi build untuk merender UI
  @override
  Widget build(BuildContext context) {
    // Scaffold sebagai kerangka halaman
    return Scaffold(
      // Tidak perlu AppBar di halaman ini
      body: Stack( // Gunakan Stack untuk menumpuk background dan konten
        fit: StackFit.expand, // Membuat Stack mengisi seluruh layar
        children: [
          // --- Layer 1: Gambar Background ---
          // TODO: Ganti 'assets/images/onboarding_bg.png' dengan path gambar Anda
          Image.asset(
            'assets/images/onboarding_bg.png', // Path ke gambar background
            fit: BoxFit.cover, // Gambar mengisi layar (mungkin terpotong)
            // Error handling jika gambar gagal dimuat
            errorBuilder: (context, error, stackTrace) {
              print("Error loading onboarding background image: $error");
              // Tampilkan warna background tema jika gambar gagal
              return Container(color: Theme.of(context).scaffoldBackgroundColor);
            },
          ),

          // --- Layer 2: Overlay Gelap (Agar teks lebih mudah dibaca) ---
          Container(
            // Gunakan gradasi dari agak gelap ke lebih gelap (sesuaikan dengan tema)
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  // Warna Navy Blue tema dengan transparansi berbeda
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4), // Lebih transparan di atas
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8), // Lebih pekat di bawah
                ],
                begin: Alignment.topCenter, // Mulai dari atas
                end: Alignment.bottomCenter, // Berakhir di bawah
              ),
            ),
          ),

          // --- Layer 3: Konten (Teks dan Tombol) ---
          Positioned( // Gunakan Positioned untuk menempatkan konten di bagian bawah
            bottom: 50, // Jarak dari bawah layar
            left: 20, // Jarak dari kiri layar
            right: 20, // Jarak dari kanan layar
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ukuran column sesuai konten
              crossAxisAlignment: CrossAxisAlignment.center, // Konten rata tengah horizontal
              children: [
                // Teks Judul Sambutan
                Text(
                  'Selamat Datang di Williams Racing App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // Ambil warna teks dari colorScheme (onBackground = putih)
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 28, // Ukuran font judul
                    fontWeight: FontWeight.w600, // Semi-Bold
                    fontFamily: 'Poppins', // Pastikan font konsisten
                  ),
                ),
                const SizedBox(height: 16), // Jarak antara judul dan deskripsi

                // Teks Deskripsi Singkat
                Text(
                  // TODO: Ganti dengan deskripsi aplikasi yang fokus pada Williams
                  'Aplikasi pendamping F1 Anda, didedikasikan untuk Williams Racing. Dapatkan info terbaru, statistik, dan lainnya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // Ambil warna teks sekunder dari colorScheme (onSurface/grey)
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // Putih agak transparan
                    fontSize: 15, // Ukuran font deskripsi
                    fontFamily: 'Poppins',
                    height: 1.5, // Jarak antar baris
                  ),
                ),
                const SizedBox(height: 40), // Jarak antara deskripsi dan tombol

                // Tombol "Mulai Sekarang" (Get Started)
                SizedBox( // Bungkus ElevatedButton dengan SizedBox agar bisa atur lebar
                  width: double.infinity, // Lebar tombol penuh (dikurangi padding Positioned)
                  child: ElevatedButton(
                    // style diambil dari elevatedButtonTheme di main.dart (background biru muda)
                    onPressed: () {
                      // Fungsi saat tombol ditekan: Pindah ke halaman login
                      // pushReplacementNamed agar tidak bisa kembali ke onboarding
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Mulai Sekarang'), // Teks tombol
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

