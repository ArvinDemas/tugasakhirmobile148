/**
 * File: profile_screen.dart
 * Deskripsi: Halaman untuk "Edit Profile".
 * * UPDATE:
 * - Ini BUKAN lagi halaman tab. Ini adalah halaman yang di-push (dibuka)
 * dari Drawer di main_screen.dart.
 * - Menghapus semua logika Drawer, AppBar kustom, dan notifikasi
 * (sudah pindah ke main_screen.dart).
 * - Hanya berisi logika untuk mengedit profil (nama, tgl lahir, foto).
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
// Import NotificationService DIHAPUS, karena sudah pindah ke MainScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  String? _currentUserEmail;
  String _username = "Pengguna";
  String? _dobString;
  String? _profileImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // --- Load User Profile (Tetap ada, diperlukan untuk halaman ini) ---
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

  // --- Update User Data (Tetap ada) ---
  Future<void> _updateUserData(String key, dynamic value) async {
    if (_currentUserEmail == null) return;
    try {
      final userBox = Hive.box('users');
      final Map<dynamic, dynamic> userData = Map.from(userBox.get(_currentUserEmail) ?? {});
      userData[key] = value;
      await userBox.put(_currentUserEmail!, userData);
      _loadUserProfile(); // Muat ulang data untuk tampilan
    } catch (e) {
      print("[ProfileScreen] Error updating user data: $e");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.redAccent)
         );
      }
    }
  }

  // --- Dialog Edit Username (Tetap ada) ---
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

  // --- Date Picker (Tetap ada) ---
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

  // --- Image Picker (Tetap ada) ---
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

  // --- UI BUILD METHOD (TANPA DRAWER) ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    bool profileImageExists = _profileImagePath != null && File(_profileImagePath!).existsSync();

    // Halaman ini sekarang punya Scaffold sendiri (karena di-push)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      
      // --- BODY: Konten Profile Utama (Tetap sama) ---
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
                      backgroundColor: theme.colorScheme.surfaceVariant,
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
          ],
        ),
      ),
    );
  }

  // --- Helper Widget Info Tile (Tetap sama) ---
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