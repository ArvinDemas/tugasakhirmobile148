/**
 * File: order_success_screen.dart
 * Deskripsi: Halaman yang ditampilkan setelah pembayaran/pemesanan berhasil.
 */

import 'package:flutter/material.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Background gelap
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Konten di tengah
            children: [
              // Ikon centang besar
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.greenAccent[400], // Warna hijau sukses
                size: 100,
              ),
              const SizedBox(height: 24),
              // Teks Judul
              Text(
                'Pembayaran Selesai!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onBackground, // Putih
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Teks Deskripsi
              Text(
                'Pesanan Anda telah berhasil dibuat dan sedang diproses. Anda dapat melihat detailnya di Riwayat Pesanan.',
                style: TextStyle(
                  color: theme.colorScheme.outline, // Abu-abu
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Tombol Kembali ke Home
              ElevatedButton(
                // Style tombol ungu dari tema
                onPressed: () {
                  // Kembali ke halaman Home ('/home') dan hapus semua halaman di atasnya
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false, // Hapus semua rute sebelumnya
                  );
                },
                child: const Text('Kembali ke Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
