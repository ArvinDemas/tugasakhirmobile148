/**
 * File: profile_screen.dart
 * Deskripsi: Halaman profile dengan Side Navigation Drawer & Toggle Biometrik
 * * UPDATE:
 * - Disesuaikan untuk menggunakan BiometricService (Singleton) yang baru.
 * - Menggunakan BiometricService() (factory instance) untuk memanggil
 * metode non-statis (isDeviceSupported, isBiometricEnrolled, getBiometricTypeName).
 * - Tetap menggunakan BiometricService (static) untuk memanggil
 * metode statis (isEnabled, setEnabled, authenticate).
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../services/biometric_service.dart'; // IMPORT BIOMETRIC SERVICE

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final NotificationService _notificationService = NotificationService();

  // Buat instance service (karena service baru Anda pakai singleton)
  final BiometricService _biometricService = BiometricService();

  String? _currentUserEmail;
  String _username = "Pengguna";
  String? _dobString;
  String? _profileImagePath;
  bool _isLoading = true;
  
  // STATE BIOMETRIK
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometrik';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadUserProfile();
    _checkBiometric(); // Panggil cek biometrik
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // Inisialisasi Notifikasi
  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
      print('[ProfileScreen] Notification service initialized');
    } catch (e) {
      print('[ProfileScreen] Error initializing notifications: $e');
    }
  }

  // Load User Profile
  Future<void> _loadUserProfile() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final userBox = Hive.box('users');
      _currentUserEmail = userBox.get('currentUserEmail'); 
      if (_currentUserEmail != null) {
        final userData = userBox.get(_currentUserEmail) as Map?;
        if (userData != null) {
          if (mounted) {
            setState(() {
              _username = userData['username'] ?? "Pengguna";
              _dobString = userData['dateOfBirth'] as String?;
              _profileImagePath = userData['profileImagePath'] as String?;
            });
          }
        } else {
          if (mounted) setState(() { _username = "Error User"; });
        }
      } else {
          if (mounted) setState(() { _username = "Not Logged In"; });
      }
    } catch (e) {
      print("[ProfileScreen] Error loading profile: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal memuat profil: $e'), backgroundColor: Colors.redAccent)
         );
          setState(() { _username = "Load Error"; });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // CEK BIOMETRIK (FIXED: Menggunakan instance _biometricService dan metode statis)
  Future<void> _checkBiometric() async {
    try {
      // Panggil metode INSTANCE menggunakan _biometricService
      final available = await _biometricService.isDeviceSupported();
      final enrolled = await _biometricService.isBiometricEnrolled();
      final typeName = await _biometricService.getBiometricTypeName();
      
      // Panggil metode STATIS menggunakan BiometricService
      final enabled = await BiometricService.isEnabled();
      
      print('[ProfileScreen] Biometric check:');
      print('  Available: $available');
      print('  Enrolled: $enrolled');
      print('  Enabled: $enabled');
      print('  Type: $typeName');
      
      if (mounted) {
        setState(() {
          _biometricAvailable = available && enrolled;
          _biometricEnabled = enabled;
          _biometricType = typeName;
        });
      }
    } catch (e) {
      print('[ProfileScreen] Error checking biometric: $e');
    }
  }

  // TOGGLE BIOMETRIK (FIXED: Menggunakan metode statis)
  Future<void> _toggleBiometric(bool value) async {
    if (!_biometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrik tidak tersedia atau belum terdaftar di perangkat ini'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    
    if (value) {
      // AKTIFKAN: Test autentikasi dulu (Panggil metode STATIS)
      final authenticated = await BiometricService.authenticate(
        reason: 'Verifikasi untuk mengaktifkan $_biometricType',
        allowSkip: false, // Harus berhasil untuk aktifkan
      );
      
      if (authenticated) {
        // Panggil metode STATIS
        await BiometricService.setEnabled(true);
        // Panggil _checkBiometric untuk refresh state
        await _checkBiometric(); 
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType berhasil diaktifkan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autentikasi gagal, biometrik tidak diaktifkan'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      // NONAKTIFKAN (Panggil metode STATIS)
      await BiometricService.setEnabled(false);
      // Panggil _checkBiometric untuk refresh state
      await _checkBiometric();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_biometricType dinonaktifkan'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Update User Data
  Future<void> _updateUserData(String key, dynamic value) async {
    if (_currentUserEmail == null) return;
    try {
      final userBox = Hive.box('users');
      final Map<dynamic, dynamic> userData = Map.from(userBox.get(_currentUserEmail) ?? {});
      userData[key] = value;
      await userBox.put(_currentUserEmail!, userData);
      _loadUserProfile();
    } catch (e) {
      print("[ProfileScreen] Error updating user data: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.redAccent)
         );
      }
    }
  }

  // Dialog Edit Username
  void _showEditUsernameDialog() {
    _usernameController.text = _username;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(hintText: "Masukkan username baru"),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Username tidak boleh kosong';
              if (value.length < 3) return 'Username minimal 3 karakter';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final newUsername = _usernameController.text.trim();
                Navigator.pop(context);
                _updateUserData('username', newUsername);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Date Picker
  Future<void> _selectDateOfBirth() async {
    final DateTime firstDate = DateTime.now().subtract(const Duration(days: 365 * 100));
    final DateTime lastDate = DateTime.now();
    final DateTime initialDate = _dobString != null ? (DateTime.tryParse(_dobString!) ?? lastDate) : lastDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate != null) {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      _updateUserData('dateOfBirth', formattedDate);
    }
  }

  // Image Picker
  Future<void> _pickImage() async {
     final ImagePicker picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile?>(
       context: context,
       builder: (context) => SafeArea(
         child: Wrap(
           children: <Widget>[
             ListTile(
                 leading: const Icon(Icons.photo_library),
                 title: const Text('Galeri'),
                 onTap: () async { Navigator.pop(context, await picker.pickImage(source: ImageSource.gallery)); }),
             ListTile(
               leading: const Icon(Icons.photo_camera),
               title: const Text('Kamera'),
               onTap: () async { Navigator.pop(context, await picker.pickImage(source: ImageSource.camera)); },
             ),
           ],
         ),
       ),
    );
    if (image != null) {
      try {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileExtension = path.extension(image.path);
        final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
        final String newPath = path.join(appDir.path, fileName);
        final File newImage = await File(image.path).copy(newPath);
        await _updateUserData('profileImagePath', newImage.path);
      } catch (e) {
        print("[ProfileScreen] Error saving image: $e");
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal menyimpan gambar: $e'), backgroundColor: Colors.redAccent)
         );
      }
    }
  }

  // Logout
   Future<void> _logout() async {
      try {
         final userBox = Hive.box('users');
         await userBox.delete('currentUserEmail');
         if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
         }
      } catch (e) {
         print("[ProfileScreen] Error logout: $e");
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal logout: $e'), backgroundColor: Colors.redAccent)
            );
         }
      }
   }

  // Test Notifikasi
  Future<void> _testInstantNotification() async {
    await _notificationService.showInstantNotification(
      id: 999,
      title: '🏁 Test Notifikasi',
      body: 'Ini adalah notifikasi test dari Williams Racing App!',
      payload: 'test',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifikasi instant dikirim!'), backgroundColor: Colors.green)
      );
    }
  }

  Future<void> _testDelayedNotification() async {
    await _notificationService.scheduleStorePromotion();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi promosi store dijadwalkan dalam 5 detik!'),
          backgroundColor: Colors.green,
        )
      );
    }
  }

  // UI BUILD METHOD (dengan Drawer)
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    bool profileImageExists = _profileImagePath != null && File(_profileImagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      
      // DRAWER MENU
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImageExists
                        ? FileImage(File(_profileImagePath!)) as ImageProvider
                        : null,
                    child: !profileImageExists
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
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
            
            ListTile(
              leading: Icon(Icons.person_outline, color: theme.colorScheme.primary),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
              title: const Text('Riwayat Pesanan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/order-history');
              },
            ),
            
            ListTile(
              leading: Icon(Icons.bookmark_outline, color: theme.colorScheme.primary),
              title: const Text('Produk Favorit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/bookmark');
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
              title: const Text('Test Notifikasi'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationTestDialog();
              },
            ),
            
            ListTile(
              leading: Icon(Icons.feedback_outlined, color: theme.colorScheme.primary),
              title: const Text('Kesan & Pesan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/feedback');
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Keluar Akun', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
      
      // BODY: Konten Profile Utama
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Foto Profil
            GestureDetector(
              onTap: _pickImage,
              child: Stack( 
                 alignment: Alignment.bottomRight,
                 children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.surfaceVariant, // Menggunakan surfaceVariant
                      backgroundImage: profileImageExists
                          ? FileImage(File(_profileImagePath!)) as ImageProvider
                          : null,
                      child: !profileImageExists
                          ? const Icon(Icons.person, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Container(
                       padding: const EdgeInsets.all(4),
                       decoration: BoxDecoration(
                         color: theme.primaryColor,
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(Icons.edit, size: 18, color: Colors.white),
                    ),
                 ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Username
            _buildInfoTile(
              icon: Icons.person_outline,
              label: 'Username',
              value: _username,
              onTap: _showEditUsernameDialog,
              showEditIcon: true,
            ),

            // Info Tanggal Lahir
            _buildInfoTile(
              icon: Icons.cake_outlined,
              label: 'Tanggal Lahir',
              value: _dobString != null
                   ? (DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.parse(_dobString!)))
                   : 'Belum diatur',
              onTap: _selectDateOfBirth,
              showEditIcon: true,
            ),

            // Info Email
             _buildInfoTile(
               icon: Icons.email_outlined,
               label: 'Email',
               value: _currentUserEmail ?? 'Tidak tersedia',
             ),
             
            const SizedBox(height: 24),
            
            // CARD BIOMETRIK (BARU - HANYA MUNCUL JIKA AVAILABLE)
            if (_biometricAvailable)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.fingerprint, // Ikon generik
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  title: Text(
                    _biometricType, // Menampilkan 'Sidik Jari' atau 'Face ID'
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    _biometricEnabled
                        ? 'Aktif - Login dengan $_biometricType'
                        : 'Nonaktif - Login dengan password saja',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Switch(
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric, // Panggil fungsi toggle
                    activeColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            
            // Hint untuk drawer
            Card(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5), // Menggunakan surfaceVariant
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Buka menu di pojok kiri atas untuk fitur lainnya',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog Test Notifikasi
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

  // Helper Widget Info Tile
  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool showEditIcon = false,
  }) {
    return Card(
       margin: const EdgeInsets.only(bottom: 12),
       child: InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(16.0),
         child: ListTile(
           leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
           title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 12)),
           subtitle: Text(
             value,
             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
             maxLines: 1,
             overflow: TextOverflow.ellipsis,
           ),
           trailing: onTap != null
              ? Icon(
                  showEditIcon ? Icons.edit_outlined : Icons.chevron_right,
                  color: Theme.of(context).colorScheme.outline,
                  size: 22,
                )
              : null,
         ),
       ),
    );
  }
}