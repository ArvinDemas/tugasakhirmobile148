/**
 * File: product_detail_screen.dart
 * Deskripsi: Halaman untuk menampilkan detail satu produk.
 * UPDATE:
 * - Tombol "Beli Sekarang" sekarang mengarahkan ke '/checkout'
 * - Mengirimkan argumen yang sama ke halaman checkout.
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'dart:async'; // Tidak perlu lagi untuk simulasi di sini

// Helper class untuk menerima argumen (data) dari halaman store
// Class ini akan digunakan juga oleh CheckoutScreen
class ProductDetailArguments {
  final Map<String, dynamic> product; // Data produk yang diklik
  final Map<String, dynamic> rates; // Data semua kurs mata uang
  final String initialCurrency; // Mata uang yang sedang dipilih

  ProductDetailArguments({
    required this.product,
    required this.rates,
    required this.initialCurrency,
  });
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  // State untuk menyimpan data yang diterima
  late Map<String, dynamic> _product;
  late Map<String, dynamic> _rates;
  late String _selectedCurrency;
  
  bool _isLoading = true; // Status loading awal (untuk ambil argumen)
  // bool _isOrdering = false; // Tidak perlu lagi di sini
  final List<String> _targetCurrencies = ['IDR', 'USD', 'EUR', 'AUD'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArguments();
    });
  }

  void _loadArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductDetailArguments) {
      setState(() {
        _product = args.product;
        _rates = args.rates;
        _selectedCurrency = args.initialCurrency;
        _isLoading = false;
      });
    } else {
      print("[ProductDetail] Error: Argumen tidak valid atau null.");
      setState(() { _isLoading = false; });
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Gagal memuat detail produk.'), backgroundColor: Colors.red)
         );
         Navigator.pop(context);
      }
    }
  }

  // --- FUNGSI BARU: Navigasi ke Checkout ---
  void _navigateToCheckout() {
    // Saat tombol ditekan, navigasi ke halaman checkout baru
    Navigator.pushNamed(
      context,
      '/checkout', // Rute checkout yang baru
      arguments: ProductDetailArguments( // Kirim argumen yang sama
        product: _product,
        rates: _rates,
        initialCurrency: _selectedCurrency,
      ),
    );
  }
  
  // Helper untuk mendapatkan simbol mata uang
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'IDR': return 'Rp ';
      case 'USD': return '\$';
      case 'EUR': return '€';
      default: return '$currencyCode ';
    }
  }

  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }
    
    // Ambil data produk dari state
    final String name = _product['name'] as String;
    final String imagePath = _product['imagePath'] as String;
    final double priceGBP = _product['priceGBP'] as double;
    
    // Hitung harga konversi
    final double exchangeRate = (_rates[_selectedCurrency] as num?)?.toDouble() ?? 1.0;
    final double convertedPrice = priceGBP * exchangeRate;
    
    // Format harga
    final formatPriceGBP = NumberFormat.currency(symbol: '£', decimalDigits: 2, locale: 'en_GB').format(priceGBP);
    final formatConverted = NumberFormat.currency(
      symbol: _getCurrencySymbol(_selectedCurrency),
      decimalDigits: _selectedCurrency == 'IDR' ? 0 : 2,
      locale: 'id_ID'
    ).format(convertedPrice);

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- GAMBAR PRODUK ---
            Image.asset(
              imagePath,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 300,
                color: theme.colorScheme.surfaceVariant,
                child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 60)),
              ),
            ),
            
            // --- INFO PRODUK (DALAM PADDING) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Produk
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Deskripsi Produk (Placeholder)
                  Text(
                    'Deskripsi detail produk akan tampil di sini. Ini adalah item eksklusif dari Williams Racing Store, dibuat dengan bahan berkualitas tinggi untuk para penggemar sejati.',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // --- PILIHAN MATA UANG ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tampilkan Harga dalam:',
                         style: TextStyle(color: theme.colorScheme.outline, fontSize: 14),
                      ),
                      Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                         decoration: BoxDecoration(
                           color: theme.colorScheme.surfaceVariant,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: DropdownButtonHideUnderline(
                           child: DropdownButton<String>(
                              value: _selectedCurrency,
                              items: _targetCurrencies.map((String currency) {
                                return DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency, style: const TextStyle(fontWeight: FontWeight.w500)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                 if (newValue != null) {
                                   setState(() { _selectedCurrency = newValue; });
                                 }
                              },
                              dropdownColor: theme.colorScheme.surface,
                              iconEnabledColor: theme.colorScheme.primary,
                           ),
                         ),
                       ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- TAMPILAN HARGA ---
                  Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     crossAxisAlignment: CrossAxisAlignment.center,
                     children: [
                        Text(
                          formatPriceGBP,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.outline,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          formatConverted,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                     ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80), // Jarak ke tombol bawah
          ],
        ),
      ),

      // --- TOMBOL BELI (di Bottom) ---
      // --- UPDATE: Tombol ini sekarang navigasi ke Checkout ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: ElevatedButton.icon(
          // Tombol tidak ada state loading di sini lagi
          onPressed: _navigateToCheckout, // Panggil fungsi navigasi
          icon: const Icon(Icons.shopping_cart_checkout), // Ikon checkout
          label: Text(
            'Beli Sekarang ($formatConverted)', // Tampilkan harga
          ),
        ),
      ),
    );
  }
}

