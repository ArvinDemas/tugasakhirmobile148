/**
 * File: main_screen.dart
 * Deskripsi: Container utama aplikasi.
 *
 * UPDATE (Final):
 * - Scaffold DI SINI TIDAK MEMILIKI AppBar. AppBar akan ada di
 * dalam halaman tab (seperti HomeScreen).
 * - Scaffold DI SINI MEMILIKI Drawer dan GlobalKey.
 * - Menginisialisasi _pages di initState agar bisa
 * meneruskan fungsi 'onProfilePressed' ke HomeScreen.
 * - Fungsi ini akan memicu _scaffoldKey untuk membuka drawer.
 *
 * UPDATE (AI):
 * - Menambahkan AI Chat sebagai TAB ke-5 di Bottom Nav Bar
 * - Menghapus AI Chat dari Drawer
 */
import 'package:flutter/material.dart';

// Import halaman-halaman untuk setiap tab
import '2_home/home_screen.dart'; // Index 0
import '3_news/news_screen.dart'; // Index 1
import '4_store/store_screen.dart'; // Index 2
import '5_arcade/arcade_screen.dart'; // Index 3
// --- IMPORT BARU UNTUK AI CHAT ---
import '7_ai/ai_chat_screen.dart'; // Index 4

// Import halaman ProfileScreen untuk diakses DARI drawer
import '6_profile/profile_screen.dart'; // Pastikan path ini benar

// --- Import yang Dibutuhkan untuk Drawer ---
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';

import '../../services/notification_service.dart'; // Import NotificationService
// --- (Selesai Import Drawer) ---

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Kunci untuk mengontrol Scaffold (terutama untuk membuka Drawer)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0; // Tab yang sedang aktif (sekarang 0-4)

  // --- DAFTAR HALAMAN (TIDAK LAGI const) ---
  late final List<Widget> _pages;

  // --- LOGIKA & STATE UNTUK DRAWER (Dipindahkan dari ProfileScreen) ---
  final NotificationService _notificationService = NotificationService();
  String? _currentUserEmail;
  String _username = "Pengguna";
  String? _profileImagePath;
  bool _isLoadingDrawer = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadUserProfileForDrawer();

    // --- Inisialisasi _pages di sini ---
    // Kita berikan HomeScreen fungsi untuk membuka drawer
    _pages = <Widget>[
      HomeScreen(
        // INI KUNCINYA: Berikan fungsi 'openDrawer' ke HomeScreen
        onProfilePressed: () {
          // Panggil fungsi untuk memuat ulang data user di drawer
          // sebelum membukanya, agar selalu update
          _loadUserProfileForDrawer();
          _scaffoldKey.currentState?.openDrawer();
        },
      ), // Index 0: Home
      const NewsScreen(), // Index 1: News
      const StoreScreen(), // Index 2: Store
      const ArcadeScreen(), // Index 3: Arcade
      // --- HALAMAN AI DITAMBAHKAN DI SINI ---
      const AiChatScreen(), // Index 4: AI Chat
    ];
  }

  // --- FUNGSI UNTUK MEMUAT DATA PENGGUNA DRAWER ---
  Future<void> _loadUserProfileForDrawer() async {
    // Hanya setState jika sedang loading atau jika data berubah
    if (!_isLoadingDrawer) {
      // Cek data cepat tanpa loading, jika perlu
      try {
        final userBox = Hive.box('users');
        _currentUserEmail = userBox.get('currentUserEmail');
        if (_currentUserEmail != null) {
          final userData = userBox.get(_currentUserEmail) as Map?;
          if (userData != null) {
            final newUsername = userData['username'] ?? "Pengguna";
            final newImagePath = userData['profileImagePath'] as String?;
            // Hanya update jika ada perubahan
            if (newUsername != _username || newImagePath != _profileImagePath) {
              if (mounted) {
                setState(() {
                  _username = newUsername;
                  _profileImagePath = newImagePath;
                });
              }
            }
          }
        }
      } catch (e) {
        print("[MainScreen] Quick load profile error: $e");
      }
      return; // Jangan tampilkan loading spinner jika sudah dimuat
    }

    if (mounted) setState(() => _isLoadingDrawer = true);
    try {
      final userBox = Hive.box('users');
      _currentUserEmail = userBox.get('currentUserEmail');
      if (_currentUserEmail != null) {
        final userData = userBox.get(_currentUserEmail) as Map?;
        if (userData != null) {
          if (mounted) {
            setState(() {
              _username = userData['username'] ?? "Pengguna";
              _profileImagePath = userData['profileImagePath'] as String?;
            });
          }
        }
      }
    } catch (e) {
      print("[MainScreen] Error loading profile for drawer: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDrawer = false);
    }
  }

  // --- UPDATE FUNGSI LOGOUT (DARI SNIPPET) ---
  Future<void> _logout() async {
    // Tampilkan dialog konfirmasi
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmLogout != true) return;

    try {
      final userBox = Hive.box('users');

      // Hapus email user aktif
      await userBox.delete('currentUserEmail');

      // PENTING: Hapus status Remember Me
      await userBox.put('rememberMeEnabled', false);
      await userBox.delete('rememberedEmail');

      print("[MainScreen] Logout berhasil, Remember Me dihapus");

      if (mounted) {
        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil keluar dari akun'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigasi ke login dan hapus semua history
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print("[MainScreen] Error logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- FUNGSI BARU (DARI SNIPPET): HAPUS INGAT SAYA ---
  Future<void> _clearRememberMe() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus "Ingat Saya"'),
        content: const Text(
          'Anda harus login kembali di lain waktu. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userBox = Hive.box('users');

      // Hapus status Remember Me (tetap login di session ini)
      await userBox.put('rememberMeEnabled', false);
      await userBox.delete('rememberedEmail');

      print("[MainScreen] Remember Me berhasil dihapus");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur "Ingat Saya" telah dinonaktifkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("[MainScreen] Error clearing Remember Me: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- FUNGSI HELPER BARU (DARI SNIPPET): CEK STATUS REMEMBER ME ---
  Future<bool> _checkRememberMeStatus() async {
    try {
      final userBox = Hive.box('users');
      return userBox.get('rememberMeEnabled', defaultValue: false) as bool;
    } catch (e) {
      return false;
    }
  }

  // --- FUNGSI NOTIFIKASI (TETAP SAMA) ---
  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
    } catch (e) {
      print('[MainScreen] Error initializing notifications: $e');
    }
  }

  Future<void> _testInstantNotification() async {
    await _notificationService.showInstantNotification(
      id: 999,
      title: '🏁 Test Notifikasi',
      body: 'Ini adalah notifikasi test dari Williams Racing App!',
      payload: 'test',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Notifikasi instant dikirim!'),
          backgroundColor: Colors.green));
    }
  }

  Future<void> _testDelayedNotification() async {
    await _notificationService.scheduleStorePromotion();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notifikasi promosi store dijadwalkan dalam 5 detik!'),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _showNotificationTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Notifikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih jenis notifikasi untuk ditest:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _testInstantNotification();
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Notifikasi Instant'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _testDelayedNotification();
              },
              icon: const Icon(Icons.schedule),
              label: const Text('Notifikasi Delay 5 Detik'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
  // --- (Selesai Logika Drawer) ---

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool profileImageExists =
        _profileImagePath != null && File(_profileImagePath!).existsSync();

    return Scaffold(
      // Tambahkan key di sini
      key: _scaffoldKey,

      // --- TIDAK ADA APPBAR DI SINI ---

      body: IndexedStack(
        index: _selectedIndex,
        children: _pages, // Gunakan _pages yang sudah di-init (sekarang 5)
      ),

      // --- DRAWER (TETAP DI SINI) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _isLoadingDrawer
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: profileImageExists
                              ? FileImage(File(_profileImagePath!))
                                  as ImageProvider
                              : null,
                          child: !profileImageExists
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currentUserEmail ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
            // Menu: Edit Profile
            ListTile(
              leading:
                  Icon(Icons.person_outline, color: theme.colorScheme.primary),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                Navigator.push(
                  context,
                  // Arahkan ke profile_screen.dart (yang TIDAK punya drawer)
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                )
                    // PENTING: Muat ulang data user saat kembali dari edit profile
                    .then((_) => _loadUserProfileForDrawer());
              },
            ),
            // Menu: Riwayat Pesanan
            ListTile(
              leading: Icon(Icons.receipt_long_outlined,
                  color: theme.colorScheme.primary),
              title: const Text('Riwayat Pesanan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/order-history');
              },
            ),
            // Menu: Bookmark
            ListTile(
              leading: Icon(Icons.bookmark_outline,
                  color: theme.colorScheme.primary),
              title: const Text('Produk Favorit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/bookmark');
              },
            ),
            const Divider(),
            // Menu: Test Notifikasi
            ListTile(
              leading: Icon(Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary),
              title: const Text('Test Notifikasi'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationTestDialog();
              },
            ),
            // Menu: Kesan & Pesan
            ListTile(
              leading: Icon(Icons.feedback_outlined,
                  color: theme.colorScheme.primary),
              title: const Text('Kesan & Pesan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/feedback');
              },
            ),

            // --- MENU AI CHATBOT (DIHAPUS DARI SINI) ---

            // --- TAMBAHAN BARU DARI SNIPPET ---
            const Divider(),
            FutureBuilder<bool>(
              future: _checkRememberMeStatus(),
              builder: (context, snapshot) {
                final rememberMeEnabled = snapshot.data ?? false;

                if (!rememberMeEnabled) {
                  return const SizedBox.shrink(); // Sembunyikan jika tidak aktif
                }

                return ListTile(
                  leading: Icon(
                    Icons.phonelink_erase_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Hapus "Ingat Saya"'),
                  subtitle: const Text(
                    'Perlu login ulang nanti',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _clearRememberMe();
                  },
                );
              },
            ),
            // --- AKHIR TAMBAHAN BARU ---

            const Divider(), // Ini adalah Divider yang sudah ada sebelumnya

            // Menu: Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Keluar Akun',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _logout(); // Memanggil fungsi _logout baru yang sudah di-update
              },
            ),
          ],
        ),
      ),
      // --- (Selesai Drawer) ---

      // --- BOTTOM NAVIGATION BAR (SEKARANG 5 ITEM) ---
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
          // --- ITEM BARU UNTUK AI CHAT ---
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Properti tambahan untuk memastikan style bottom nav bar Anda
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.outline,
        backgroundColor: theme.colorScheme.surface,
      ),
    );
  }
}