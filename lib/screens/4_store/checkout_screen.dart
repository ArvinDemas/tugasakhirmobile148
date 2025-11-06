/**
 * File: checkout_screen.dart
 * Lokasi: lib/tabs/checkout_screen.dart
 * Deskripsi: Halaman checkout dengan biometrik (FIXED)
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'product_detail_screen.dart';
import '../../services/biometric_service.dart'; // FIX: Path yang benar

enum ShippingMethod { JNE, Sicepat }
enum PaymentMethod { Gopay, Dana, SPay }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  ProductDetailArguments? _args;
  
  String _userName = "Memuat...";
  String _userEmail = "Memuat...";
  String _userAddress = "Alamat belum diatur di Store";
  String _defaultAddressMessage = "Alamat belum diatur di Store";

  ShippingMethod? _selectedShipping = ShippingMethod.JNE;
  PaymentMethod? _selectedPayment = PaymentMethod.Gopay;

  bool _isLoadingData = true;
  bool _isPlacingOrder = false;

  final Map<ShippingMethod, double> _shippingCosts = {
    ShippingMethod.JNE: 15.00,
    ShippingMethod.Sicepat: 12.00,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductDetailArguments) {
      _args = args;
    } else {
      print("[Checkout] Error: Argumen tidak ditemukan.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Gagal memuat data produk.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

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
              _userAddress = userData['address'] ?? _defaultAddressMessage;
            });
          }
        } else {
          throw Exception('Data user tidak ditemukan.');
        }
      } else {
        throw Exception('User tidak login.');
      }
    } catch (e) {
      print("[Checkout] Error loading user data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data user: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _userName = "Error";
          _userEmail = "Error";
        });
      }
    }
    
    if (mounted) setState(() => _isLoadingData = false);
  }

  Future<void> _placeOrder() async {
    // Validasi alamat
    if (_userAddress == _defaultAddressMessage || _userAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alamat pengiriman belum diatur! Harap atur di tab Store.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isPlacingOrder || _args == null || _selectedShipping == null || _selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi pilihan pengiriman dan pembayaran.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // --- CEK BIOMETRIK ---
    print('[CheckoutScreen] ===== MULAI CEK BIOMETRIK =====');
    
    try {
      final biometricEnabled = await BiometricService.isEnabled();
      print('[CheckoutScreen] Biometrik enabled: $biometricEnabled');
      
      if (biometricEnabled) {
        print('[CheckoutScreen] Biometrik AKTIF, meminta autentikasi...');
        
        // Tampilkan dialog loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final bool authenticated = await BiometricService.authenticate(
          reason: 'Verifikasi untuk menyelesaikan pembayaran',
          allowSkip: true,
        );
        
        // Tutup dialog loading
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        
        print('[CheckoutScreen] Hasil autentikasi: $authenticated');
        
        if (!authenticated) {
          print('[CheckoutScreen] Autentikasi GAGAL');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pembayaran dibatalkan'),
                backgroundColor: Colors.orangeAccent,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        
        print('[CheckoutScreen] Autentikasi BERHASIL');
      } else {
        print('[CheckoutScreen] Biometrik TIDAK AKTIF, skip');
      }
    } catch (e) {
      print('[CheckoutScreen] ERROR saat cek biometrik: $e');
      // Lanjut ke proses order jika error
    }
    
    print('[CheckoutScreen] ===== LANJUT KE PROSES ORDER =====');
    // --- AKHIR CEK BIOMETRIK ---

    if (mounted) setState(() => _isPlacingOrder = true);
    print("[Checkout] Memproses pesanan...");

    try {
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
        'shippingAddress': _userAddress,
        'customerName': _userName,
      };

      final ordersBox = Hive.box('orders');
      final currentUserEmail = Hive.box('users').get('currentUserEmail');
      
      final List<dynamic> userOrders = List.from(ordersBox.get(currentUserEmail) ?? []);
      userOrders.insert(0, orderData);
      
      await ordersBox.put(currentUserEmail, userOrders);
      print("[Checkout] Pesanan berhasil disimpan untuk $currentUserEmail");

      await Future.delayed(const Duration(seconds: 2));

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pesanan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  String _formatPrice(double price, String currencyCode, Map<String, dynamic> rates) {
    if (!rates.containsKey(currencyCode)) return "N/A";
    final rate = (rates[currencyCode] as num?)?.toDouble() ?? 1.0;
    final convertedPrice = price * rate;
    
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

    final product = _args!.product;
    final rates = _args!.rates;
    final currency = _args!.initialCurrency;

    final priceGBP = product['priceGBP'] as double;
    final shippingCostGBP = _shippingCosts[_selectedShipping] ?? 0.0;
    final totalGBP = priceGBP + shippingCostGBP;

    final priceConverted = _formatPrice(priceGBP, currency, rates);
    final totalConverted = _formatPrice(totalGBP, currency, rates);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembayaran'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
                      product['imagePath'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 80,
                        height: 80,
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Harga Produk',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        ),
                        Text(
                          priceConverted,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildSectionTitle(theme, 'Alamat Pengiriman'),
          Card(
            child: ListTile(
              leading: Icon(Icons.home_outlined, color: theme.colorScheme.primary),
              title: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                "$_userEmail\n$_userAddress",
                style: TextStyle(color: theme.colorScheme.outline, height: 1.4),
              ),
              isThreeLine: true,
            ),
          ),

          _buildSectionTitle(theme, 'Jasa Pengiriman'),
          Card(
            child: Column(
              children: [
                RadioListTile<ShippingMethod>(
                  title: const Text('JNE Reguler'),
                  subtitle: Text(
                    'Estimasi 2-3 hari kerja - ${_formatPrice(_shippingCosts[ShippingMethod.JNE]!, currency, rates)}',
                  ),
                  value: ShippingMethod.JNE,
                  groupValue: _selectedShipping,
                  onChanged: (ShippingMethod? value) {
                    setState(() {
                      _selectedShipping = value;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<ShippingMethod>(
                  title: const Text('Sicepat BEST'),
                  subtitle: Text(
                    'Estimasi 1-2 hari kerja - ${_formatPrice(_shippingCosts[ShippingMethod.Sicepat]!, currency, rates)}',
                  ),
                  value: ShippingMethod.Sicepat,
                  groupValue: _selectedShipping,
                  onChanged: (ShippingMethod? value) {
                    setState(() {
                      _selectedShipping = value;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

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
                    setState(() {
                      _selectedPayment = value;
                    });
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
                    setState(() {
                      _selectedPayment = value;
                    });
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
                    setState(() {
                      _selectedPayment = value;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Pembayaran:',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                ),
                Text(
                  totalConverted,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isPlacingOrder ? null : _placeOrder,
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lanjut Bayar'),
            ),
          ],
        ),
      ),
    );
  }

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