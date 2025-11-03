/**
 * File: login_screen.dart
 * Deskripsi: Halaman untuk pengguna masuk ke aplikasi menggunakan email dan password.
 * Menggunakan Hive untuk memverifikasi kredensial pengguna.
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Dibutuhkan untuk mengakses Hive Box
import 'package:crypto/crypto.dart' as crypto; // Dibutuhkan untuk hashing password
import 'dart:convert'; // Dibutuhkan untuk utf8.encode

class LoginScreen extends StatefulWidget {
  // Constructor const
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey untuk mengidentifikasi Form dan memvalidasi input
  final _formKey = GlobalKey<FormState>();
  // Controller untuk mengambil teks dari TextField email dan password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State untuk mengontrol visibilitas password
  bool _isPasswordVisible = false;
  // State untuk menampilkan loading indicator saat proses login
  bool _isLoading = false;

  // dispose() dipanggil saat State dihancurkan
  @override
  void dispose() {
    // Pastikan controller di-dispose untuk membebaskan memori
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI UNTUK HASHING PASSWORD ---
  /**
   * Mengubah password String menjadi hash SHA-256.
   * Parameter: password (String)
   * Mengembalikan: String hash dalam format heksadesimal.
   * PENTING: Gunakan algoritma hashing yang sama persis saat registrasi!
   */
  String _hashPassword(String password) {
    // 1. Ubah String password menjadi List<int> (bytes) menggunakan UTF-8 encoding
    final bytes = utf8.encode(password);
    // 2. Lakukan hashing menggunakan SHA-256 dari package crypto
    final digest = crypto.sha256.convert(bytes);
    // 3. Kembalikan representasi String heksadesimal dari hash
    return digest.toString();
  }

  // --- FUNGSI UNTUK PROSES LOGIN ---
  /**
   * Fungsi asynchronous (_loginUser) yang dipanggil saat tombol "Log In" ditekan.
   * Melakukan validasi input, memeriksa kredensial ke Hive, dan navigasi jika berhasil.
   */
  Future<void> _loginUser() async {
    // 1. Validasi form. Jika tidak valid (misal email kosong), hentikan proses.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Set state ke loading (menampilkan indicator & disable tombol)
    if (mounted) { // Cek widget masih ada
      setState(() => _isLoading = true);
    }

    // Ambil email dan password dari controller
    final email = _emailController.text.trim(); // trim() menghapus spasi di awal/akhir
    final password = _passwordController.text;

    print('[LoginScreen] Mencoba login dengan email: $email'); // Debug print

    try {
      // 3. Buka Hive Box 'users' (seharusnya sudah dibuka di main.dart)
      final userBox = Hive.box('users');

      // 4. Cari data pengguna berdasarkan email (yang digunakan sebagai key)
      final userData = userBox.get(email);
      print('[LoginScreen] Data ditemukan di Hive: $userData'); // Debug print

      // 5. Cek apakah data pengguna ditemukan
      if (userData != null && userData is Map) {
         // Data ditemukan, sekarang cek password
         print('[LoginScreen] User ditemukan, membandingkan password...');

         // --- PENTING: ASUMSI FORMAT DATA DI HIVE ---
         // Asumsi hash password disimpan dengan key 'password_hash'. SESUAIKAN JIKA BEDA.
         final storedHash = userData['password_hash'] as String?;

         // Hash password yang dimasukkan pengguna
         final enteredHash = _hashPassword(password);
         print('[LoginScreen] Hash password dimasukkan: $enteredHash'); // Debug print
         print('[LoginScreen] Hash tersimpan di Hive : $storedHash'); // Debug print


         // 6. Bandingkan hash password
         if (storedHash != null && storedHash == enteredHash) {
           // --- LOGIN BERHASIL ---
           print('[LoginScreen] PASSWORD COCOK! Login berhasil.');

           // --- SIMPAN INFO USER AKTIF (Opsional tapi berguna) ---
           // Simpan email user yang berhasil login agar bisa diambil di halaman lain (misal HomeScreen)
           await userBox.put('currentUserEmail', email);
           print('[LoginScreen] Email user aktif disimpan: $email');

           // Tampilkan pesan sukses (opsional)
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login berhasil!'),
                  backgroundColor: Colors.green, // Warna hijau untuk sukses
                ),
              );
              // Tunggu sebentar agar SnackBar terlihat, lalu navigasi
              await Future.delayed(const Duration(milliseconds: 500));
           }

           // 7. Navigasi ke Halaman Utama ('/home')
           // pushReplacementNamed agar tidak bisa kembali ke halaman login
           if (mounted) { // Cek lagi mounted setelah await
              Navigator.pushReplacementNamed(context, '/home');
           }

         } else {
           // --- PASSWORD SALAH ---
           print('[LoginScreen] PASSWORD SALAH!');
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password yang Anda masukkan salah.'),
                  backgroundColor: Colors.orangeAccent, // Warna warning
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
              backgroundColor: Colors.redAccent, // Warna error
            ),
          );
        }
      }
    } catch (e) {
      // Tangkap error saat proses Hive atau hashing
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
      // 8. Hentikan loading, apapun hasilnya (sukses, gagal, error)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI WIDGET BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // Scaffold sebagai kerangka halaman
    return Scaffold(
      // Tidak pakai AppBar bawaan, logo ditempatkan di body
      body: SafeArea( // Menghindari notch/status bar
        // SingleChildScrollView agar halaman bisa di-scroll saat keyboard muncul
        child: SingleChildScrollView(
          // Padding keseluruhan konten halaman
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          // Form widget untuk grouping dan validasi input fields
          child: Form(
            key: _formKey, // Hubungkan dengan GlobalKey
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center, // Pusatkan konten vertikal
              crossAxisAlignment: CrossAxisAlignment.stretch, // Lebarkan children horizontal
              children: [
                // --- BAGIAN LOGO & JUDUL ---
                // TODO: Ganti path 'assets/images/F1_logo.png' dengan path logo Williams PNG Anda
                Image.asset(
                  'assets/images/F1_logo.png', // Path ke logo PNG
                  height: 80, // Sesuaikan tinggi logo jika perlu
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.sports_motorsports, size: 80, color: Colors.grey), // Fallback jika gagal load
                ),
                const SizedBox(height: 16),
                Text(
                  'Williams Racing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground, // Putih
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Masuk ke Akun Williams Anda', // Sub-judul
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), // Abu-abu terang
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40), // Jarak ke form input

                // --- INPUT EMAIL ---
                TextFormField(
                  controller: _emailController, // Hubungkan controller
                  decoration: _buildInputDecoration( // Panggil helper decoration
                    hintText: 'Masukkan email Anda',
                    prefixIcon: Icons.email_outlined, // Ikon email
                  ),
                  keyboardType: TextInputType.emailAddress, // Keyboard khusus email
                  // Validasi input email
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    // Validasi format email sederhana
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Masukkan format email yang valid';
                    }
                    return null; // Return null jika valid
                  },
                ),
                const SizedBox(height: 20), // Jarak antar input field

                // --- INPUT PASSWORD ---
                TextFormField(
                  controller: _passwordController, // Hubungkan controller
                  decoration: _buildInputDecoration( // Panggil helper decoration
                    hintText: 'Masukkan password Anda',
                    prefixIcon: Icons.lock_outline, // Ikon gembok
                    // Tambahkan ikon mata untuk toggle visibilitas password
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Theme.of(context).inputDecorationTheme.suffixIconColor, // Warna ikon dari tema
                      ),
                      onPressed: () {
                        // Toggle state visibilitas password
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible, // Sembunyikan teks jika _isPasswordVisible false
                  // Validasi input password
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    // Opsional: Tambahkan validasi panjang minimal password
                    // if (value.length < 6) {
                    //   return 'Password minimal 6 karakter';
                    // }
                    return null; // Return null jika valid
                  },
                ),
                const SizedBox(height: 12), // Jarak ke Opsi Lanjutan

                // --- OPSI LANJUTAN (REMEMBER ME & FORGOT PASSWORD) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Rata kiri-kanan
                  children: [
                    // Opsi "Remember Me" (sementara non-fungsional)
                    Row(
                      children: [
                         Checkbox(
                           value: false, // TODO: Implement state & logic remember me
                           onChanged: (bool? value) {
                             // TODO: Implement logic remember me
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Fitur "Remember Me" belum diimplementasikan.')),
                             );
                           },
                           // Tema diambil dari checkboxTheme di main.dart
                         ),
                         Text(
                           'Ingat Saya',
                           style: TextStyle(
                             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                             fontSize: 13,
                           ),
                         ),
                      ],
                    ),
                    // Link "Lupa Password?" (sementara non-fungsional)
                    TextButton(
                      onPressed: () {
                        // TODO: Implementasi halaman/logika lupa password
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fitur "Lupa Password" belum diimplementasikan.')),
                        );
                      },
                      child: Text(
                        'Lupa Password?',
                        style: TextStyle(
                          fontSize: 13,
                          // Warna diambil dari textButtonTheme
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30), // Jarak ke Tombol Login

                // --- TOMBOL LOGIN ---
                ElevatedButton(
                  // Style diambil dari elevatedButtonTheme (warna biru muda)
                  // onPressed di-set null jika _isLoading true (tombol disable)
                  onPressed: _isLoading ? null : _loginUser,
                  // Tampilkan loading atau teks "Log In"
                  child: _isLoading
                      ? const SizedBox( // Tampilkan loading indicator kecil
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            // Warna loading di tombol (sesuaikan dengan foregroundColor tombol)
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF012169)),
                          ),
                        )
                      : const Text('Log In'), // Teks tombol
                ),
                const SizedBox(height: 20), // Jarak ke Divider

                // --- DIVIDER "ATAU" ---
                Row(
                  children: [
                    const Expanded(child: Divider(thickness: 0.5)), // Garis kiri
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'ATAU',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider(thickness: 0.5)), // Garis kanan
                  ],
                ),
                const SizedBox(height: 20), // Jarak ke Tombol Sign Up

                // --- TOMBOL KE HALAMAN REGISTRASI ---
                OutlinedButton(
                  // Style diambil dari outlinedButtonTheme
                  onPressed: () {
                    // Navigasi ke halaman registrasi ('/register')
                    // pushNamed menambahkan halaman baru ke stack navigasi
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
  /**
   * Fungsi helper untuk membuat InputDecoration yang konsisten untuk TextField.
   * Parameter:
   * - hintText: Teks placeholder di dalam field.
   * - prefixIcon: Ikon opsional di awal field.
   * - suffixIcon: Widget opsional di akhir field (misal IconButton).
   * Mengembalikan: InputDecoration object.
   */
  InputDecoration _buildInputDecoration({required String hintText, IconData? prefixIcon, Widget? suffixIcon}) {
    // Mengambil tema input dari ThemeData global
    final inputTheme = Theme.of(context).inputDecorationTheme;

    // Membuat InputDecoration
    return InputDecoration(
      hintText: hintText, // Set hint text
      // Set ikon prefix jika ada
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: inputTheme.hintStyle?.color, size: 20) // Gunakan warna hint untuk ikon prefix
          : null,
      // Set widget suffix jika ada
      suffixIcon: suffixIcon,
      // Menggunakan border, fillColor, dll dari tema yang sudah didefinisikan
      // Tidak perlu di-override di sini kecuali ada kebutuhan khusus
    );
  }

} // Akhir Class _LoginScreenState

