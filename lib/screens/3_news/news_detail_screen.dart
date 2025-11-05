/**
 * File: news_detail_screen.dart
 * Deskripsi: Halaman untuk menampilkan detail lengkap dari satu artikel berita.
 * Menerima data artikel (Map) melalui argumen navigasi.
 */

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({super.key});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  // --- 1. FUNGSI UNTUK MEMBUKA URL ---
  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      print('[NewsDetail] Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka link: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil argumen (data artikel) yang dikirim dari NewsScreen
    final Map<String, dynamic>? article =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Tema
    final theme = Theme.of(context);

    // Handle jika argumen null (seharusnya tidak terjadi jika navigasi benar)
    if (article == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Gagal memuat artikel.")),
      );
    }

    // Ekstrak data dari Map
    final String title = article['title'] ?? 'Tanpa Judul';
    final String imagePath =
        article['imagePath'] ?? 'assets/images/placeholder.png';
    final String source = article['source'] ?? 'Tidak diketahui';
    final String date = article['date'] ?? '';
    final String? url = article['url'];
    final String content = article['content'] ??
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. \n\n'
        'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
        'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. \n\n'
        'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, '
        'totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.';

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          // --- AppBar yang bisa Collapse ---
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            iconTheme: theme.appBarTheme.iconTheme,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                source,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              centerTitle: false,
              background: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black54,
                              Colors.transparent,
                              Colors.black54
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // --- Konten Artikel ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    date,
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    content,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.85),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // --- Tombol Baca Artikel Lengkap ---
      bottomNavigationBar: url != null
          ? Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _launchURL(url),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Baca Artikel Lengkap'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          : null,
    );
  }
}
