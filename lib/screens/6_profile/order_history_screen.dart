/**
 * File: order_history_screen.dart
 * Deskripsi: Halaman untuk menampilkan daftar riwayat pesanan pengguna dari Hive.
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Untuk baca data
import 'package:intl/intl.dart'; // Untuk format tanggal & harga

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  // State untuk menyimpan daftar pesanan
  List<dynamic> _orders = []; // List pesanan (berisi Map)
  bool _isLoading = true; // Status loading
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadOrderHistory(); // Muat riwayat saat halaman dibuka
  }

  // --- FUNGSI LOAD RIWAYAT PESANAN DARI HIVE ---
  Future<void> _loadOrderHistory() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final userBox = Hive.box('users');
      _currentUserEmail = userBox.get('currentUserEmail'); // Dapatkan email user

      if (_currentUserEmail != null) {
        final ordersBox = Hive.box('orders'); // Buka box pesanan
        // Ambil list pesanan berdasarkan email user, atau list kosong jika null
        final List<dynamic> userOrders = List.from(ordersBox.get(_currentUserEmail) ?? []);
        print("[OrderHistory] Ditemukan ${userOrders.length} pesanan untuk $_currentUserEmail");
        
        if (mounted) {
          setState(() {
            _orders = userOrders; // Simpan list pesanan ke state
            _isLoading = false; // Selesai loading
          });
        }
      } else {
        // Jika tidak ada user login
        throw Exception('User tidak login. Tidak bisa menampilkan riwayat.');
      }
    } catch (e) {
      print("[OrderHistory] Error loading order history: $e");
      if (mounted) {
         setState(() => _isLoading = false); // Selesai loading (meskipun error)
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat riwayat: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  // Helper untuk format harga (ambil dari data tersimpan)
  String _formatSavedPrice(double price, String currencyCode) {
      return NumberFormat.currency(
        symbol: (currencyCode == 'IDR' ? 'Rp ' : currencyCode == 'USD' ? '\$' : currencyCode == 'EUR' ? '€' : currencyCode + ' '),
        decimalDigits: (currencyCode == 'IDR' ? 0 : 2),
        locale: 'id_ID'
      ).format(price);
  }

  // Helper untuk format tanggal (ambil dari data tersimpan)
   String _formatSavedDate(String isoDate) {
     try {
       final DateTime date = DateTime.parse(isoDate);
       // Format: 30 Okt 2025, 12:00
       return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date);
     } catch (e) {
       print("Error parsing date $isoDate: $e");
       return isoDate; // Kembalikan string asli jika format salah
     }
   }


  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        centerTitle: true,
      ),
      body: _isLoading
          // Tampilkan loading indicator jika sedang memuat
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          // Jika sudah selesai loading
          : _orders.isEmpty
              // Tampilkan pesan jika tidak ada riwayat pesanan
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Pesanan',
                        style: theme.textTheme.titleLarge,
                      ),
                       Text(
                        'Semua pesanan Anda akan muncul di sini.',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                )
              // Tampilkan daftar pesanan jika ada
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0), // Padding untuk list
                  itemCount: _orders.length, // Jumlah pesanan
                  itemBuilder: (context, index) {
                    // Ambil data 1 pesanan (berupa Map)
                    final order = _orders[index] as Map<dynamic, dynamic>;
                    
                    // Parsing data dari Map (gunakan fallback '??' jika key tidak ada)
                    final String orderId = order['orderId'] ?? 'ID-???';
                    final String orderDate = _formatSavedDate(order['date'] ?? '');
                    final String productName = order['productName'] ?? 'Produk Tidak Dikenal';
                    final String productImage = order['productImage'] ?? 'assets/images/placeholder.png'; // Perlu placeholder
                    final double totalConverted = (order['totalConverted'] as num?)?.toDouble() ?? 0.0;
                    final String currency = order['currency'] ?? '???';
                    final String paymentMethod = order['paymentMethod'] ?? '???';
                    
                    // Buat Card untuk setiap item riwayat
                    return Card(
                      // margin: const EdgeInsets.only(bottom: 16), // Diambil dari CardTheme
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Baris 1: ID Pesanan & Tanggal
                            Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Text(
                                   orderId,
                                   style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary), // Ungu
                                 ),
                                 Text(
                                   orderDate,
                                   style: TextStyle(fontSize: 12, color: theme.colorScheme.outline), // Abu-abu
                                 ),
                               ],
                            ),
                            const Divider(height: 16), // Pemisah
                            // Baris 2: Detail Produk
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Gambar Produk
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.asset(
                                    productImage, width: 60, height: 60, fit: BoxFit.cover,
                                    errorBuilder: (c,e,s) => Container(width: 60, height: 60, color: theme.colorScheme.surfaceVariant, child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Nama & Total Harga
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatSavedPrice(totalConverted, currency), // Total harga
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            // Baris 3: Status & Metode Bayar
                            Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                  Text(
                                    'Pembayaran: $paymentMethod', // Metode bayar
                                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                                  ),
                                  // Status (statis)
                                  const Text(
                                    'Selesai',
                                    style: TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                  ),
                               ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
