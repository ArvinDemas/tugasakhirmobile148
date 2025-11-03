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
    // --- PALET WARNA BARU (BERDASARKAN REFERENSI) ---
    const primaryBackgroundColor = Color(0xFF0C0C25); // Biru sangat gelap
    const primaryAccentColor = Color(0xFF8C8AFA);    // Ungu Aksen
    const cardSurfaceColor = Color(0xFF25253B);      // Warna Card / Bottom Nav
    const primaryTextColor = Colors.white;          // Teks Putih
    const secondaryTextColor = Color(0xFF929292);    // Teks Abu-abu
    const buttonTextColor = Colors.white;           // Teks di atas tombol ungu

    return MaterialApp(
      title: 'Williams', // Nama aplikasi
      debugShowCheckedModeBanner: false,

      // --- PENGATURAN TEMA APLIKASI ---
      theme: ThemeData(
        useMaterial3: true, // Tetap gunakan Material 3
        brightness: Brightness.dark,
        scaffoldBackgroundColor: primaryBackgroundColor,
        fontFamily: 'Poppins',

        // ColorScheme (Pusat warna di Material 3)
        colorScheme: const ColorScheme.dark(
          primary: primaryAccentColor,
          secondary: primaryAccentColor,
          background: primaryBackgroundColor,
          surface: cardSurfaceColor,
          onPrimary: buttonTextColor,
          onSecondary: buttonTextColor,
          onBackground: primaryTextColor,
          onSurface: primaryTextColor,
          error: Colors.redAccent,
          onError: Colors.white,
          surfaceVariant: Color(0xAA25253B),
          outline: secondaryTextColor,
        ),

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBackgroundColor,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          iconTheme: IconThemeData(color: primaryTextColor),
        ),

        // Input Decoration Theme (TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardSurfaceColor.withOpacity(0.5),
          hintStyle: const TextStyle(color: secondaryTextColor, fontSize: 14),
          labelStyle: const TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w500),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.3), width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.3), width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryAccentColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.redAccent.shade100, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.redAccent.shade100, width: 2.0),
          ),
          suffixIconColor: secondaryTextColor,
        ),

        // ElevatedButton Theme (Tombol Utama)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAccentColor,
            foregroundColor: buttonTextColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              letterSpacing: -0.64,
            ),
          ),
        ),

        // OutlinedButton Theme
        outlinedButtonTheme: OutlinedButtonThemeData(
           style: OutlinedButton.styleFrom(
             foregroundColor: primaryAccentColor,
             side: const BorderSide(color: primaryAccentColor, width: 1.5),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
                letterSpacing: -0.64,
              ),
           )
        ),

        // TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
             foregroundColor: primaryAccentColor,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
          )
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: cardSurfaceColor,
          selectedItemColor: primaryAccentColor,
          unselectedItemColor: secondaryTextColor,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 12),
        ),

        // Card Theme
        cardTheme: CardThemeData( // Menggunakan CardThemeData
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 16),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
           // Warna otomatis dari colorScheme.surface
        ),

         // ListTile Theme
         listTileTheme: const ListTileThemeData(
            iconColor: primaryAccentColor,
            textColor: primaryTextColor,
            dense: true,
         ),

        // --- FIX BAGIAN CheckboxTheme ---
        checkboxTheme: CheckboxThemeData(
          // fillColor (warna kotak saat dicentang) tetap pakai WidgetStateProperty
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryAccentColor; // Ungu saat dicentang
            }
            return Colors.transparent; // Transparan saat tidak
          }),
          // checkColor (warna tanda centang) tetap pakai WidgetStateProperty
          checkColor: WidgetStateProperty.all(primaryBackgroundColor), // Biru gelap (agar kontras)
          
          // shape (bentuk kotak)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),

          // --- FIX: Menggunakan BorderSide langsung untuk 'side' ---
          // Ini untuk mengatasi error 'WidgetStateProperty' vs 'BorderSide?'
          side: const BorderSide(color: secondaryTextColor, width: 1.5),
        ),

      ), // Akhir ThemeData

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
      },
    ); // Akhir MaterialApp
  }
}