/**
 * File: arcade_screen.dart
 * Deskripsi: Halaman tab "Arcade" yang berisi game balapan sederhana.
 *
 * UPDATE:
 * - Menambahkan fitur Daily Mission dengan Rank dan High Score (via Hive).
 * - UPDATE 2: Memindahkan Daily Mission Card ke dalam dialog (pop-up)
 * yang dipicu oleh IconButton baru di AppBar agar tidak menutupi game.
 */

import 'dart:async'; // Untuk Timer
import 'dart:math'; // Untuk Random
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Untuk suara
import 'package:vibration/vibration.dart'; // Untuk getaran

// Import Hive
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

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
  final String _crashSoundPath = 'audio/crash.mp3';
  final String _musicPath = 'audio/audi_sound.mp3';

  // --- STATE DAILY MISSION ---
  int _todayHighScore = 0; // Skor tertinggi hari ini
  int _allTimeHighScore = 0; // Skor tertinggi sepanjang masa
  String _currentRank = "Rookie"; // Rank saat ini
  String _lastPlayedDate = ""; // Tanggal terakhir main

  // Rank system
  final Map<String, int> _rankThresholds = {
    "Rookie": 0,
    "Beginner": 50,
    "Amateur": 100,
    "Pro": 200,
    "Expert": 350,
    "Master": 500,
    "Legend": 750,
  };


  @override
  void initState() {
    super.initState();
    _loadGameData(); // Load data dari Hive
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

  // --- FUNGSI LOAD/SAVE DATA (DAILY MISSION) ---

  Future<void> _loadGameData() async {
    try {
      final userBox = Hive.box('users');
      final currentUserEmail = userBox.get('currentUserEmail');
      
      if (currentUserEmail != null) {
        final userData = userBox.get(currentUserEmail) as Map?;
        if (userData != null) {
          final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          
          setState(() {
            _lastPlayedDate = userData['lastArcadeDate'] ?? '';
            _allTimeHighScore = userData['arcadeHighScore'] ?? 0;
            
            // Reset daily score jika hari berbeda
            if (_lastPlayedDate != today) {
              _todayHighScore = 0;
            } else {
              _todayHighScore = userData['arcadeDailyScore'] ?? 0;
            }
            
            _currentRank = _calculateRank(_todayHighScore);
          });
        }
      }
    } catch (e) {
      print('[Arcade] Error loading game data: $e');
    }
  }

  String _calculateRank(int score) {
    String rank = "Rookie";
    _rankThresholds.forEach((key, value) {
      if (score >= value) rank = key;
    });
    return rank;
  }

  Future<void> _saveGameData(int finalScore) async {
    try {
      final userBox = Hive.box('users');
      final currentUserEmail = userBox.get('currentUserEmail');
      
      if (currentUserEmail != null) {
        final userData = Map<dynamic, dynamic>.from(userBox.get(currentUserEmail) ?? {});
        final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        // Update daily score jika lebih tinggi
        int currentDailyScore = userData['arcadeDailyScore'] ?? 0;
        // Cek juga tanggal terakhir main dari state
        if (_lastPlayedDate != today) currentDailyScore = 0;
        
        if (finalScore > currentDailyScore) {
          userData['arcadeDailyScore'] = finalScore;
          _todayHighScore = finalScore;
        } else {
          // Jika skor baru tidak lebih tinggi, pastikan _todayHighScore
          // tetap mencerminkan skor tertinggi hari ini
          _todayHighScore = currentDailyScore;
        }
        
        // Update all-time high score
        int currentHighScore = userData['arcadeHighScore'] ?? 0;
        if (finalScore > currentHighScore) {
          userData['arcadeHighScore'] = finalScore;
          _allTimeHighScore = finalScore;
        } else {
          // Pastikan _allTimeHighScore tetap yang tertinggi
          _allTimeHighScore = currentHighScore;
        }
        
        userData['lastArcadeDate'] = today;
        await userBox.put(currentUserEmail, userData);
        
        // Update UI state setelah save
        setState(() {
          _currentRank = _calculateRank(_todayHighScore);
          _lastPlayedDate = today;
        });
      }
    } catch (e) {
      print('[Arcade] Error saving game data: $e');
    }
  }

  // --- FUNGSI KONTROL GAME ---

  void _startGame() {
    if (_gameStatus == GameStatus.playing) return;
    print("[ArcadeScreen] Starting game...");

    _resetGame(keepStatus: false);

    setState(() {
      _gameStatus = GameStatus.playing;
      _frameCount = 0;
      _gameSpeed = 5.0;
    });

    _playMusic();

    _gameTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (_gameStatus != GameStatus.playing) {
        timer.cancel();
        return;
      }
      _updateGame();
    });
  }

  void _gameOver() {
    print("[ArcadeScreen] Game Over! Score: $_score");
    _gameTimer?.cancel();
    _stopMusic();
    _playCrashSound();
    _vibrate();
    
    // SAVE GAME DATA
    _saveGameData(_score); // Fungsi ini akan update state (skor, rank)

    if (mounted) {
      setState(() {
        _gameStatus = GameStatus.gameOver;
      });
    }
  }

  void _resetGame({bool keepStatus = true}) {
      print("[ArcadeScreen] Resetting game...");
      _gameTimer?.cancel();
      _stopMusic();

    if (mounted) {
      setState(() {
        if (!keepStatus) _gameStatus = GameStatus.ready;
        _score = 0;
        _playerX = 0.0;
        _obstacles.clear();
      });
      // Selalu load data terbaru saat reset
      // agar rank di dialog/card terupdate
      _loadGameData();
    }
  }

  void _updateGame() {
    if (!mounted) return;

    _frameCount++;

    // --- 1. Update Posisi Musuh ---
    List<Map<String, double>> obstaclesToRemove = [];
    for (var obstacle in _obstacles) {
      obstacle['y'] = (obstacle['y'] ?? 0) + _gameSpeed;
      if (obstacle['y']! > _gameAreaHeight) {
        obstaclesToRemove.add(obstacle);
        setState(() {
          _score += 10;
        });
      }
    }
    _obstacles.removeWhere((obs) => obstaclesToRemove.contains(obs));

    // --- 2. Spawn Musuh Baru ---
    if (_frameCount % _obstacleFrequency == 0) {
      double randomX = (_random.nextDouble() * 2.0) - 1.0;
      _obstacles.add({
        'x': randomX,
        'y': -_obstacleWidth,
        'type': _random.nextInt(3).toDouble(),
      });
    }

    // --- 3. Deteksi Tabrakan ---
    _checkCollisions();

    // --- 4. Tingkatkan Kesulitan (Opsional) ---
    if (_score > 0 && _score % 100 == 0) {
      _gameSpeed += 0.2;
      print("[ArcadeScreen] Level Up! Speed: $_gameSpeed");
    }

    setState(() {});
  }

  void _checkCollisions() {
    if (_gameAreaHeight == 0.0) return;

    double playerLeft = (_gameAreaWidth / 2) + (_playerX * (_gameAreaWidth / 2.5)) - (_playerWidth / 2);
    double playerRight = playerLeft + _playerWidth;
    double playerTop = _gameAreaHeight - _playerBottomOffset - _playerWidth;
    double playerBottom = _gameAreaHeight - _playerBottomOffset;

    for (var obstacle in _obstacles) {
      double obstacleLeft = (_gameAreaWidth / 2) + (obstacle['x']! * (_gameAreaWidth / 2.5)) - (_obstacleWidth / 2);
      double obstacleRight = obstacleLeft + _obstacleWidth;
      double obstacleTop = obstacle['y']!;
      double obstacleBottom = obstacleTop + _obstacleWidth;

      if (playerLeft < obstacleRight &&
          playerRight > obstacleLeft &&
          playerTop < obstacleBottom &&
          playerBottom > obstacleTop) {
        _gameOver();
        break;
      }
    }
  }

  // --- FUNGSI KONTROL PEMAIN ---
  void _movePlayer(double direction) {
    if (_gameStatus != GameStatus.playing) return;
    setState(() {
      _playerX += direction;
      _playerX = _playerX.clamp(-1.0, 1.0);
    });
  }

    // --- FUNGSI AUDIO & GETAR ---
  Future<void> _playCrashSound() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 200);
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
        await _musicPlayer.resume();
      } catch (e) {
        print("[ArcadeScreen] Error playing music: $e. Pastikan file '$_musicPath' ada di assets/audio/.");
        try {
          await _musicPlayer.play(AssetSource(_musicPath));
        } catch (e2) {
          print("[ArcadeScreen] Error playing music (fallback): $e2");
        }
      }
    }

    Future<void> _stopMusic() async {
      try {
        await _musicPlayer.pause();
        await _musicPlayer.seek(Duration.zero);
      } catch (e) {
        print("[ArcadeScreen] Error stopping music: $e");
      }
    }


  // --- UI BUILD METHOD ---
  // --- UPDATE: build() method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Williams Arcade'),
        centerTitle: true,
        actions: [
          // --- BARU: IconButton untuk Daily Mission ---
          IconButton(
            icon: const Icon(Icons.military_tech_outlined), // Ikon medali/rank
            onPressed: _showDailyMissionDialog, // Panggil dialog
            tooltip: 'Lihat Misi Harian',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetGame(keepStatus: false),
            tooltip: 'Mulai Ulang Game',
          )
        ],
      ),
      body: Column(
        children: [
          // --- KARTU MISI HARIAN DIHAPUS DARI SINI ---
          // _buildDailyMissionCard(Theme.of(context)), // <-- DIHAPUS
          
          // 1. Tampilan Skor (tetap)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHigh,
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

          // 2. Game Area (tetap)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _gameAreaWidth = constraints.maxWidth;
                _gameAreaHeight = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildRoadBackground(),
                    _buildPlayer(),
                    ..._buildObstacles(),
                    _buildOverlay(),
                  ],
                );
              },
            ),
          ),

          // 3. Tombol Kontrol (tetap)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _movePlayer(-0.1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.arrow_back, size: 30),
                ),
                ElevatedButton(
                  onPressed: () => _movePlayer(0.1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
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
          Align(
            alignment: const Alignment(-0.3, 0),
            child: Container(width: 5, color: Colors.grey[600]),
          ),
            Align(
            alignment: const Alignment(0.3, 0),
            child: Container(width: 5, color: Colors.grey[600]),
          ),
            Align(
            alignment: Alignment.centerLeft,
            child: Container(width: _gameAreaWidth * 0.15, color: Colors.green[800]),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(width: _gameAreaWidth * 0.15, color: Colors.green[800]),
          ),
        ],
      ),
    );
  }


  /**
    * Membangun widget Pemain.
    */
  Widget _buildPlayer() {
    if (_gameAreaWidth == 0.0) return const SizedBox.shrink();

    double playerLeftPosition = (_gameAreaWidth / 2) +
                            (_playerX * (_gameAreaWidth / 2.5)) -
                            (_playerWidth / 2);

    return Positioned(
      bottom: _playerBottomOffset,
      left: playerLeftPosition,
      child: Container(
        width: _playerWidth,
        height: _playerWidth,
        child: Icon(
          Icons.directions_car,
          color: Theme.of(context).colorScheme.primary,
          size: _playerWidth,
        ),
      ),
    );
  }

  /**
    * Membangun list widget Musuh/Rintangan.
    */
  List<Widget> _buildObstacles() {
      if (_gameAreaWidth == 0.0) return [];

      List<Widget> obstacleWidgets = [];
      for (var obstacle in _obstacles) {
        double obstacleLeftPosition = (_gameAreaWidth / 2) +
                                      (obstacle['x']! * (_gameAreaWidth / 2.5)) -
                                      (_obstacleWidth / 2);
        int type = obstacle['type']?.toInt() ?? 0;
        Color obstacleColor = Colors.red[400]!;
        IconData obstacleIcon = Icons.directions_car_filled;
        if (type == 1) {
            obstacleColor = Colors.blueGrey[400]!;
            obstacleIcon = Icons.local_taxi;
        } else if (type == 2) {
            obstacleColor = Colors.orange[400]!;
            obstacleIcon = Icons.airport_shuttle;
        }

        obstacleWidgets.add(
          Positioned(
            top: obstacle['y'],
            left: obstacleLeftPosition,
            child: Container(
              width: _obstacleWidth,
              height: _obstacleWidth,
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
    if (_gameStatus == GameStatus.playing) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.6),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          if (_gameStatus == GameStatus.gameOver)
              Text(
              'Skor Akhir: $_score',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
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


  // --- FUNGSI BARU: Menampilkan Dialog Misi Harian ---
  void _showDailyMissionDialog() {
    // Panggil _loadGameData setiap kali dialog dibuka
    // untuk memastikan data rank dan skor adalah yang terbaru.
    _loadGameData().then((_) {
      // Tampilkan dialog HANYA setelah data terbaru dimuat
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Misi Harian & Peringkat'),
          // Gunakan _buildDailyMissionCard sebagai konten dialog
          // Kita butuh Builder agar bisa dapat Theme baru di dalam dialog
          content: Builder(
            builder: (context) {
              return _buildDailyMissionCard(Theme.of(context));
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            )
          ],
        ),
      );
    });
  }


  // --- Widget untuk Daily Mission Card (sekarang dipanggil dialog) ---
  Widget _buildDailyMissionCard(ThemeData theme) {
    // Cari next rank
    String nextRank = "Legend";
    int nextThreshold = 1000;
    bool isMaxRank = false;
    
    // Perbarui rank berdasarkan state terbaru
    final currentRank = _calculateRank(_todayHighScore);
    
    _rankThresholds.forEach((key, value) {
      if (value > _todayHighScore && value < nextThreshold) {
        nextRank = key;
        nextThreshold = value;
      }
    });
    
    if (currentRank == "Legend") {
      isMaxRank = true;
      nextRank = "Legend";
      nextThreshold = _rankThresholds["Legend"]!;
    }
    
    int pointsNeeded = nextThreshold - _todayHighScore;
    double progress = isMaxRank ? 1.0 : (_todayHighScore / nextThreshold).clamp(0.0, 1.0);
    
    // Gunakan SizedBox untuk membatasi lebar card di dalam dialog
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8, // Lebar 80% layar
      child: Column( // Ganti Card menjadi Column
        mainAxisSize: MainAxisSize.min, // Agar dialog pas
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peringkat Harian', // Judul lebih jelas
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  currentRank.toUpperCase(), // Gunakan rank yang baru dihitung
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMaxRank ? 'MAX RANK!' : 'Next: $nextRank',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    isMaxRank 
                        ? '🏆 Champion'
                        : '$pointsNeeded poin lagi',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  icon: Icons.today,
                  label: 'Hari Ini',
                  value: _todayHighScore.toString(),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  icon: Icons.emoji_events,
                  label: 'Terbaik',
                  value: _allTimeHighScore.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.outline,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}