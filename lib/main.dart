/**
 * File: main.dart
 * Deskripsi: Titik masuk utama aplikasi Flutter. Menginisialisasi Hive,
 * format tanggal, mendefinisikan tema aplikasi (Tema Gelap Baru #0C0C25),
 * dan mengatur rute navigasi antar halaman.
 *
 * UPDATE:
 * - Menambahkan Hive.openBox('orders') untuk mengatasi error Box not found.
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import Halaman-halaman
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart'; // Halaman utama (Bottom Nav)
import 'tabs/profile_screen.dart';
import 'tabs/product_detail_screen.dart';
// Import Halaman Checkout
import 'tabs/checkout_screen.dart';
import 'tabs/order_success_screen.dart';
import 'tabs/order_history_screen.dart';
import 'screens/map_picker_screen.dart';
import 'screens/news_detail_screen.dart';
import 'screens/bookmark_screen.dart'; // Import halaman bookmark
import 'screens/feedback_screen.dart'; // Import halaman feedback
import 'services/notification_service.dart'; // Import NotificationService
import 'services/williams_colors.dart';


void main() async {
  // Pastikan binding Flutter siap sebelum inisialisasi plugin
  WidgetsFlutterBinding.ensureInitialized();



  // Inisialisasi Hive
  try {
    await Hive.initFlutter();
    await Hive.openBox('users'); // Box untuk data pengguna
    print("Hive Box 'users' berhasil dibuka!");
    // await Hive.openBox('feedback'); // Dihapus/di-komen jika tidak dipakai
    await Hive.openBox('orders'); // Box untuk riwayat pesanan
    print("Hive Box 'orders' berhasil dibuka!");

  } catch (e) {
    print("FATAL ERROR initializing Hive: $e");
  }

  
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
    print("NotificationService berhasil diinisialisasi!");
  } catch (e) {
    print("Error initializing NotificationService: $e");
  }

  // Inisialisasi format tanggal lokal (Indonesia)
  try {
     await initializeDateFormatting('id_ID', null);
     print("Inisialisasi format tanggal 'id_ID' berhasil.");
  } catch (e) {
     print("Error initializing date formatting 'id_ID': $e");
  }

  // Menjalankan aplikasi
  runApp(const WilliamsApp());
}

class WilliamsApp extends StatelessWidget {
  const WilliamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    

    return MaterialApp(
      title: 'Williams', // Nama aplikasi
      debugShowCheckedModeBanner: false,

      theme: WilliamsColors.getTheme(),

      // --- Rute Navigasi (LENGKAP) ---
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/product-detail': (context) => const ProductDetailScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/order-success': (context) => const OrderSuccessScreen(),
        '/order-history': (context) => const OrderHistoryScreen(),
        '/map-picker': (context) => const MapPickerScreen(),
        '/news-detail': (context) => const NewsDetailScreen(),
        '/bookmark': (context) => const BookmarkScreen(), // Route bookmark
       '/feedback': (context) => const FeedbackScreen(), // Route feedback
      },
    ); // Akhir MaterialApp
  }
}