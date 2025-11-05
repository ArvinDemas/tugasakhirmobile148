/**
 * File: register_screen.dart
 * Deskripsi: Halaman untuk pengguna baru mendaftar akun.
 * Menyimpan data pengguna (username/email, hash password) ke Hive.
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Dibutuhkan untuk mengakses Hive Box
import 'package:crypto/crypto.dart' as crypto; // Dibutuhkan untuk hashing password
import 'dart:convert'; // Dibutuhkan untuk utf8.encode

class RegisterScreen extends StatefulWidget {
  // Constructor const
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // GlobalKey untuk form
  final _formKey = GlobalKey<FormState>();
  // Controller untuk input fields
  final TextEditingController _usernameController = TextEditingController(); // Tambah controller username
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State visibilitas password
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  // State loading
  bool _isLoading = false;

  // Dispose controllers
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- FUNGSI UNTUK HASHING PASSWORD ---
  /**
   * Mengubah password String menjadi hash SHA-256.
   * Sama persis dengan yang di halaman login.
   */
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  // --- FUNGSI UNTUK PROSES REGISTRASI ---
  /**
   * Fungsi asynchronous (_registerUser) yang dipanggil saat tombol "Sign Up" ditekan.
   * Melakukan validasi input, memeriksa email unik, menyimpan data ke Hive, dan navigasi.
   */
  Future<void> _registerUser() async {
    // 1. Validasi form
    if (!_formKey.currentState!.validate()) {
      return; // Hentikan jika validasi gagal
    }

    // 2. Set state ke loading
    if (mounted) {
      setState(() => _isLoading = true);
    }

    // Ambil data dari controllers
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    // Password konfirmasi sudah divalidasi di validator

    print('[RegisterScreen] Mencoba registrasi dengan username: $username, email: $email'); // Debug print

    try {
      // 3. Buka Hive Box 'users'
      final userBox = Hive.box('users');

      // --- PENTING: CEK EMAIL UNIK ---
      // Periksa apakah email sudah terdaftar sebelumnya
      if (userBox.containsKey(email)) {
        print('[RegisterScreen] ERROR: Email $email sudah terdaftar.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email ini sudah digunakan oleh akun lain.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        // Hentikan proses jika email sudah ada
        // Set loading ke false di finally
        return;
      }

      // 4. Hash password
      final hashedPassword = _hashPassword(password);
      print('[RegisterScreen] Password di-hash: $hashedPassword'); // Debug print

      // 5. Simpan data pengguna ke Hive Box
      // Key: email pengguna
      // Value: Map berisi username dan hash password
      // --- PENTING: PASTIKAN FORMAT INI KONSISTEN DENGAN LOGIN ---
      await userBox.put(email, {
        'username': username, // Simpan juga username
        'password_hash': hashedPassword,
        // Bisa tambahkan data lain jika perlu, misal tanggal registrasi:
        // 'registered_at': DateTime.now().toIso8601String(),
      });
      print('[RegisterScreen] Data user berhasil disimpan ke Hive untuk email: $email');

      // --- SIMPAN INFO USER AKTIF (setelah registrasi langsung login) ---
      await userBox.put('currentUserEmail', email);
      print('[RegisterScreen] Email user aktif disimpan setelah registrasi: $email');


      // --- REGISTRASI BERHASIL ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Anda akan dialihkan...'),
            backgroundColor: Colors.green,
          ),
        );
        // Tunggu sebentar lalu navigasi
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // 6. Navigasi ke Halaman Utama ('/home') setelah registrasi berhasil
      // pushReplacementNamed agar tidak bisa kembali ke halaman registrasi/login
      if (mounted) { // Cek lagi mounted setelah await
        Navigator.pushReplacementNamed(context, '/home');
      }

    } catch (e) {
      // Tangkap error saat proses Hive atau hashing
      print('[RegisterScreen] Terjadi error saat registrasi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat registrasi: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // 7. Hentikan loading, apapun hasilnya
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI WIDGET BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar dengan tombol kembali
      appBar: AppBar(
        // Background color diambil dari tema (williamsNavyBlue)
        // elevation: 0, // Diambil dari tema
        // leading: Tombol back otomatis muncul karena halaman ini di-push (dari login)
        title: const Text('Buat Akun Baru'), // Judul AppBar
        centerTitle: true, // Judul di tengah
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0), // Padding disesuaikan
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- BAGIAN LOGO & JUDUL (Opsional, bisa dihapus jika ada AppBar) ---
                // Image.asset(
                //   'assets/images/F1_logo.png', // Sesuaikan path logo
                //   height: 60,
                //   errorBuilder: (context, error, stackTrace) =>
                //       const Icon(Icons.sports_motorsports, size: 60, color: Colors.grey),
                // ),
                // const SizedBox(height: 16),
                // Text(
                //   'Daftar Paddock Pass',
                //   textAlign: TextAlign.center,
                //   style: TextStyle(
                //     color: Theme.of(context).colorScheme.onBackground,
                //     fontSize: 24,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
                // const SizedBox(height: 30),

                // --- INPUT USERNAME ---
                TextFormField(
                  controller: _usernameController,
                  decoration: _buildInputDecoration(
                    hintText: 'Masukkan username',
                    prefixIcon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    if (value.length < 3) {
                       return 'Username minimal 3 karakter';
                    }
                    // Opsional: Cek keunikan username jika diperlukan (lebih kompleks)
                    return null;
                  },
                ),
                const SizedBox(height: 20),

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
                    hintText: 'Buat password Anda',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Theme.of(context).inputDecorationTheme.suffixIconColor,
                      ),
                      onPressed: () {
                        setState(() { _isPasswordVisible = !_isPasswordVisible; });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 6) { // Validasi panjang minimal
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // --- INPUT KONFIRMASI PASSWORD ---
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: _buildInputDecoration(
                    hintText: 'Konfirmasi password Anda',
                    prefixIcon: Icons.lock_outline,
                     suffixIcon: IconButton( // Ikon mata juga di konfirmasi password
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                         color: Theme.of(context).inputDecorationTheme.suffixIconColor,
                      ),
                      onPressed: () {
                        setState(() { _isConfirmPasswordVisible = !_isConfirmPasswordVisible; });
                      },
                    ),
                  ),
                  obscureText: !_isConfirmPasswordVisible, // Gunakan state terpisah
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password tidak boleh kosong';
                    }
                    // Cek apakah sama dengan password di field sebelumnya
                    if (value != _passwordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40), // Jarak ke tombol Sign Up

                // --- TOMBOL SIGN UP ---
                ElevatedButton(
                  // Style diambil dari tema (biru muda)
                  onPressed: _isLoading ? null : _registerUser, // Panggil fungsi register
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF012169)), // Warna navy
                          ),
                        )
                      : const Text('Daftar Akun'), // Teks tombol
                ),
                const SizedBox(height: 20), // Jarak ke link login

                // --- LINK KE HALAMAN LOGIN ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Pusatkan teks
                  children: [
                    Text(
                      'Sudah punya akun? ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // Abu-abu terang
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Kembali ke halaman sebelumnya (Login)
                        Navigator.pop(context);
                      },
                      // Padding dihilangkan agar rapat dengan teks sebelumnya
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text('Masuk di sini'), // Warna link diambil dari tema
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER UNTUK MEMBUAT INPUT DECORATION (Sama seperti di LoginScreen) ---
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

} // Akhir Class _RegisterScreenState

