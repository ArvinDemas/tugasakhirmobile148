/**
 * File: splash_screen.dart
 * Deskripsi: Halaman yang muncul pertama kali saat aplikasi dibuka (loading screen).
 * Menampilkan logo aplikasi dan nama aplikasi "Williams" selama beberapa detik
 * sebelum berpindah ke halaman berikutnya.
 * 
 * UPDATE:
 * - Cek status Remember Me sebelum memutuskan navigasi
 * - Jika Remember Me aktif, langsung ke Home
 * - Jika tidak, ke Onboarding/Login
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // Fungsi untuk memulai timer dan cek Remember Me
  void _startTimer() {
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      
      try {
        final userBox = Hive.box('users');
        
        // --- CEK REMEMBER ME ---
        final rememberMeEnabled = userBox.get('rememberMeEnabled', defaultValue: false) as bool;
        final rememberedEmail = userBox.get('rememberedEmail') as String?;
        
        if (rememberMeEnabled && rememberedEmail != null) {
          // User sebelumnya centang "Ingat Saya"
          print('[SplashScreen] Remember Me aktif, auto-login ke: $rememberedEmail');
          
          // Set currentUserEmail
          await userBox.put('currentUserEmail', rememberedEmail);
          
          // Langsung ke Home
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // Tidak ada Remember Me, cek apakah sudah pernah login
          final hasLoggedInBefore = userBox.get('hasLoggedInBefore', defaultValue: false) as bool;
          
          if (hasLoggedInBefore) {
            // Langsung ke Login (skip onboarding)
            print('[SplashScreen] User pernah login sebelumnya, ke Login');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          } else {
            // Pertama kali buka app, tampilkan Onboarding
            print('[SplashScreen] First time user, ke Onboarding');
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/onboarding');
            }
          }
        }
      } catch (e) {
        print('[SplashScreen] Error checking Remember Me: $e');
        // Jika error, default ke onboarding
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- LOGO APLIKASI (PNG) ---
              Image.asset(
                'assets/images/F1_logo.png',
                width: 150,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading logo PNG: $error");
                  return const Icon(Icons.image_not_supported, size: 100, color: Colors.grey);
                },
              ),
              const SizedBox(height: 24),

              // --- NAMA APLIKASI ---
              Text(
                'Williams',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),

              // --- LOADING INDICATOR ---
              CircularProgressIndicator(
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