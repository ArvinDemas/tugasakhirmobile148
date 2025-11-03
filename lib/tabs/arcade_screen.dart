/**
 * File: arcade_screen.dart
 * Deskripsi: Halaman tab "Arcade" yang berisi game balapan sederhana.
 * Dibuat menggunakan widget Flutter standar (StatefulWidget, Timer, Stack, Positioned).
 */

import 'dart:async'; // Untuk Timer
import 'dart:math'; // Untuk Random
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Untuk suara
import 'package:vibration/vibration.dart'; // Untuk getaran

// Enum untuk status game
enum GameStatus { ready, playing, gameOver }

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  // --- STATE GAME ---
  GameStatus _gameStatus = GameStatus.ready; // Status game saat ini
  int _score = 0; // Skor pemain
  double _playerX = 0.0; // Posisi horizontal pemain (-1.0 kiri, 0.0 tengah, 1.0 kanan)
  final List<Map<String, double>> _obstacles = []; // List musuh/rintangan
  Timer? _gameTimer; // Timer untuk game loop
  final Random _random = Random(); // Untuk posisi musuh
  double _gameSpeed = 5.0; // Kecepatan awal musuh
  int _obstacleFrequency = 20; // Frekuensi kemunculan musuh (lebih kecil = lebih sering)
  int _frameCount = 0; // Counter untuk spawn musuh

  // --- UKURAN GAME AREA (didapat dari LayoutBuilder) ---
  double _gameAreaWidth = 0.0;
  double _gameAreaHeight = 0.0;
  final double _playerWidth = 50.0; // Lebar pemain (untuk deteksi tabrakan)
  final double _obstacleWidth = 50.0; // Lebar musuh (untuk deteksi tabrakan)
  final double _playerBottomOffset = 30.0; // Jarak pemain dari bawah

  // --- AUDIO ---
  final AudioPlayer _audioPlayer = AudioPlayer(); // Player untuk SFX
  final AudioPlayer _musicPlayer = AudioPlayer(); // Player untuk BGM
  // Path asset suara (pastikan file ada di assets/audio/)
  final String _crashSoundPath = 'audio/crash.mp3'; // TODO: Ganti nama file jika beda
  final String _musicPath = 'audio/audi_sound.mp3'; // TODO: Ganti nama file jika beda

  @override
  void initState() {
    super.initState();
    // Set mode BGM agar loop
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    // Pre-load BGM (opsional tapi bagus)
    _preloadMusic();
  }

  Future<void> _preloadMusic() async {
     try {
       await _musicPlayer.setSource(AssetSource(_musicPath));
       print("[ArcadeScreen] Music preloaded.");
     } catch (e) {
       print("[ArcadeScreen] Error preloading music: $e");
     }
  }


  @override
  void dispose() {
    _gameTimer?.cancel(); // Hentikan game loop
    _audioPlayer.dispose(); // Hentikan SFX player
    _musicPlayer.dispose(); // Hentikan BGM player
    super.dispose();
  }

  // --- FUNGSI KONTROL GAME ---

  /**
   * Memulai Game Loop
   */
  void _startGame() {
    if (_gameStatus == GameStatus.playing) return; // Jangan mulai jika sudah jalan
    print("[ArcadeScreen] Starting game...");

    // Reset game ke kondisi awal
    _resetGame(keepStatus: false);

    setState(() {
      _gameStatus = GameStatus.playing; // Set status ke playing
      _frameCount = 0; // Reset frame count
      _gameSpeed = 5.0; // Reset speed
    });

    // Mulai BGM
    _playMusic();

    // Mulai Game Timer (Game Loop)
    // Berjalan setiap 33ms (sekitar 30 FPS)
    _gameTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (_gameStatus != GameStatus.playing) {
        timer.cancel(); // Hentikan jika game over
        return;
      }
      _updateGame(); // Panggil fungsi update
    });
  }

  /**
   * Menghentikan Game (Game Over)
   */
  void _gameOver() {
    print("[ArcadeScreen] Game Over! Score: $_score");
    _gameTimer?.cancel(); // Hentikan game loop
    _stopMusic(); // Hentikan BGM
    _playCrashSound(); // Mainkan suara tabrakan
    _vibrate(); // Getarkan HP

    if (mounted) {
      setState(() {
        _gameStatus = GameStatus.gameOver; // Set status game over
      });
    }
  }

   /**
   * Reset game state ke awal
   */
  void _resetGame({bool keepStatus = true}) {
     print("[ArcadeScreen] Resetting game...");
     _gameTimer?.cancel(); // Hentikan timer (jika ada)
     _stopMusic(); // Hentikan musik

    if (mounted) {
      setState(() {
        if (!keepStatus) _gameStatus = GameStatus.ready; // Kembali ke ready jika diminta
        _score = 0; // Reset skor
        _playerX = 0.0; // Reset posisi pemain
        _obstacles.clear(); // Kosongkan list musuh
      });
    }
  }

  /**
   * Fungsi Game Loop Utama (dipanggil oleh Timer)
   */
  void _updateGame() {
    if (!mounted) return; // Cek jika widget masih ada

    _frameCount++; // Tambah frame count

    // --- 1. Update Posisi Musuh ---
    // List untuk musuh yang akan dihapus (karena keluar layar)
    List<Map<String, double>> obstaclesToRemove = [];
    for (var obstacle in _obstacles) {
      // Pindahkan musuh ke bawah
      obstacle['y'] = (obstacle['y'] ?? 0) + _gameSpeed;
      // Cek jika musuh keluar layar
      if (obstacle['y']! > _gameAreaHeight) {
        obstaclesToRemove.add(obstacle);
        // Tambah skor jika berhasil menghindari
        setState(() {
          _score += 10;
        });
      }
    }
    // Hapus musuh yang sudah keluar layar
    _obstacles.removeWhere((obs) => obstaclesToRemove.contains(obs));

    // --- 2. Spawn Musuh Baru ---
    // Spawn musuh baru setiap _obstacleFrequency frame
    if (_frameCount % _obstacleFrequency == 0) {
      // Posisi horizontal acak (-1.0 sampai 1.0)
      double randomX = (_random.nextDouble() * 2.0) - 1.0;
      _obstacles.add({
        'x': randomX, // Posisi X
        'y': -_obstacleWidth, // Posisi Y (mulai dari atas layar)
        'type': _random.nextInt(3).toDouble(), // Tipe musuh (untuk ganti ikon/warna)
      });
    }

    // --- 3. Deteksi Tabrakan ---
    _checkCollisions();

    // --- 4. Tingkatkan Kesulitan (Opsional) ---
    if (_score > 0 && _score % 100 == 0) {
      _gameSpeed += 0.2; // Tambah kecepatan
      if (_obstacleFrequency > 10) {
        // _obstacleFrequency -= 1; // Musuh lebih sering muncul
      }
       print("[ArcadeScreen] Level Up! Speed: $_gameSpeed, Freq: $_obstacleFrequency");
    }

    // Update UI
    setState(() {});
  }

  /**
   * Cek Tabrakan Pemain vs Musuh
   */
  void _checkCollisions() {
    if (_gameAreaHeight == 0.0) return; // Jangan cek jika area belum diukur

    // Hitung area pemain (bounding box)
    // Konversi _playerX (-1 s/d 1) ke posisi pixel
    double playerLeft = (_gameAreaWidth / 2) + (_playerX * (_gameAreaWidth / 2.5)) - (_playerWidth / 2);
    double playerRight = playerLeft + _playerWidth;
    double playerTop = _gameAreaHeight - _playerBottomOffset - _playerWidth; // Asumsi player 50x50
    double playerBottom = _gameAreaHeight - _playerBottomOffset;

    for (var obstacle in _obstacles) {
      // Hitung area musuh
      double obstacleLeft = (_gameAreaWidth / 2) + (obstacle['x']! * (_gameAreaWidth / 2.5)) - (_obstacleWidth / 2);
      double obstacleRight = obstacleLeft + _obstacleWidth;
      double obstacleTop = obstacle['y']!;
      double obstacleBottom = obstacleTop + _obstacleWidth; // Asumsi musuh 50x50

      // Deteksi tabrakan AABB (Axis-Aligned Bounding Box)
      if (playerLeft < obstacleRight &&
          playerRight > obstacleLeft &&
          playerTop < obstacleBottom &&
          playerBottom > obstacleTop) {
        // --- TABRAKAN TERJADI ---
        _gameOver();
        break; // Hentikan loop
      }
    }
  }

  // --- FUNGSI KONTROL PEMAIN ---
  void _movePlayer(double direction) {
    if (_gameStatus != GameStatus.playing) return; // Hanya bisa gerak saat main
    setState(() {
      _playerX += direction;
      // Batasi gerakan pemain agar tidak keluar jalur (-1.0 s/d 1.0)
      _playerX = _playerX.clamp(-1.0, 1.0);
    });
  }

   // --- FUNGSI AUDIO & GETAR ---
  Future<void> _playCrashSound() async {
    try {
      // Cek apakah vibration didukung
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 200); // Getar 200ms
      }
    } catch (e) {
       print("[ArcadeScreen] Error vibrating: $e");
    }
    try {
      await _audioPlayer.play(AssetSource(_crashSoundPath));
    } catch (e) {
      print("[ArcadeScreen] Error playing crash sound: $e. Pastikan file '$_crashSoundPath' ada di assets/audio/.");
    }
  }

   Future<void> _vibrate() async {
     try {
       bool? hasVibrator = await Vibration.hasVibrator();
       if (hasVibrator == true) {
         Vibration.vibrate(duration: 200);
       }
     } catch (e) {
        print("[ArcadeScreen] Error vibrating: $e");
     }
   }

   Future<void> _playMusic() async {
     try {
       await _musicPlayer.resume(); // Lanjutkan musik jika di-pause
     } catch (e) {
       print("[ArcadeScreen] Error playing music: $e. Pastikan file '$_musicPath' ada di assets/audio/.");
       // Coba mainkan dari awal jika resume gagal
       try {
         await _musicPlayer.play(AssetSource(_musicPath));
       } catch (e2) {
          print("[ArcadeScreen] Error playing music (fallback): $e2");
       }
     }
   }

   Future<void> _stopMusic() async {
     try {
       await _musicPlayer.pause(); // Pause musik (agar bisa di-resume)
       await _musicPlayer.seek(Duration.zero); // Kembali ke awal
     } catch (e) {
       print("[ArcadeScreen] Error stopping music: $e");
     }
   }


  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // Scaffold dengan AppBar standar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Williams Arcade'),
        centerTitle: true,
        // Tombol reset/refresh di AppBar
        actions: [
           IconButton(
             icon: const Icon(Icons.refresh),
             onPressed: () => _resetGame(keepStatus: false), // Reset game
             tooltip: 'Mulai Ulang Game',
           )
        ],
      ),
      // Body utama game
      body: Column(
        children: [
          // 1. Tampilan Skor
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceVariant, // Warna background skor
            child: Text(
              'SKOR: $_score',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // 2. Game Area
          Expanded(
            // LayoutBuilder digunakan untuk mendapatkan ukuran pasti area game
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Simpan ukuran area game untuk kalkulasi
                _gameAreaWidth = constraints.maxWidth;
                _gameAreaHeight = constraints.maxHeight;
                // Stack untuk menumpuk jalan, pemain, musuh, dan overlay
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // --- Background Jalan ---
                    _buildRoadBackground(), // Jalan statis
                    _buildPlayer(), // Widget pemain
                    ..._buildObstacles(), // List widget musuh
                    // --- Overlay (Start/Game Over) ---
                    _buildOverlay(),
                  ],
                );
              },
            ),
          ),

          // 3. Tombol Kontrol
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            color: Theme.of(context).colorScheme.surface, // Warna background kontrol
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Kiri
                ElevatedButton(
                  onPressed: () => _movePlayer(-0.1), // Gerak ke kiri
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.arrow_back, size: 30),
                ),
                // Tombol Kanan
                ElevatedButton(
                  onPressed: () => _movePlayer(0.1), // Gerak ke kanan
                  style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.arrow_forward, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER UNTUK UI GAME ---

  /**
   * Membangun background jalan (statis).
   */
  Widget _buildRoadBackground() {
    return Container(
      color: Colors.grey[800], // Warna aspal
      child: Stack(
        children: [
          // Garis tengah (putus-putus bisa dibuat dengan Ticker/Animation,
          // tapi untuk simpel kita buat 2 garis solid)
          Align(
            alignment: const Alignment(-0.3, 0), // Garis kiri
            child: Container(width: 5, color: Colors.grey[600]),
          ),
           Align(
            alignment: const Alignment(0.3, 0), // Garis kanan
            child: Container(width: 5, color: Colors.grey[600]),
          ),
           // Rumput/Bahu Jalan
           Align(
            alignment: Alignment.centerLeft,
            child: Container(width: _gameAreaWidth * 0.15, color: Colors.green[800]), // Rumput kiri
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(width: _gameAreaWidth * 0.15, color: Colors.green[800]), // Rumput kanan
          ),
        ],
      ),
    );
  }


  /**
   * Membangun widget Pemain.
   */
  Widget _buildPlayer() {
    if (_gameAreaWidth == 0.0) return const SizedBox.shrink(); // Jangan render jika area 0

    // Kalkulasi posisi 'left' dari 'center' berdasarkan _playerX (-1 s/d 1)
    // (_gameAreaWidth / 2.5) adalah batas pergerakan (agar tidak terlalu mepet)
    double playerLeftPosition = (_gameAreaWidth / 2) + // Titik tengah
                              (_playerX * (_gameAreaWidth / 2.5)) - // Offset
                              (_playerWidth / 2); // Setengah lebar pemain

    // Positioned untuk menempatkan pemain di Stack
    return Positioned(
      bottom: _playerBottomOffset, // Jarak dari bawah
      left: playerLeftPosition, // Posisi horizontal
      // Tampilan pemain
      child: Container(
        width: _playerWidth,
        height: _playerWidth, // Asumsi pemain kotak
        // TODO: Ganti Icon dengan gambar mobil Williams (Image.asset)
        child: Icon(
          Icons.directions_car,
          color: Theme.of(context).colorScheme.primary, // Warna ungu (atau biru Williams)
          size: _playerWidth,
        ),
      ),
    );
  }

  /**
   * Membangun list widget Musuh/Rintangan.
   */
  List<Widget> _buildObstacles() {
     if (_gameAreaWidth == 0.0) return []; // Jangan render jika area 0

     List<Widget> obstacleWidgets = [];
     for (var obstacle in _obstacles) {
        // Kalkulasi posisi 'left' musuh
        double obstacleLeftPosition = (_gameAreaWidth / 2) +
                                    (obstacle['x']! * (_gameAreaWidth / 2.5)) -
                                    (_obstacleWidth / 2);
        // Tipe musuh (untuk ganti warna/ikon)
        int type = obstacle['type']?.toInt() ?? 0;
        Color obstacleColor = Colors.red[400]!; // Default
        IconData obstacleIcon = Icons.directions_car_filled; // Default
        if (type == 1) {
           obstacleColor = Colors.blueGrey[400]!;
           obstacleIcon = Icons.local_taxi;
        } else if (type == 2) {
           obstacleColor = Colors.orange[400]!;
           obstacleIcon = Icons.airport_shuttle;
        }

        obstacleWidgets.add(
          Positioned(
            top: obstacle['y'], // Posisi vertikal (dari atas)
            left: obstacleLeftPosition, // Posisi horizontal
            // Tampilan musuh
            child: Container(
              width: _obstacleWidth,
              height: _obstacleWidth,
              // TODO: Ganti Icon dengan gambar mobil musuh (Image.asset)
              child: Icon(
                obstacleIcon,
                color: obstacleColor,
                size: _obstacleWidth,
              ),
            ),
          ),
        );
     }
     return obstacleWidgets;
  }

  /**
   * Membangun Overlay (Tombol Start / Teks Game Over).
   */
  Widget _buildOverlay() {
    // Jika sedang bermain, jangan tampilkan overlay
    if (_gameStatus == GameStatus.playing) {
      return const SizedBox.shrink(); // Widget kosong
    }

    // Tampilkan overlay jika status 'ready' atau 'gameOver'
    return Container(
      // Background gelap transparan
      color: Colors.black.withOpacity(0.6),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ukuran sesuai konten
        children: [
          // Tampilkan teks "Game Over" jika status gameOver
          if (_gameStatus == GameStatus.gameOver)
            Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red[400],
                letterSpacing: 2.0,
              ),
            ),
          // Tampilkan skor akhir jika status gameOver
          if (_gameStatus == GameStatus.gameOver)
             Text(
              'Skor Akhir: $_score',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 24), // Jarak

          // Tombol Start (jika status 'ready') atau Mulai Lagi (jika 'gameOver')
          ElevatedButton(
            onPressed: _startGame, // Panggil _startGame saat ditekan
            style: ElevatedButton.styleFrom(
              // Gunakan warna aksen tema (ungu)
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            child: Text(
              _gameStatus == GameStatus.ready ? 'Mulai Game' : 'Mulai Lagi',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
