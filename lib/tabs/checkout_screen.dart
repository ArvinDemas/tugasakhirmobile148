/**
 * File: checkout_screen.dart
 * Deskripsi: Halaman untuk konfirmasi pesanan (alamat, pengiriman, pembayaran)
 * sebelum menyelesaikan pembelian.
 *
 * UPDATE:
 * - Menambahkan validasi alamat di _placeOrder
 * - Memperbaiki error _selectedCurrency (diganti 'currency')
 * - Menghapus variabel 'shippingConverted' yang tidak terpakai
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Untuk ambil data user & simpan pesanan
import 'package:intl/intl.dart'; // Untuk format harga & tanggal
import 'product_detail_screen.dart'; // Untuk ProductDetailArguments

// Enum untuk pilihan (agar lebih mudah dibaca)
enum ShippingMethod { JNE, Sicepat }
enum PaymentMethod { Gopay, Dana, SPay }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // State untuk data yang diterima
  ProductDetailArguments? _args; // Argumen dari halaman detail
  
  // State untuk data user (dari Hive)
  String _userName = "Memuat...";
  String _userEmail = "Memuat...";
  String _userAddress = "Alamat belum diatur di Store"; // Default
  String _defaultAddressMessage = "Alamat belum diatur di Store"; // Simpan pesan default

  // State untuk pilihan checkout
  ShippingMethod? _selectedShipping = ShippingMethod.JNE; // Default JNE
  PaymentMethod? _selectedPayment = PaymentMethod.Gopay; // Default Gopay

  // State UI
  bool _isLoadingData = true; // Loading data user
  bool _isPlacingOrder = false; // Loading saat tekan "Bayar"

  // Biaya pengiriman (contoh statis)
  final Map<ShippingMethod, double> _shippingCosts = {
    ShippingMethod.JNE: 15.00, // Harga dalam GBP
    ShippingMethod.Sicepat: 12.00,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(); // Panggil fungsi untuk ambil argumen & data Hive
    });
  }

  // Fungsi untuk mengambil data argumen DAN data user dari Hive
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

    // 1. Ambil Argumen (Produk, Harga)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductDetailArguments) {
      _args = args; // Simpan argumen di state
    } else {
      // Error: Halaman ini tidak bisa dibuka tanpa argumen
      print("[Checkout] Error: Argumen ProductDetailArguments tidak ditemukan.");
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Gagal memuat data produk.'), backgroundColor: Colors.red));
         Navigator.pop(context);
      }
      return;
    }

    // 2. Ambil Data User (Nama, Alamat) dari Hive
    try {
      final userBox = Hive.box('users');
      final currentUserEmail = userBox.get('currentUserEmail') as String?;
      
      if (currentUserEmail != null) {
        final userData = userBox.get(currentUserEmail) as Map?;
        if (userData != null) {
           if (mounted) {
             setState(() {
               _userEmail = currentUserEmail;
               _userName = userData['username'] ?? 'Nama Tidak Ada';
               // Ambil alamat, jika tidak ada, gunakan pesan default
               _userAddress = userData['address'] ?? _defaultAddressMessage; 
             });
           }
        } else { throw Exception('Data user tidak ditemukan.'); }
      } else { throw Exception('User tidak login.'); }

    } catch (e) {
       print("[Checkout] Error loading user data from Hive: $e");
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data user: $e'), backgroundColor: Colors.redAccent));
         setState(() { _userName = "Error"; _userEmail = "Error"; });
       }
    }
    
    // Selesai loading
    if (mounted) setState(() => _isLoadingData = false);
  }

  // --- FUNGSI PROSES PESANAN ---
  Future<void> _placeOrder() async {
     // --- FIX: Tambahkan validasi alamat ---
     if (_userAddress == _defaultAddressMessage || _userAddress.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Alamat pengiriman belum diatur! Harap atur di tab Store.'),
          backgroundColor: Colors.orange,
        ));
        return; // Hentikan proses
     }

     if (_isPlacingOrder || _args == null || _selectedShipping == null || _selectedPayment == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi pilihan pengiriman dan pembayaran.'), backgroundColor: Colors.orange));
        return;
     }
     
     if (mounted) setState(() => _isPlacingOrder = true);
     print("[Checkout] Memproses pesanan...");

     try {
        // 1. Siapkan data pesanan untuk disimpan
        final product = _args!.product;
        final rates = _args!.rates;
        final currency = _args!.initialCurrency;
        final shippingCostGBP = _shippingCosts[_selectedShipping]!;
        final productPriceGBP = product['priceGBP'] as double;
        final totalGBP = productPriceGBP + shippingCostGBP;

        final rate = (rates[currency] as num?)?.toDouble() ?? 1.0;
        final totalConverted = totalGBP * rate;

        final Map<String, dynamic> orderData = {
           'orderId': 'WMS-${DateTime.now().millisecondsSinceEpoch}',
           'date': DateTime.now().toIso8601String(),
           'productName': product['name'],
           'productImage': product['imagePath'],
           'priceGBP': productPriceGBP,
           'shippingCostGBP': shippingCostGBP,
           'totalGBP': totalGBP,
           'currency': currency,
           'totalConverted': totalConverted,
           'shippingMethod': _selectedShipping.toString().split('.').last,
           'paymentMethod': _selectedPayment.toString().split('.').last,
           'shippingAddress': _userAddress, // Alamat pengiriman
           'customerName': _userName, // Nama pelanggan
        };

        // 2. Simpan ke Hive Box 'orders'
        // (Pastikan Box 'orders' sudah dibuka di main.dart)
        final ordersBox = Hive.box('orders'); 
        final currentUserEmail = Hive.box('users').get('currentUserEmail');
        
        final List<dynamic> userOrders = List.from(ordersBox.get(currentUserEmail) ?? []);
        userOrders.insert(0, orderData); 
        
        await ordersBox.put(currentUserEmail, userOrders);
        print("[Checkout] Pesanan berhasil disimpan ke Hive untuk $currentUserEmail");

        // 3. Simulasi loading bayar
        await Future.delayed(const Duration(seconds: 2));

        // 4. Navigasi ke halaman sukses
        if (mounted) {
           Navigator.pushNamedAndRemoveUntil(
             context, 
             '/order-success',
             (route) => route.isFirst,
           );
        }

     } catch (e) {
       print("[Checkout] Error saat menyimpan pesanan: $e");
       if (mounted) {
          // Tampilkan error (termasuk jika Box not found)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memproses pesanan: $e'), backgroundColor: Colors.redAccent));
       }
     } finally {
       if (mounted) setState(() => _isPlacingOrder = false);
     }
  }

  // --- FIX: Ganti _selectedCurrency menjadi currencyCode ---
  String _formatPrice(double price, String currencyCode, Map<String, dynamic> rates) {
      if (!rates.containsKey(currencyCode)) return "N/A";
      final rate = (rates[currencyCode] as num?)?.toDouble() ?? 1.0;
      final convertedPrice = price * rate;
      
      // Gunakan parameter 'currencyCode'
      return NumberFormat.currency(
        symbol: (currencyCode == 'IDR' ? 'Rp ' : currencyCode == 'USD' ? '\$' : currencyCode == 'EUR' ? '€' : currencyCode + ' '),
        decimalDigits: (currencyCode == 'IDR' ? 0 : 2),
        locale: 'id_ID'
      ).format(convertedPrice);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingData || _args == null) {
       return Scaffold(
         appBar: AppBar(title: const Text('Checkout')),
         body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
       );
    }

    // Ambil mata uang dari argumen
    final product = _args!.product;
    final rates = _args!.rates;
    // --- FIX: Ambil currency dari argumen ---
    final currency = _args!.initialCurrency; 

    // Hitung harga
    final priceGBP = product['priceGBP'] as double;
    final shippingCostGBP = _shippingCosts[_selectedShipping] ?? 0.0;
    final totalGBP = priceGBP + shippingCostGBP;

    // Format harga
    final priceConverted = _formatPrice(priceGBP, currency, rates);
    // --- FIX: Hapus variabel 'shippingConverted' yang tidak terpakai ---
    // final shippingConverted = _formatPrice(shippingCostGBP, currency, rates);
    final totalConverted = _formatPrice(totalGBP, currency, rates);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 1. Detail Pesanan ---
          _buildSectionTitle(theme, 'Detail Pesanan'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                     borderRadius: BorderRadius.circular(8.0),
                     child: Image.asset(
                       product['imagePath'], width: 80, height: 80, fit: BoxFit.cover,
                       errorBuilder: (c,e,s) => Container(width: 80, height: 80, color: theme.colorScheme.surfaceVariant, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                     ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Text(product['name'], style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text('Harga Produk', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                          Text(priceConverted, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.primary)),
                       ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. Alamat Pengiriman ---
          _buildSectionTitle(theme, 'Alamat Pengiriman'),
          Card(
             child: ListTile(
               leading: Icon(Icons.home_outlined, color: theme.colorScheme.primary),
               title: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
               subtitle: Text("$_userEmail\n$_userAddress", style: TextStyle(color: theme.colorScheme.outline, height: 1.4)),
               isThreeLine: true,
             ),
          ),

          // --- 3. Jasa Pengiriman ---
          _buildSectionTitle(theme, 'Jasa Pengiriman'),
          Card(
             child: Column(
               children: [
                 RadioListTile<ShippingMethod>(
                   title: const Text('JNE Reguler'),
                   // Panggil _formatPrice dengan 'currency' yang benar
                   subtitle: Text('Estimasi 2-3 hari kerja - ${_formatPrice(_shippingCosts[ShippingMethod.JNE]!, currency, rates)}'),
                   value: ShippingMethod.JNE,
                   groupValue: _selectedShipping,
                   onChanged: (ShippingMethod? value) {
                     setState(() { _selectedShipping = value; });
                   },
                   activeColor: theme.colorScheme.primary,
                 ),
                 const Divider(height: 1, indent: 16, endIndent: 16),
                 RadioListTile<ShippingMethod>(
                   title: const Text('Sicepat BEST'),
                   // Panggil _formatPrice dengan 'currency' yang benar
                   subtitle: Text('Estimasi 1-2 hari kerja - ${_formatPrice(_shippingCosts[ShippingMethod.Sicepat]!, currency, rates)}'),
                   value: ShippingMethod.Sicepat,
                   groupValue: _selectedShipping,
                   onChanged: (ShippingMethod? value) {
                     setState(() { _selectedShipping = value; });
                   },
                   activeColor: theme.colorScheme.primary,
                 ),
               ],
             ),
          ),

          // --- 4. Metode Pembayaran ---
          _buildSectionTitle(theme, 'Metode Pembayaran'),
           Card(
             child: Column(
               children: [
                 RadioListTile<PaymentMethod>(
                   title: const Text('Gopay E-Wallet'),
                   secondary: const Icon(Icons.wallet, color: Colors.blueAccent),
                   value: PaymentMethod.Gopay,
                   groupValue: _selectedPayment,
                   onChanged: (PaymentMethod? value) {
                     setState(() { _selectedPayment = value; });
                   },
                   activeColor: theme.colorScheme.primary,
                 ),
                 const Divider(height: 1, indent: 16, endIndent: 16),
                 RadioListTile<PaymentMethod>(
                   title: const Text('DANA E-Wallet'),
                   secondary: const Icon(Icons.wallet, color: Colors.lightBlue),
                   value: PaymentMethod.Dana,
                   groupValue: _selectedPayment,
                   onChanged: (PaymentMethod? value) {
                     setState(() { _selectedPayment = value; });
                   },
                   activeColor: theme.colorScheme.primary,
                 ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                 RadioListTile<PaymentMethod>(
                   title: const Text('ShopeePay E-Wallet'),
                   secondary: const Icon(Icons.wallet, color: Colors.orangeAccent),
                   value: PaymentMethod.SPay,
                   groupValue: _selectedPayment,
                   onChanged: (PaymentMethod? value) {
                     setState(() { _selectedPayment = value; });
                   },
                   activeColor: theme.colorScheme.primary,
                 ),
               ],
             ),
           ),
        ],
      ),

      // --- BOTTOM BAR: TOTAL & TOMBOL BAYAR ---
      bottomNavigationBar: Container(
         padding: const EdgeInsets.all(16.0),
         decoration: BoxDecoration(
           color: theme.colorScheme.surface,
           boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 0) ],
         ),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text('Total Pembayaran:', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
                 Text(
                   totalConverted, // Total harga + ongkir
                   style: theme.textTheme.titleLarge?.copyWith(
                     color: theme.colorScheme.primary,
                     fontWeight: FontWeight.bold
                   ),
                 ),
               ],
             ),
             ElevatedButton(
               onPressed: _isPlacingOrder ? null : _placeOrder, // Panggil fungsi simpan pesanan
               child: _isPlacingOrder
                 ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                 : const Text('Lanjut Bayar'),
             ),
           ],
         ),
      ),
    );
  }

  // Helper untuk judul section
  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

