/**
 * File: map_picker_screen.dart
 * Deskripsi: Halaman fullscreen untuk memilih lokasi dari peta OpenStreetMap.
 * Menggunakan flutter_map dan latlong2.
 * Mengembalikan LatLng yang dipilih ke halaman sebelumnya.
 */

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Untuk mendapatkan lokasi awal

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Lokasi default (Monas, Jakarta) jika GPS gagal
  final LatLng _defaultPosition = const LatLng(-6.175392, 106.827153);
  LatLng? _currentCenter; // Posisi tengah peta saat ini
  
  // Posisi marker yang dipilih pengguna
  LatLng? _markerPosition;
  
  // Controller untuk peta
  final MapController _mapController = MapController();

  bool _isLoadingGps = true; // Status loading GPS awal

  @override
  void initState() {
    super.initState();
    // Coba dapatkan lokasi GPS saat ini untuk posisi awal peta
    _determineInitialPosition();
  }

  // Coba cari lokasi GPS pengguna untuk jadi pusat peta
  Future<void> _determineInitialPosition() async {
    try {
      // Cek izin (asumsi izin sudah diminta di store_screen, tapi cek lagi)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
         // Jika tidak ada izin, gunakan default
         print("[MapPicker] Izin GPS tidak ada, pakai default (Monas)");
         if (mounted) setState(() { _currentCenter = _defaultPosition; _isLoadingGps = false; });
         return;
      }
      // Ambil posisi
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5) // Batasi waktu tunggu GPS
      );
      print("[MapPicker] Posisi GPS awal didapat: ${position.latitude}, ${position.longitude}");
      if (mounted) {
         setState(() {
           _currentCenter = LatLng(position.latitude, position.longitude);
           _isLoadingGps = false;
         });
      }
    } catch (e) {
      // Jika GPS gagal (timeout, dll), gunakan default
      print("[MapPicker] Error dapatkan GPS awal: $e. Pakai default (Monas).");
      if (mounted) {
         setState(() {
           _currentCenter = _defaultPosition;
           _isLoadingGps = false;
         });
      }
    }
  }

  // Fungsi saat peta di-tap
  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _markerPosition = latLng; // Pindahkan marker ke lokasi tap
    });
    // Tampilkan SnackBar konfirmasi
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Hapus snackbar lama
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Lokasi dipilih: ${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}',
        ),
        backgroundColor: Theme.of(context).colorScheme.surface, // Warna card
        behavior: SnackBarBehavior.floating, // Mengambang
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Fungsi saat tombol Konfirmasi (FAB) ditekan
  void _confirmSelection() {
    if (_markerPosition != null) {
      print("[MapPicker] Lokasi dikonfirmasi: $_markerPosition");
      // Kembalikan data LatLng ke halaman sebelumnya (StoreScreen)
      Navigator.pop(context, _markerPosition);
    } else {
      // Jika belum ada marker
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan ketuk peta untuk memilih lokasi terlebih dahulu.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi dari Peta'),
        centerTitle: true,
        // (Warna AppBar otomatis dari tema)
      ),
      // Gunakan Stack untuk menumpuk Peta dan Tombol Konfirmasi
      body: Stack(
        children: [
          // Tampilkan loading jika sedang mencari GPS awal
          if (_isLoadingGps)
            const Center(child: CircularProgressIndicator()),
          
          // Tampilkan peta jika GPS sudah siap (atau gagal & pakai default)
          if (!_isLoadingGps && _currentCenter != null)
            FlutterMap(
              mapController: _mapController, // Hubungkan controller
              options: MapOptions(
                initialCenter: _currentCenter!, // Posisi tengah awal
                initialZoom: 15.0, // Zoom awal
                onTap: _handleMapTap, // Fungsi saat peta di-tap
                interactionOptions: const InteractionOptions(
                   flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Izinkan semua interaksi kecuali rotasi
                ),
              ),
              children: [
                // Layer 1: Tile Peta (OpenStreetMap)
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  // User agent penting untuk OpenStreetMap
                  userAgentPackageName: 'com.example.williams', // TODO: Sesuaikan jika package name beda
                ),
                
                // Layer 2: Marker (jika _markerPosition tidak null)
                if (_markerPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _markerPosition!,
                        width: 80,
                        height: 80,
                        // Gunakan Icon dengan warna tema
                        child: Icon(
                          Icons.location_pin,
                          color: theme.colorScheme.primary, // Warna ungu
                          size: 45,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          
          // Tombol untuk kembali ke lokasi GPS saat ini (jika bergeser)
           if (!_isLoadingGps)
             Positioned(
               top: 16,
               right: 16,
               child: FloatingActionButton(
                 heroTag: 'gps_fab', // Tag hero unik
                 mini: true, // Tombol kecil
                 onPressed: () {
                    // Animasikan peta kembali ke lokasi GPS awal
                    _mapController.move(_currentCenter!, 15.0);
                 },
                 backgroundColor: theme.colorScheme.surface, // Warna card
                 child: Icon(Icons.my_location, color: theme.colorScheme.primary), // Ikon ungu
               ),
             ),
        ],
      ),
      
      // Tombol Konfirmasi (Floating Action Button)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirmSelection, // Panggil fungsi konfirmasi
        icon: const Icon(Icons.check),
        label: const Text('Konfirmasi Lokasi'),
        // Style otomatis diambil dari tema (ungu)
      ),
    );
  }
}
