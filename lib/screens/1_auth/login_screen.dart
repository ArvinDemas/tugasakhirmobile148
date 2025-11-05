/**
 * File: login_screen.dart
 * Deskripsi: Halaman untuk pengguna masuk ke aplikasi menggunakan email dan password.
 * Menggunakan Hive untuk memverifikasi kredensial pengguna.
 * 
 * UPDATE:
 * - Fitur "Remember Me" sudah diaktifkan
 * - Auto-login jika user sebelumnya centang "Remember Me"
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';

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
  // --- TAMBAHKAN STATE UNTUK REMEMBER ME ---
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // --- CEK AUTO-LOGIN SAAT HALAMAN DIBUKA ---
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI BARU: CEK AUTO-LOGIN ---
  /**
   * Cek apakah user sebelumnya centang "Remember Me".
   * Jika ya, langsung navigasi ke home tanpa perlu login lagi.
   */
  Future<void> _checkAutoLogin() async {
    try {
      final userBox = Hive.box('users');
      
      // Cek apakah ada data "rememberMe" yang true
      final rememberMeEnabled = userBox.get('rememberMeEnabled', defaultValue: false) as bool;
      
      if (rememberMeEnabled) {
        // Ambil email yang tersimpan
        final savedEmail = userBox.get('rememberedEmail') as String?;
        
        if (savedEmail != null) {
          print('[LoginScreen] Remember Me aktif untuk: $savedEmail');
          
          // Set email aktif
          await userBox.put('currentUserEmail', savedEmail);
          
          // Navigasi langsung ke home
          if (mounted) {
            // Delay sedikit agar tidak terlalu cepat (UX lebih baik)
            await Future.delayed(const Duration(milliseconds: 500));
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      }
      
      // Jika tidak ada remember me, isi email terakhir (jika ada)
      final lastEmail = userBox.get('lastLoginEmail') as String?;
      if (lastEmail != null && mounted) {
        setState(() {
          _emailController.text = lastEmail;
        });
      }
      
    } catch (e) {
      print('[LoginScreen] Error checking auto-login: $e');
    }
  }

  // --- FUNGSI UNTUK HASHING PASSWORD ---
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  // --- FUNGSI UNTUK PROSES LOGIN (UPDATE) ---
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        print('[LoginScreen] Hash password dimasukkan: $enteredHash');
        print('[LoginScreen] Hash tersimpan di Hive : $storedHash');

        if (storedHash != null && storedHash == enteredHash) {
          // --- LOGIN BERHASIL ---
          print('[LoginScreen] PASSWORD COCOK! Login berhasil.');

          // Simpan email user aktif
          await userBox.put('currentUserEmail', email);
          print('[LoginScreen] Email user aktif disimpan: $email');
          
          // --- PROSES REMEMBER ME ---
          if (_rememberMe) {
            // Simpan status remember me
            await userBox.put('rememberMeEnabled', true);
            await userBox.put('rememberedEmail', email);
            print('[LoginScreen] Remember Me diaktifkan untuk: $email');
          } else {
            // Hapus remember me jika tidak dicentang
            await userBox.put('rememberMeEnabled', false);
            await userBox.delete('rememberedEmail');
            print('[LoginScreen] Remember Me dinonaktifkan');
          }
          
          // Simpan email terakhir login (untuk auto-fill)
          await userBox.put('lastLoginEmail', email);

          // Tampilkan pesan sukses
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Login berhasil!'),
                backgroundColor: Colors.green,
              ),
            );
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // Navigasi ke Halaman Utama
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }

        } else {
          // --- PASSWORD SALAH ---
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
        // --- USER TIDAK DITEMUKAN ---
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

  // --- UI WIDGET BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- BAGIAN LOGO & JUDUL ---
                Image.asset(
                  'assets/images/F1_logo.png',
                  height: 80,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.sports_motorsports, size: 80, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Text(
                  'Williams Racing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk ke Akun Williams Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // --- INPUT EMAIL ---
                TextFormField(
                  controller: _emailController,
                  decoration: _buildInputDecoration(
                    hintText: 'Masukkan email Anda',
                    prefixIcon: Icons.email_outlined,
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

                // --- INPUT PASSWORD ---
                TextFormField(
                  controller: _passwordController,
                  decoration: _buildInputDecoration(
                    hintText: 'Masukkan password Anda',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Theme.of(context).inputDecorationTheme.suffixIconColor,
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

                // --- OPSI LANJUTAN (REMEMBER ME & FORGOT PASSWORD) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- REMEMBER ME (SUDAH AKTIF) ---
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                            print('[LoginScreen] Remember Me: $_rememberMe');
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _rememberMe = !_rememberMe;
                            });
                          },
                          child: Text(
                            'Ingat Saya',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // --- LUPA PASSWORD ---
                    TextButton(
                      onPressed: () {
                        // TODO: Implementasi halaman/logika lupa password
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
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // --- TOMBOL LOGIN ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF012169)),
                          ),
                        )
                      : const Text('Log In'),
                ),
                const SizedBox(height: 20),

                // --- DIVIDER "ATAU" ---
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 0.5)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'ATAU',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider(thickness: 0.5)),
                  ],
                ),
                const SizedBox(height: 20),

                // --- TOMBOL KE HALAMAN REGISTRASI ---
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

  // --- HELPER UNTUK MEMBUAT INPUT DECORATION ---
  InputDecoration _buildInputDecoration({required String hintText, IconData? prefixIcon, Widget? suffixIcon}) {
    final inputTheme = Theme.of(context).inputDecorationTheme;
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: inputTheme.hintStyle?.color, size: 20)
          : null,
      suffixIcon: suffixIcon,
    );
  }
}