/**
 * File: main_screen.dart
 * Deskripsi: Container utama aplikasi setelah login, menampilkan Bottom Navigation Bar
 * dan halaman yang sesuai dengan tab yang dipilih.
 */
import 'package:flutter/material.dart';

// Import halaman-halaman untuk setiap tab BARU
import '../tabs/home_screen.dart';       // Halaman Home (sudah ada)
import '../tabs/news_screen.dart.dart';       // Halaman Berita (baru)
import '../tabs/store_screen.dart';      // Halaman Toko (baru)
import '../tabs/arcade_screen.dart';   // Halaman Jadwal (baru)
// Komentar sisa import halaman lama dihapus untuk kebersihan
// import 'tabs/feedback_screen.dart';
// import 'tabs/converter_screen.dart';


/**
 * File: main_screen.dart
 * Deskripsi: Container utama aplikasi setelah login, menampilkan Bottom Navigation Bar
 * dan halaman yang sesuai dengan tab yang dipilih.
 *
 * UPDATE:
 * - Menggunakan IndexedStack di body untuk menjaga state (keep-alive)
 * setiap tab. Ini akan MENCEGAH LOKASI DAN GAME SHAKE ME-RESET
 * saat berpindah tab.
 */
class MainScreen extends StatefulWidget {
  // Constructor const
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Variabel state untuk menyimpan index tab yang sedang aktif
  int _selectedIndex = 0; // Mulai dari tab pertama (Home)

  // --- DAFTAR HALAMAN SESUAI TAB BARU ---
  // Kita buat daftarnya di sini agar instance-nya tetap sama
  final List<Widget> _pages = const <Widget>[
    HomeScreen(),      // Index 0: Home
    NewsScreen(),      // Index 1: News
    StoreScreen(),     // Index 2: Store
    ArcadeScreen(),    // Index 3: Arcade
  ];

  // Fungsi yang dipanggil ketika salah satu item navigasi di-tap
  void _onItemTapped(int index) {
    // Update state _selectedIndex dengan index baru
    setState(() {
      _selectedIndex = index;
    });
  }

  // UI Widget Build Method
  @override
  Widget build(BuildContext context) {
    // Scaffold sebagai kerangka dasar
    return Scaffold(
      // --- FIX: Gunakan IndexedStack ---
      // IndexedStack menjaga semua child widget tetap ada di memori (keep-alive)
      // tapi hanya menampilkan widget pada '_selectedIndex'.
      // Ini akan menyimpan state scroll, game, dan alamat di setiap tab.
      body: IndexedStack(
        index: _selectedIndex, // Tampilkan widget sesuai index
        children: _pages,    // Gunakan list widget yang sudah dibuat
      ),
      // --- (End of Fix) ---

      // --- BOTTOM NAVIGATION BAR BARU ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad_outlined),
            activeIcon: Icon(Icons.gamepad),
            label: 'Arcade',
          ),
        ],
        currentIndex: _selectedIndex, // Item yang aktif
        onTap: _onItemTapped, // Fungsi saat di-tap
        // Style (warna, dll) diambil dari tema di main.dart
      ),
    );
  }
}

