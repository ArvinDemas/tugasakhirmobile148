/**
 * File: splash_screen.dart
 * Deskripsi: Halaman yang muncul pertama kali saat aplikasi dibuka (loading screen).
 * Menampilkan logo aplikasi dan nama aplikasi "Williams" selama beberapa detik
 * sebelum berpindah ke halaman onboarding. Disesuaikan dengan tema baru.
 */

import 'dart:async'; // Dibutuhkan untuk Timer
import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // Jika pakai SVG

class SplashScreen extends StatefulWidget {
  // Constructor const
  const SplashScreen({super.key});

  @override
  // Membuat state untuk StatefulWidget
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // initState() dipanggil sekali saat State pertama kali dibuat
  @override
  void initState() {
    super.initState();
    // Memulai timer saat halaman splash muncul
    _startTimer();
  }

  // Fungsi untuk memulai timer
  void _startTimer() {
    // Membuat Timer yang akan berjalan selama 3 detik
    Timer(const Duration(seconds: 3), () {
      // Setelah 3 detik, cek apakah widget masih ada di tree
      if (mounted) {
        // Pindah ke halaman onboarding ('/onboarding')
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  // build() dipanggil untuk merender UI halaman
  @override
  Widget build(BuildContext context) {
    // Scaffold adalah kerangka dasar halaman
    return Scaffold(
      // Mengambil warna background utama dari tema baru (#0C0C25)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // SafeArea memastikan konten tidak tertutup oleh status bar atau notch
      body: SafeArea(
        // Center menempatkan child-nya (Column) di tengah layar
        child: Center(
          // Column untuk menata logo dan teks secara vertikal
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Tengah vertikal
            crossAxisAlignment: CrossAxisAlignment.center, // Tengah horizontal
            children: [
              // --- LOGO APLIKASI (PNG) ---
              // TODO: Ganti 'assets/images/F1_logo.png' dengan path logo Williams PNG Anda
              Image.asset(
                'assets/images/F1_logo.png', // Path ke file logo PNG
                width: 150, // Sesuaikan lebar logo
                // Error handler jika gambar tidak ditemukan
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading logo PNG: $error");
                  // Tampilkan placeholder jika gagal
                  return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                },
              ),
              const SizedBox(height: 24), // Jarak

              // --- NAMA APLIKASI BARU ---
              Text(
                'Williams', // Ganti nama aplikasi di sini
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Ambil warna teks dari colorScheme (onBackground = putih)
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16), // Jarak

              // --- LOADING INDICATOR ---
              CircularProgressIndicator(
                // Ambil warna aksen dari colorScheme (primary = ungu #8C8AFA)
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                strokeWidth: 3.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

