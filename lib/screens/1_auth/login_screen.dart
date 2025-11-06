/**
 * File: login_screen.dart
 * Lokasi: lib/screens/login_screen.dart
 * Deskripsi: Halaman login dengan biometrik (FIXED)
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';
import '../../services/biometric_service.dart'; // FIX: Path yang benar

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _loginUser() async {
    // 1. Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // --- CEK BIOMETRIK ---
    print('[LoginScreen] ===== MULAI CEK BIOMETRIK =====');
    
    try {
      final biometricEnabled = await BiometricService.isEnabled();
      print('[LoginScreen] Biometrik enabled: $biometricEnabled');
      
      if (biometricEnabled) {
        print('[LoginScreen] Biometrik AKTIF, meminta autentikasi...');
        
        // Tampilkan dialog loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final bool authenticated = await BiometricService.authenticate(
          reason: 'Verifikasi untuk login ke Williams Racing',
          allowSkip: true,
        );
        
        // Tutup dialog loading
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        
        print('[LoginScreen] Hasil autentikasi: $authenticated');
        
        if (!authenticated) {
          print('[LoginScreen] Autentikasi GAGAL');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Autentikasi biometrik gagal. Coba lagi atau gunakan password.'),
                backgroundColor: Colors.orangeAccent,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        
        print('[LoginScreen] Autentikasi BERHASIL');
      } else {
        print('[LoginScreen] Biometrik TIDAK AKTIF, skip autentikasi');
      }
    } catch (e) {
      print('[LoginScreen] ERROR saat cek biometrik: $e');
      // Lanjut ke login password jika error
    }
    
    print('[LoginScreen] ===== LANJUT KE LOGIN PASSWORD =====');
    // --- AKHIR CEK BIOMETRIK ---

    // 2. Set loading
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    print('[LoginScreen] Mencoba login dengan email: $email');

    try {
      final userBox = Hive.box('users');
      final userData = userBox.get(email);
      print('[LoginScreen] Data ditemukan di Hive: $userData');

      if (userData != null && userData is Map) {
        print('[LoginScreen] User ditemukan, membandingkan password...');

        final storedHash = userData['password_hash'] as String?;
        final enteredHash = _hashPassword(password);

        if (storedHash != null && storedHash == enteredHash) {
          print('[LoginScreen] PASSWORD COCOK! Login berhasil.');

          await userBox.put('currentUserEmail', email);
          print('[LoginScreen] Email user aktif disimpan: $email');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login berhasil!'),
                backgroundColor: Colors.green,
              ),
            );
            await Future.delayed(const Duration(milliseconds: 500));
          }

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }

        } else {
          print('[LoginScreen] PASSWORD SALAH!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password yang Anda masukkan salah.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      } else {
        print('[LoginScreen] User TIDAK ditemukan dengan email: $email');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Akun dengan email $email tidak ditemukan.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      print('[LoginScreen] Terjadi error saat login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Image.asset(
                  'assets/images/F1_logo.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sports_motorsports,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Williams Racing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Masuk ke Akun Williams Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // Input Email
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan email Anda',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.colorScheme.outline,
                      size: 20,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Masukkan format email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Input Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan password Anda',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.outline,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: theme.inputDecorationTheme.suffixIconColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (bool? value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Fitur "Remember Me" belum diimplementasikan.'),
                              ),
                            );
                          },
                        ),
                        Text(
                          'Ingat Saya',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur "Lupa Password" belum diimplementasikan.'),
                          ),
                        );
                      },
                      child: Text(
                        'Lupa Password?',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Tombol Login
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Log In'),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tombol Register
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text('Belum Punya Akun? Daftar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}