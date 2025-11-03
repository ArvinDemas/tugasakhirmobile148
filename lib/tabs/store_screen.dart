/**
 * File: store_screen.dart
 * Deskripsi: Halaman tab "Store" yang berisi:
 * 1. Header Lokasi (Manual/Otomatis/Peta)
 * 2. Gamifikasi "Pecah Telur" (Shake sensor)
 * 3. Daftar Produk (statis) dengan konversi mata uang (ExchangeRate API)
 *
 * UPDATE:
 * - Menambahkan opsi "Pilih dari Peta" yang membuka MapPickerScreen.
 * - Memanggil _saveAddressToHive setiap kali alamat diubah (dari GPS/Manual/Peta).
 * - Memuat alamat dari Hive saat initState (dijaga oleh IndexedStack).
 * - Perbaikan error (shake, random, localeIdentifier, http import).
 * - MENAMBAHKAN FUNGSI SEARCH BAR (SESUAI INSTRUKSI)
 */

import 'dart:async'; // Untuk StreamSubscription (Shake)
import 'dart:math'; // Untuk Random (Referral Code)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import paket-paket baru
import 'package:shake/shake.dart'; // Untuk deteksi goyangan
import 'package:geolocator/geolocator.dart'; // Untuk mendapatkan GPS
import 'package:geocoding/geocoding.dart'; // Untuk mengubah GPS ke alamat
import 'package:hive_flutter/hive_flutter.dart'; // Impor Hive
import 'package:latlong2/latlong.dart'; // Untuk menerima data dari MapPicker

// Import service API
import '../../services/exchange_rate_service.dart';
// Import halaman detail produk (untuk class arguments)
import 'product_detail_screen.dart'; 
// (Tidak perlu import MapPickerScreen, kita pakai navigasi nama rute)

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
  
}

// Variabel search yang ada di file asli (baris 29-30) dihapus dari sini
// dan dipindahkan ke dalam _StoreScreenState sesuai Instruksi 1.

class _StoreScreenState extends State<StoreScreen> {
  // --- STATE UNTUK LOKASI ---
  // --- PESAN DEFAULT UNTUK VALIDASI ---
  static const String _defaultAddressMessage = "Tekan ikon untuk mengatur lokasi";
  String _currentAddress = _defaultAddressMessage; // Teks lokasi default
  bool _isFetchingLocation = false; // Status loading lokasi
  // Controller & Key untuk form alamat manual
  final _manualAddressController = TextEditingController();
  final _manualAddressFormKey = GlobalKey<FormState>();

  // --- STATE UNTUK GAME SHAKE ---
  ShakeDetector? _shakeDetector;
  int _shakeCount = 0;
  final int _shakesToBreak = 10;
  bool _eggBroken = false;
  String _referralCode = "";
  final Random _random = Random(); // Instance Random

  // --- STATE UNTUK STORE & API ---
  final ExchangeRateService _exchangeService = ExchangeRateService();
  Future<Map<String, dynamic>>? _ratesFuture;
  String _selectedCurrency = 'IDR';
  final List<String> _targetCurrencies = ['IDR', 'USD', 'EUR', 'AUD'];

  // --- INSTRUKSI 1: Tambahkan state untuk search ---
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  // --- DATA PRODUK STATIS ---
  final List<Map<String, dynamic>> _products = [
    { "id": 1, "name": "Williams Racing 2025 Team Polo", "imagePath": "assets/images/product_polo.png", "priceGBP": 65.00 },
    { "id": 2, "name": "Williams Racing 2025 Team Cap", "imagePath": "assets/images/product_cap.png", "priceGBP": 35.00 },
    { "id": 3, "name": "Alex Albon Driver T-Shirt", "imagePath": "assets/images/product_albon.png", "priceGBP": 40.00 },
    { "id": 4, "name": "Williams Racing Model Car 1:43", "imagePath": "assets/images/product_model.png", "priceGBP": 70.00 },
  ];

  @override
  void initState() {
    super.initState();
    _ratesFuture = _exchangeService.getRates('GBP');
    _initializeShakeGame();
    // --- Muat alamat terakhir dari Hive saat init ---
    // Karena IndexedStack, ini hanya akan jalan SEKALI saat app dibuka
    _loadAddressFromHive(); 
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    _manualAddressController.dispose(); // Dispose controller
    _searchController.dispose(); // DARI INSTRUKSI 2
    super.dispose();
  }

  // --- 1. LOGIKA LOKASI ---

  // --- Muat alamat terakhir yang tersimpan di Hive ---
  Future<void> _loadAddressFromHive() async {
      try {
        final userBox = Hive.box('users');
        final currentUserEmail = userBox.get('currentUserEmail');
        if (currentUserEmail != null) {
          final userData = userBox.get(currentUserEmail) as Map?;
          if (userData != null && userData.containsKey('address') && userData['address'] != null) {
              if (mounted) {
                setState(() {
                  _currentAddress = userData['address'];
                });
              }
              print("[StoreScreen] Alamat dimuat dari Hive: $_currentAddress");
          } else {
              print("[StoreScreen] Alamat di Hive kosong, pakai default.");
              if (mounted) setState(() => _currentAddress = _defaultAddressMessage);
          }
        }
      } catch (e) {
        print("[StoreScreen] Gagal memuat alamat dari Hive: $e");
      }
  }

  // --- BARU: Dialog untuk memilih sumber lokasi (dengan opsi Peta) ---
  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
              title: const Text('Gunakan Lokasi Saat Ini (Otomatis)'),
              onTap: () {
                Navigator.pop(ctx); // Tutup bottom sheet
                _determinePosition(); // Panggil fungsi GPS
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_location_outlined, color: Theme.of(context).colorScheme.primary),
              title: const Text('Masukkan Alamat Manual'),
              onTap: () {
                  Navigator.pop(ctx); // Tutup bottom sheet
                _showManualAddressDialog(); // Panggil dialog input manual
              },
            ),
              // --- BARU: Opsi Pilih dari Peta ---
              ListTile(
                leading: Icon(Icons.map_outlined, color: Theme.of(context).colorScheme.primary),
                title: const Text('Pilih dari Peta'),
                onTap: () async { // Jadikan async
                  Navigator.pop(ctx); // Tutup bottom sheet
                  // Buka halaman peta dan tunggu hasilnya (LatLng)
                  final result = await Navigator.pushNamed(context, '/map-picker');
                  
                  // Jika pengguna memilih lokasi dan kembali
                  if (result != null && result is LatLng) {
                    print("[StoreScreen] Menerima LatLng dari Peta: $result");
                    // Ubah LatLng menjadi Position (dummy) untuk _getAddressFromLatLng
                    final Position mapPosition = Position(
                        latitude: result.latitude,
                        longitude: result.longitude,
                        timestamp: DateTime.now(),
                        accuracy: 100.0, altitude: 0, altitudeAccuracy: 0,
                        heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0
                    );
                    // Panggil fungsi reverse geocoding
                    _getAddressFromLatLng(mapPosition);
                  } else {
                    print("[StoreScreen] Pemilihan peta dibatalkan atau data tidak valid.");
                  }
                },
              ),
              ListTile(
              leading: Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.outline.withOpacity(0.7)),
              title: const Text('Batal'),
              onTap: () => Navigator.pop(ctx), // Tutup bottom sheet
            ),
          ],
        ),
      ),
    );
  }

  // --- BARU: Dialog untuk input alamat manual ---
  void _showManualAddressDialog() {
    if (_currentAddress != _defaultAddressMessage) {
        _manualAddressController.text = _currentAddress;
    } else {
        _manualAddressController.text = "";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masukkan Alamat Manual'),
        content: Form(
          key: _manualAddressFormKey,
          child: TextFormField(
            controller: _manualAddressController,
            decoration: const InputDecoration(
              hintText: "Contoh: Jl. Sudirman No. 1, Jakarta",
              labelText: "Alamat Lengkap",
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Alamat tidak boleh kosong';
              if (value.trim().length < 10) return 'Alamat terlalu pendek';
              return null;
            },
            maxLines: 3,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (_manualAddressFormKey.currentState!.validate()) {
                final manualAddress = _manualAddressController.text.trim();
                Navigator.pop(ctx);
                // Simpan alamat manual ke Hive
                _saveAddressToHive(manualAddress);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // --- BARU: Fungsi helper untuk menyimpan alamat ke Hive ---
  // (Ini adalah kunci agar alamat tidak hilang)
  Future<void> _saveAddressToHive(String address) async {
      if (address.isEmpty) return; 

      try {
        final userBox = Hive.box('users');
        final currentUserEmail = userBox.get('currentUserEmail');
        if (currentUserEmail != null) {
          final userData = Map<dynamic, dynamic>.from(userBox.get(currentUserEmail) ?? {});
          userData['address'] = address; // Tambah/update field alamat
          await userBox.put(currentUserEmail, userData); // Simpan kembali
          
          print("[StoreScreen] Alamat disimpan ke Hive: $address");
          if (mounted) {
            setState(() {
              _currentAddress = address; // Update UI state
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alamat berhasil disimpan!'), backgroundColor: Colors.green));
          }
        } else {
          throw Exception("User tidak login, tidak bisa simpan alamat.");
        }
      } catch (e) {
        print("[StoreScreen] Gagal simpan alamat ke Hive: $e");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan alamat: $e'), backgroundColor: Colors.redAccent));
      }
  }


  /**
    * Meminta izin lokasi dan mengambil posisi saat ini (Otomatis).
    */
  Future<void> _determinePosition() async {
    if (_isFetchingLocation) return;
    if (mounted) setState(() => _isFetchingLocation = true);

    LocationPermission permission;
    bool serviceEnabled;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Layanan lokasi nonaktif. Mohon aktifkan GPS.');

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Izin lokasi ditolak.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Izin lokasi ditolak permanen. Buka pengaturan aplikasi.');

      print("[StoreScreen] Izin lokasi didapat. Mengambil posisi...");
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      print("[StoreScreen] Posisi didapat: ${position.latitude}, ${position.longitude}");

      // Konversi ke Alamat (fungsi ini akan panggil _saveAddressToHive)
      _getAddressFromLatLng(position); 

    } catch (e) {
      print("[StoreScreen] Error mendapatkan lokasi: $e");
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
          setState(() => _isFetchingLocation = false);
      }
    }
    // Hentikan loading dipindahkan ke _getAddressFromLatLng
  }

  /**
    * Mengubah koordinat (Lat/Lng) menjadi alamat jalan.
    * --- UPDATE: Memanggil _saveAddressToHive ---
    */
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      // Hapus parameter locale/localeIdentifier
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''}";
        address = address.replaceAll(RegExp(r', , '), ', ').replaceAll(RegExp(r'^, |,$'), '').trim();
        print("[StoreScreen] Alamat didapat: $address");
        
        if (address.isNotEmpty) {
            // --- PENTING: Simpan ke Hive setiap kali alamat didapat ---
            await _saveAddressToHive(address);
        } else {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat menemukan alamat dari lokasi Anda.')));
        }
      } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat menemukan alamat.')));
      }
    } catch (e) {
      print("[StoreScreen] Error konversi alamat: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal konversi alamat: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
        // Pastikan loading dihentikan di sini
        if (mounted) setState(() => _isFetchingLocation = false);
    }
  }


  // --- 2. LOGIKA GAME SHAKE (Sama) ---
  void _initializeShakeGame() {
      _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (ShakeEvent event) { 
        if (!_eggBroken && mounted) {
          setState(() => _shakeCount++);
          if (_shakeCount >= _shakesToBreak) _breakTheEgg();
        }
      },
      shakeSlopTimeMS: 500, shakeThresholdGravity: 2.7,
    );
    _shakeDetector?.startListening();
    print("[StoreScreen] Shake detector dimulai.");
  }
  void _breakTheEgg() {
    if (_eggBroken) return;
    print("[StoreScreen] Telur pecah!");
    _shakeDetector?.stopListening();
    String code = 'WILLIAMS${_random.nextInt(900) + 100}';
    if (mounted) {
      setState(() { _eggBroken = true; _referralCode = code; });
      _showReferralDialog(code);
    }
  }
  void _showReferralDialog(String code) {
    showDialog( context: context, barrierDismissible: false, builder: (context) => AlertDialog(
        title: const Text('Selamat!', textAlign: TextAlign.center),
        content: Column( mainAxisSize: MainAxisSize.min, children: [
          Text('Kamu memecahkan telur! Ini kode diskon untukmu:', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8))),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1),
            ),
            child: Text( code, style: TextStyle( color: Theme.of(context).colorScheme.primary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          const SizedBox(height: 16),
          const Text('(Kode ini hanya contoh)', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
        ],),
        actions: [ TextButton( onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
      ),
    );
  }


  // --- UI BUILD METHOD ---
  // --- SESUAI INSTRUKSI 6: Update build method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store & Misi'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildLocationHeader(theme),
          const SizedBox(height: 24),
          _buildEggGame(theme),
          const SizedBox(height: 24),
          _buildSearchBar(theme), // TAMBAHKAN INI
          const SizedBox(height: 16),
          _buildStoreSection(theme),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  /**
    * Membangun bagian Header (Tombol Lokasi + Gambar Placeholder).
    * --- SESUAI INSTRUKSI 3: Ganti fungsi _buildLocationHeader ---
    */
  Widget _buildLocationHeader(ThemeData theme) {
    return Column(
      children: [
        // BAGIAN 1: LOKASI (TANPA GAMBAR)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alamat Pengiriman:',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: _currentAddress == _defaultAddressMessage
                              ? Colors.orangeAccent[100]
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontStyle: _currentAddress == _defaultAddressMessage
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isFetchingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.edit_location_outlined,
                          color: theme.colorScheme.primary,
                        ),
                  onPressed: _isFetchingLocation ? null : _showLocationOptions,
                  tooltip: 'Ubah Alamat Pengiriman',
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // BAGIAN 2: GAMBAR BANNER (TERPISAH)
        Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: AspectRatio(
            aspectRatio: 16 / 9, // Rasio 16:9 agar tidak terpotong
            child: Image.asset(
              'assets/images/williams_carousel_1.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                color: theme.colorScheme.surfaceContainerHigh,
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // --- SESUAI INSTRUKSI 4: Tambahkan widget untuk Search Bar ---
  Widget _buildSearchBar(ThemeData theme) {
    return Card(
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari produk Williams Racing...',
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }


  

  /**
    * Membangun bagian Gamifikasi "Pecah Telur". (Sama)
    */
  Widget _buildEggGame(ThemeData theme) {
    double progress = _shakeCount / _shakesToBreak;
    progress = progress.clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_eggBroken ? 'Telur Telah Pecah!' : 'Goyangkan HP untuk Hadiah!', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Center(
                child: _eggBroken
                    ? Column( mainAxisSize: MainAxisSize.min, children: [
                        Text('Kode Referral Anda:', style: TextStyle(color: theme.colorScheme.outline)),
                        const SizedBox(height: 8),
                        Text(_referralCode, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 1.5)),
                      ])
                    : Icon(Icons.egg_alt_outlined, size: 60 + (progress * 20), color: theme.colorScheme.primary.withOpacity(0.5 + (progress * 0.5))),
              ),
            ),
            const SizedBox(height: 16),
            if (!_eggBroken)
              LinearProgressIndicator(
                value: progress, minHeight: 8, borderRadius: BorderRadius.circular(4),
                backgroundColor: theme.colorScheme.surfaceVariant, color: theme.colorScheme.primary,
              ),
              if (!_eggBroken)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('${(_shakeCount / _shakesToBreak * 100).toInt()}%', style: TextStyle(color: theme.colorScheme.outline, fontSize: 12)),
                ),
          ],
        ),
      ),
    );
  }

  /**
    * Membangun bagian Toko (Dropdown Konversi + Daftar Produk).
    * --- SESUAI INSTRUKSI 5: Update fungsi _buildStoreSection ---
    */
  Widget _buildStoreSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Williams Store',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Theme(
                data: theme.copyWith(canvasColor: theme.colorScheme.surface),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    items: _targetCurrencies
                        .map((String currency) => DropdownMenuItem<String>(
                              value: currency,
                              child: Text(
                                currency,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) setState(() => _selectedCurrency = newValue);
                    },
                    iconEnabledColor: theme.colorScheme.primary,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, dynamic>>(
          future: _ratesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Gagal memuat kurs mata uang: ${snapshot.error}',
                    style: const TextStyle(color: Colors.orangeAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (snapshot.hasData) {
              final Map<String, dynamic> rates = snapshot.data!;
              if (!rates.containsKey(_selectedCurrency)) {
                return Center(
                  child: Text('Mata uang $_selectedCurrency tidak ditemukan di API.'),
                );
              }

              // FILTER PRODUK BERDASARKAN SEARCH
              final filteredProducts = _products.where((product) {
                if (_searchQuery.isEmpty) return true;
                final name = (product['name'] as String).toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

              if (filteredProducts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Produk tidak ditemukan',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba kata kunci lain',
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredProducts.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return _buildProductCard(
                    theme: theme,
                    product: product,
                    rates: rates,
                  );
                },
              );
            }
            return const Center(child: Text('Memuat data toko...'));
          },
        ),
      ],
    );
  }

// Cek apakah produk sudah di-bookmark
Future<bool> _isBookmarked(int productId) async {
  try {
    final userBox = Hive.box('users');
    final currentUserEmail = userBox.get('currentUserEmail');
    
    if (currentUserEmail != null) {
      final userData = userBox.get(currentUserEmail) as Map?;
      if (userData != null && userData.containsKey('bookmarks')) {
        List<dynamic> bookmarks = List.from(userData['bookmarks'] ?? []);
        return bookmarks.any((product) => product['id'] == productId);
      }
    }
  } catch (e) {
    print('[StoreScreen] Error checking bookmark: $e');
  }
  return false;
}

// Toggle bookmark (tambah/hapus)
Future<void> _toggleBookmark(Map<String, dynamic> product) async {
  try {
    final userBox = Hive.box('users');
    final currentUserEmail = userBox.get('currentUserEmail');
    
    if (currentUserEmail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap login terlebih dahulu'))
        );
      }
      return;
    }
    
    final userData = Map<dynamic, dynamic>.from(userBox.get(currentUserEmail) ?? {});
    List<dynamic> bookmarks = List.from(userData['bookmarks'] ?? []);
    
    final productId = product['id'];
    final isCurrentlyBookmarked = bookmarks.any((p) => p['id'] == productId);
    
    if (isCurrentlyBookmarked) {
      // Hapus dari bookmark
      bookmarks.removeWhere((p) => p['id'] == productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dihapus dari favorit'),
            backgroundColor: Colors.orange,
          )
        );
      }
    } else {
      // Tambah ke bookmark
      bookmarks.add(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ditambahkan ke favorit'),
            backgroundColor: Colors.green,
          )
        );
      }
    }
    
    userData['bookmarks'] = bookmarks;
    await userBox.put(currentUserEmail, userData);
    
    setState(() {}); // Refresh UI
    
  } catch (e) {
    print('[StoreScreen] Error toggling bookmark: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.redAccent)
      );
    }
  }
}

// --- UPDATE WIDGET _buildProductCard ---
// Ganti fungsi _buildProductCard yang lama dengan ini:

Widget _buildProductCard({
  required ThemeData theme,
  required Map<String, dynamic> product,
  required Map<String, dynamic> rates,
}) {
  final String imagePath = product['imagePath'] as String;
  final String name = product['name'] as String;
  final double priceGBP = product['priceGBP'] as double;
  final int productId = product['id'] as int;
  
  final double exchangeRate = (rates[_selectedCurrency] as num?)?.toDouble() ?? 1.0;
  final double convertedPrice = priceGBP * exchangeRate;
  
  final formatPriceGBP = NumberFormat.currency(symbol: '£', decimalDigits: 2, locale: 'en_GB').format(priceGBP);
  final formatConverted = NumberFormat.currency(
      symbol: (_selectedCurrency == 'IDR' ? 'Rp ' : _selectedCurrency == 'USD' ? '\$' : _selectedCurrency == 'EUR' ? '€' : _selectedCurrency + ' '),
      decimalDigits: (_selectedCurrency == 'IDR' ? 0 : 2),
      locale: 'id_ID'
  ).format(convertedPrice);

  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: () {
        print("[StoreScreen] Card '$name' ditekan.");
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: ProductDetailArguments(
            product: product,
            rates: rates,
            initialCurrency: _selectedCurrency,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                imagePath, width: 100, height: 100, fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 100, height: 100, 
                  color: theme.colorScheme.surfaceVariant, 
                  child: const Icon(Icons.image_not_supported, color: Colors.grey)
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Info Produk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name, 
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500, 
                      color: theme.colorScheme.onSurface
                    ), 
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatPriceGBP, 
                    style: TextStyle(
                      fontSize: 14, 
                      color: theme.colorScheme.outline, 
                      decoration: TextDecoration.lineThrough
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatConverted, 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: theme.colorScheme.primary
                    )
                  ),
                ],
              ),
            ),
            
            // Kolom Ikon (Bookmark & Chevron)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tombol Bookmark
                FutureBuilder<bool>(
                  future: _isBookmarked(productId),
                  builder: (context, snapshot) {
                    final isBookmarked = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Colors.amber : theme.colorScheme.outline,
                      ),
                      onPressed: () => _toggleBookmark(product),
                      tooltip: isBookmarked ? 'Hapus dari Favorit' : 'Tambah ke Favorit',
                    );
                  },
                ),
                
                // Ikon Chevron (Detail)
                Icon(Icons.chevron_right, color: theme.colorScheme.outline, size: 28),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
  

} // Akhir Class _StoreScreenState