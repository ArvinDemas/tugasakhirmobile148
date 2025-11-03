/**
 * File: williams_colors.dart
 * Deskripsi: Konfigurasi warna Williams Racing 2002 Livery
 * 
 * PANDUAN MENGUBAH WARNA (UNTUK PRESENTASI):
 * 1. PRIMARY COLOR: Warna utama (tombol, aksen) - ubah nilai primaryColor
 * 2. BACKGROUND: Warna latar belakang utama - ubah backgroundColor
 * 3. SURFACE: Warna kartu/card - ubah surfaceColor
 * 4. ACCENT: Warna aksen sekunder - ubah accentColor
 * 
 * Tinggal ubah nilai HEX di bawah, save, dan hot reload!
 */

import 'package:flutter/material.dart';

class WilliamsColors {
  // ==========================================
  // WARNA WILLIAMS RACING 2002 LIVERY
  // ==========================================
  
  // WARNA UTAMA (BMW Williams Blue - biru khas Williams 2002)
  static const Color primaryColor = Color(0xFF0055B8); // Biru Williams BMW
  
  // WARNA AKSEN (White/Silver dari livery 2002)
  static const Color accentColor = Color(0xFFE8E8E8); // Abu-abu terang/Silver
  
  // WARNA BACKGROUND (Dark Blue - untuk kontras elegan)
  static const Color backgroundColor = Color(0xFF0A1128); // Biru sangat gelap
  
  // WARNA SURFACE (Card, Bottom Nav - biru gelap dengan sedikit warmth)
  static const Color surfaceColor = Color(0xFF1A2744); // Biru gelap hangat
  
  // WARNA TEKS
  static const Color textPrimaryColor = Color(0xFFFFFFFF); // Putih
  static const Color textSecondaryColor = Color(0xFFB0B8C8); // Abu-abu terang
  
  // WARNA TAMBAHAN (dari livery 2002)
  static const Color goldAccent = Color(0xFFFFD700); // Emas (untuk highlight)
  static const Color darkAccent = Color(0xFF001F3F); // Navy tua
  
  // ==========================================
  // WARNA FUNGSIONAL (STATUS)
  // ==========================================
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  
  // ==========================================
  // METODE HELPER - BUAT THEME
  // ==========================================
  
  /// Membuat ColorScheme untuk MaterialApp
  static ColorScheme getColorScheme() {
    return const ColorScheme.dark(
      // Warna Utama
      primary: primaryColor,
      secondary: accentColor,
      
      // Background & Surface
      surface: surfaceColor,
      surfaceContainerHighest: surfaceColor,
      
      // Text Colors
      onPrimary: textPrimaryColor,
      onSecondary: backgroundColor,
      onSurface: textPrimaryColor,
      
      // Status Colors
      error: errorColor,
      onError: textPrimaryColor,
      
      // Outline & Variants
      outline: textSecondaryColor,
      surfaceContainerHigh: Color(0xFF0F1B2E),
    );
  }
  
  /// Membuat ThemeData lengkap
  static ThemeData getTheme() {
    final colorScheme = getColorScheme();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Poppins',
      colorScheme: colorScheme,
      
      // ==========================================
      // APP BAR THEME
      // ==========================================
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(color: textPrimaryColor),
      ),
      
      // ==========================================
      // INPUT DECORATION (TEXTFIELD)
      // ==========================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor.withOpacity(0.5),
        hintStyle: const TextStyle(color: textSecondaryColor, fontSize: 14),
        labelStyle: const TextStyle(
          color: textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        
        // Border styling
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: textSecondaryColor.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: textSecondaryColor.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: errorColor, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: errorColor, width: 2.0),
        ),
        suffixIconColor: textSecondaryColor,
      ),
      
      // ==========================================
      // ELEVATED BUTTON (TOMBOL UTAMA)
      // ==========================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimaryColor,
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // ==========================================
      // OUTLINED BUTTON
      // ==========================================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      
      // ==========================================
      // TEXT BUTTON
      // ==========================================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      
      // ==========================================
      // BOTTOM NAVIGATION BAR
      // ==========================================
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondaryColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      
      // ==========================================
      // CARD THEME
      // ==========================================
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
      
      // ==========================================
      // LIST TILE THEME
      // ==========================================
      listTileTheme: const ListTileThemeData(
        iconColor: primaryColor,
        textColor: textPrimaryColor,
        dense: true,
      ),
      
      // ==========================================
      // CHECKBOX THEME
      // ==========================================
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(backgroundColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(color: textSecondaryColor, width: 1.5),
      ),
      
      // ==========================================
      // FLOATING ACTION BUTTON
      // ==========================================
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textPrimaryColor,
        elevation: 4,
      ),
      
      // ==========================================
      // DIVIDER THEME
      // ==========================================
      dividerTheme: DividerThemeData(
        color: textSecondaryColor.withOpacity(0.2),
        thickness: 1,
      ),
    );
  }
  
  // ==========================================
  // GRADIENT HELPERS (UNTUK EFEK VISUAL)
  // ==========================================
  
  /// Gradient untuk header/card special
  static LinearGradient getPrimaryGradient() {
    return const LinearGradient(
      colors: [primaryColor, Color(0xFF003A8C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  
  /// Gradient untuk background subtle
  static LinearGradient getBackgroundGradient() {
    return LinearGradient(
      colors: [
        backgroundColor,
        backgroundColor.withOpacity(0.8),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }
}

// ==========================================
// CARA MENGUBAH WARNA SAAT PRESENTASI:
// ==========================================
// 1. Buka file ini (williams_colors.dart)
// 2. Scroll ke atas, cari bagian "WARNA WILLIAMS RACING 2002 LIVERY"
// 3. Ubah nilai Color(0xFFxxxxxx) sesuai kebutuhan:
//    - primaryColor: Warna tombol dan aksen utama
//    - backgroundColor: Warna background gelap
//    - surfaceColor: Warna card/kotak
//    - accentColor: Warna aksen sekunder
// 4. Save file (Ctrl+S / Cmd+S)
// 5. Hot Reload (tekan 'r' di terminal atau tombol hot reload di IDE)
// 6. Selesai! Semua warna langsung berubah
//
// CONTOH PALET WARNA ALTERNATIF:
// - Merah Ferrari: primaryColor = Color(0xFFDC0000)
// - Hijau Mercedes: primaryColor = Color(0xFF00D2BE)
// - Oranye McLaren: primaryColor = Color(0xFFFF8700)
// - Ungu Modern: primaryColor = Color(0xFF8C8AFA)