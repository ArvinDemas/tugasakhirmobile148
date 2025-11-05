/**
 * File: feedback_screen.dart - UPDATE
 * Deskripsi: Halaman feedback dengan fitur:
 * - Lihat list feedback yang sudah dikirim
 * - Edit feedback yang sudah ada
 * - Delete feedback
 */

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feedbackController = TextEditingController();
  
  int _rating = 0;
  bool _isSubmitting = false;
  String? _currentUserEmail;
  
  // STATE BARU untuk edit mode
  bool _isEditMode = false;
  int? _editingFeedbackKey; // Key Hive yang sedang di-edit
  
  // STATE untuk list feedback
  List<MapEntry<dynamic, dynamic>> _myFeedbacks = []; // List feedback user ini
  bool _isLoadingList = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadMyFeedbacks(); // Load feedback user
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  // Load info user
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

  // Load feedback milik user ini
  Future<void> _loadMyFeedbacks() async {
    if (mounted) setState(() => _isLoadingList = true);
    try {
      final feedbackBox = await Hive.openBox('feedbacks');
      
      if (_currentUserEmail != null) {
        // Filter feedback berdasarkan email user
        final allFeedbacks = feedbackBox.toMap().entries.toList();
        final myFeedbacks = allFeedbacks.where((entry) {
          final feedback = entry.value as Map;
          return feedback['email'] == _currentUserEmail;
        }).toList();
        
        // Urutkan berdasarkan timestamp (terbaru di atas)
        myFeedbacks.sort((a, b) {
          final timeA = (a.value as Map)['timestamp'] ?? '';
          final timeB = (b.value as Map)['timestamp'] ?? '';
          return timeB.compareTo(timeA);
        });
        
        if (mounted) {
          setState(() {
            _myFeedbacks = myFeedbacks;
          });
        }
      }
    } catch (e) {
      print('[FeedbackScreen] Error loading feedbacks: $e');
    } finally {
      if (mounted) setState(() => _isLoadingList = false);
    }
  }

  // Submit atau Update feedback
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
      final feedbackBox = await Hive.openBox('feedbacks');
      
      final feedbackData = {
        'name': _nameController.text.trim(),
        'email': _currentUserEmail ?? 'Anonymous',
        'rating': _rating,
        'message': _feedbackController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (_isEditMode && _editingFeedbackKey != null) {
        // UPDATE MODE
        await feedbackBox.put(_editingFeedbackKey, feedbackData);
        print('[FeedbackScreen] Feedback updated: $_editingFeedbackKey');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback berhasil diperbarui!'),
              backgroundColor: Colors.green,
            )
          );
        }
      } else {
        // ADD MODE
        await feedbackBox.add(feedbackData);
        print('[FeedbackScreen] Feedback submitted: $feedbackData');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terima kasih atas kesan & pesan Anda!'),
              backgroundColor: Colors.green,
            )
          );
        }
      }
      
      // Reset form & reload list
      _resetForm();
      _loadMyFeedbacks();
      
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

  // Edit feedback
  void _editFeedback(int key, Map feedback) {
    setState(() {
      _isEditMode = true;
      _editingFeedbackKey = key;
      _nameController.text = feedback['name'] ?? '';
      _feedbackController.text = feedback['message'] ?? '';
      _rating = feedback['rating'] ?? 0;
    });
    
    // Scroll ke atas (ke form)
    // Bisa tambahkan ScrollController jika perlu
  }

  // Delete feedback
  Future<void> _deleteFeedback(int key) async {
    // Konfirmasi dulu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Feedback?'),
        content: const Text('Apakah Anda yakin ingin menghapus feedback ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      final feedbackBox = await Hive.openBox('feedbacks');
      await feedbackBox.delete(key);
      
      print('[FeedbackScreen] Feedback deleted: $key');
      _loadMyFeedbacks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback berhasil dihapus'),
            backgroundColor: Colors.orange,
          )
        );
      }
    } catch (e) {
      print('[FeedbackScreen] Error deleting feedback: $e');
    }
  }

  // Reset form ke mode tambah baru
  void _resetForm() {
    setState(() {
      _isEditMode = false;
      _editingFeedbackKey = null;
      _nameController.text = _currentUserEmail != null 
          ? (Hive.box('users').get(_currentUserEmail) as Map?)?.values.first ?? ''
          : '';
      _feedbackController.clear();
      _rating = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kesan & Pesan'),
        centerTitle: true,
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _resetForm,
              tooltip: 'Batal Edit',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FORM INPUT (EDIT/ADD)
            _buildFeedbackForm(theme),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // LIST FEEDBACK SAYA
            _buildMyFeedbacksList(theme),
          ],
        ),
      ),
    );
  }

  // Widget Form Input
  Widget _buildFeedbackForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit : Icons.feedback_outlined,
                    color: theme.colorScheme.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isEditMode ? 'Edit Feedback' : 'Bagikan Pengalaman Anda',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditMode 
                        ? 'Perbarui kesan dan pesan Anda'
                        : 'Kesan dan pesan Anda sangat berarti untuk pengembangan aplikasi ini',
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

          // Tombol Submit/Update
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
                : Icon(_isEditMode ? Icons.save : Icons.send),
            label: Text(_isSubmitting 
                ? 'Menyimpan...' 
                : (_isEditMode ? 'Update Feedback' : 'Kirim Feedback')),
          ),
          
          // Tombol Batal (hanya muncul saat edit)
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.close),
                label: const Text('Batal Edit'),
              ),
            ),
        ],
      ),
    );
  }

  // Widget List Feedback Saya
  Widget _buildMyFeedbacksList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Feedback Saya',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_myFeedbacks.isNotEmpty)
              Text(
                '${_myFeedbacks.length} feedback',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingList)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_myFeedbacks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum Ada Feedback',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Feedback yang Anda kirim akan muncul di sini',
                    style: TextStyle(color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myFeedbacks.length,
            itemBuilder: (context, index) {
              final entry = _myFeedbacks[index];
              final key = entry.key;
              final feedback = entry.value as Map;
              return _buildFeedbackCard(theme, key, feedback);
            },
          ),
      ],
    );
  }

  // Widget Card Feedback
  Widget _buildFeedbackCard(ThemeData theme, int key, Map feedback) {
    final String name = feedback['name'] ?? 'Anonymous';
    final int rating = feedback['rating'] ?? 0;
    final String message = feedback['message'] ?? '';
    final String timestamp = feedback['timestamp'] ?? '';
    
    String formattedDate = '';
    if (timestamp.isNotEmpty) {
      try {
        final date = DateTime.parse(timestamp);
        formattedDate = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date);
      } catch (e) {
        formattedDate = timestamp;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Name + Rating)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: index < rating ? Colors.amber : Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Tanggal
            Text(
              formattedDate,
              style: TextStyle(
                color: theme.colorScheme.outline,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            
            // Pesan
            Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tombol Edit & Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editFeedback(key, feedback),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteFeedback(key),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}