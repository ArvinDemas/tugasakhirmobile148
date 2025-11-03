/**
 * File: feedback_screen.dart
 * Deskripsi: Halaman untuk pengguna memberikan kesan dan pesan (feedback).
 * Data disimpan di Hive.
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feedbackController = TextEditingController();
  
  int _rating = 0; // Rating bintang (1-5)
  bool _isSubmitting = false;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // Load info user untuk auto-fill nama
  Future<void> _loadUserInfo() async {
    try {
      final userBox = Hive.box('users');
      _currentUserEmail = userBox.get('currentUserEmail');
      
      if (_currentUserEmail != null) {
        final userData = userBox.get(_currentUserEmail) as Map?;
        if (userData != null && mounted) {
          setState(() {
            _nameController.text = userData['username'] ?? '';
          });
        }
      }
    } catch (e) {
      print('[FeedbackScreen] Error loading user info: $e');
    }
  }

  // Submit feedback ke Hive
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon beri rating bintang terlebih dahulu'),
          backgroundColor: Colors.orangeAccent,
        )
      );
      return;
    }

    if (mounted) setState(() => _isSubmitting = true);

    try {
      // Buka atau buat Box 'feedbacks'
      final feedbackBox = await Hive.openBox('feedbacks');
      
      // Buat data feedback
      final feedbackData = {
        'name': _nameController.text.trim(),
        'email': _currentUserEmail ?? 'Anonymous',
        'rating': _rating,
        'message': _feedbackController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Simpan ke box dengan key timestamp (unik)
      await feedbackBox.add(feedbackData);
      
      print('[FeedbackScreen] Feedback submitted: $feedbackData');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih atas kesan & pesan Anda!'),
            backgroundColor: Colors.green,
          )
        );
        
        // Reset form
        _feedbackController.clear();
        setState(() {
          _rating = 0;
        });
      }
    } catch (e) {
      print('[FeedbackScreen] Error submitting feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim feedback: $e'),
            backgroundColor: Colors.redAccent,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesan & Pesan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        color: theme.colorScheme.primary,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bagikan Pengalaman Anda',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kesan dan pesan Anda sangat berarti untuk pengembangan aplikasi ini',
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Input Nama
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Anda',
                  hintText: 'Masukkan nama Anda',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Rating Bintang
              Text(
                'Beri Rating:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Input Pesan
              TextFormField(
                controller: _feedbackController,
                decoration: const InputDecoration(
                  labelText: 'Kesan & Pesan',
                  hintText: 'Tuliskan kesan dan pesan Anda di sini...',
                  prefixIcon: Icon(Icons.message_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pesan tidak boleh kosong';
                  }
                  if (value.trim().length < 10) {
                    return 'Pesan terlalu pendek (minimal 10 karakter)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Tombol Submit
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitFeedback,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Mengirim...' : 'Kirim Feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}