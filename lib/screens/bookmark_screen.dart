/**
 * File: bookmark_screen.dart
 * Deskripsi: Halaman untuk menampilkan daftar produk yang di-bookmark (favorit).
 * Data disimpan di Hive per user.
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<dynamic> _bookmarkedProducts = [];
  bool _isLoading = true;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  // Load daftar bookmark dari Hive
  Future<void> _loadBookmarks() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final userBox = Hive.box('users');
      _currentUserEmail = userBox.get('currentUserEmail');
      
      if (_currentUserEmail != null) {
        final userData = userBox.get(_currentUserEmail) as Map?;
        if (userData != null && userData.containsKey('bookmarks')) {
          if (mounted) {
            setState(() {
              _bookmarkedProducts = List.from(userData['bookmarks'] ?? []);
            });
          }
        }
      }
    } catch (e) {
      print('[BookmarkScreen] Error loading bookmarks: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat favorit: $e'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hapus produk dari bookmark
  Future<void> _removeBookmark(int productId) async {
    if (_currentUserEmail == null) return;
    
    try {
      final userBox = Hive.box('users');
      final userData = Map<dynamic, dynamic>.from(userBox.get(_currentUserEmail) ?? {});
      
      List<dynamic> bookmarks = List.from(userData['bookmarks'] ?? []);
      bookmarks.removeWhere((product) => product['id'] == productId);
      
      userData['bookmarks'] = bookmarks;
      await userBox.put(_currentUserEmail!, userData);
      
      print('[BookmarkScreen] Product $productId removed from bookmarks');
      _loadBookmarks(); // Refresh list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dihapus dari favorit'), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      print('[BookmarkScreen] Error removing bookmark: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Favorit'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _bookmarkedProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline, size: 80, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('Belum Ada Favorit', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Tap ikon bookmark di produk Store untuk menambahkan ke favorit',
                        style: TextStyle(color: theme.colorScheme.outline),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _bookmarkedProducts.length,
                  itemBuilder: (context, index) {
                    final product = _bookmarkedProducts[index];
                    return _buildBookmarkCard(theme, product);
                  },
                ),
    );
  }

  // Widget card untuk setiap produk bookmark
  Widget _buildBookmarkCard(ThemeData theme, Map<dynamic, dynamic> product) {
    final String name = product['name'] ?? 'Produk';
    final String imagePath = product['imagePath'] ?? 'assets/images/placeholder.png';
    final double priceGBP = (product['priceGBP'] as num?)?.toDouble() ?? 0.0;
    final int productId = product['id'] ?? 0;

    final formattedPrice = NumberFormat.currency(
      symbol: '£',
      decimalDigits: 2,
      locale: 'en_GB',
    ).format(priceGBP);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // TODO: Navigasi ke detail produk (jika diperlukan)
          print('[BookmarkScreen] Product $name tapped');
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
                  imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 100,
                    height: 100,
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
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
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedPrice,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol Hapus
              IconButton(
                icon: const Icon(Icons.bookmark, color: Colors.amber),
                onPressed: () => _removeBookmark(productId),
                tooltip: 'Hapus dari Favorit',
              ),
            ],
          ),
        ),
      ),
    );
  }
}