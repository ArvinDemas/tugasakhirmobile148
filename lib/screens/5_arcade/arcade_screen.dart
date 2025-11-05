/**
 * File: arcade_screen.dart
 * Deskripsi: Halaman tab "Arcade" yang berisi game balapan sederhana.
 *
 * UPDATE:
 * - Menambahkan fitur Daily Mission (di dialog AppBar).
 * - Menambahkan fitur Gyro Control (di dialog settings AppBar).
 * - Memperbaiki logika sensitivitas gyro (nilai tinggi = lebih responsif).
 * - (FIX) Menghapus state '_currentRank' yang tidak terpakai untuk menghilangkan warning.
 */

import 'dart:async'; // Untuk Timer
import 'dart:math'; // Untuk Random
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Untuk suara
import 'package:vibration/vibration.dart'; // Untuk getaran

// Import Hive
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

// Import Gyro
import 'package:sensors_plus/sensors_plus.dart';

// Enum untuk status game
enum GameStatus { ready, playing, gameOver }

class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  // --- STATE GAME ---
  GameStatus _gameStatus = GameStatus.ready;
  int _score = 0;
  double _playerX = 0.0;
  final List<Map<String, double>> _obstacles = [];
  Timer? _gameTimer;
  final Random _random = Random();
  double _gameSpeed = 5.0;
  int _obstacleFrequency = 20;
  int _frameCount = 0;

  // --- UKURAN GAME AREA ---
  double _gameAreaWidth = 0.0;
  double _gameAreaHeight = 0.0;
  final double _playerWidth = 50.0;
  final double _obstacleWidth = 50.0;
  final double _playerBottomOffset = 30.0;

  // --- AUDIO ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final String _crashSoundPath = 'audio/crash.mp3';
  final String _musicPath = 'audio/audi_sound.mp3';

  // --- STATE DAILY MISSION (FIXED) ---
  int _todayHighScore = 0;
  int _allTimeHighScore = 0;
  // String _currentRank = "Rookie"; // <-- HAPUS BARIS INI (Sesuai Solusi 1)
  String _lastPlayedDate = "";

  final Map<String, int> _rankThresholds = {
    "Rookie": 0, "Beginner": 50, "Amateur": 100, "Pro": 200,
    "Expert": 350, "Master": 500, "Legend": 750,
  };

  // --- STATE UNTUK GYRO CONTROL ---
  bool _isGyroControl = false;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  double _gyroSensitivity = 15.0; // Nilai tengah (5=Lambat, 30=Cepat)
  double _centerCalibration = 0.0;


  @override
  void initState() {
    super.initState();
    _loadGameData();
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
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
    _gameTimer?.cancel();
    _audioPlayer.dispose();
    _musicPlayer.dispose();
    _accelerometerSubscription?.cancel(); // Hentikan Gyro
    super.dispose();
  }

  // --- FUNGSI LOAD/SAVE DATA (DAILY MISSION) ---

  // _loadGameData() - FIXED
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
            
            if (_lastPlayedDate != today) {
              _todayHighScore = 0;
            } else {
              _todayHighScore = userData['arcadeDailyScore'] ?? 0;
            }
            
            // HAPUS: _currentRank = _calculateRank(_todayHighScore);

            // Muat juga setelan kontrol
            _isGyroControl = userData['arcadeUseGyro'] ?? false;
            _gyroSensitivity = (userData['arcadeGyroSens'] as num? ?? 15.0).toDouble();
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

  // _saveGameData() - FIXED
  Future<void> _saveGameData(int finalScore) async {
    try {
      final userBox = Hive.box('users');
      final currentUserEmail = userBox.get('currentUserEmail');
      
      if (currentUserEmail != null) {
        final userData = Map<dynamic, dynamic>.from(userBox.get(currentUserEmail) ?? {});
        final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        
        int currentDailyScore = userData['arcadeDailyScore'] ?? 0;
        if (_lastPlayedDate != today) currentDailyScore = 0;
        
        if (finalScore > currentDailyScore) {
          userData['arcadeDailyScore'] = finalScore;
          _todayHighScore = finalScore;
        } else {
          _todayHighScore = currentDailyScore;
        }
        
        int currentHighScore = userData['arcadeHighScore'] ?? 0;
        if (finalScore > currentHighScore) {
          userData['arcadeHighScore'] = finalScore;
          _allTimeHighScore = finalScore;
        } else {
          _allTimeHighScore = currentHighScore;
        }
        
        userData['lastArcadeDate'] = today;
        await userBox.put(currentUserEmail, userData);
        
        setState(() {
          // HAPUS: _currentRank = _calculateRank(_todayHighScore);
          _lastPlayedDate = today;
        });
      }
    } catch (e) {
      print('[Arcade] Error saving game data: $e');
    }
  }
  
  // Fungsi untuk menyimpan HANYA pengaturan
  Future<void> _saveControlSettings() async {
      try {
      final userBox = Hive.box('users');
      final currentUserEmail = userBox.get('currentUserEmail');
      
      if (currentUserEmail != null) {
        final userData = Map<dynamic, dynamic>.from(userBox.get(currentUserEmail) ?? {});
        
        userData['arcadeUseGyro'] = _isGyroControl;
        userData['arcadeGyroSens'] = _gyroSensitivity;
        
        await userBox.put(currentUserEmail, userData);
      }
      } catch (e) {
        print('[Arcade] Error saving control settings: $e');
      }
  }

  // --- FUNGSI KONTROL GAME & GYRO ---

  void _startGyroControl() {
    if (!_isGyroControl) return;
    
    _calibrateGyro();
    
    print('[Arcade] Starting gyro control...');
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (_gameStatus != GameStatus.playing) return;
        
        double tilt = event.x - _centerCalibration;
        
        // --- LOGIKA SENSITIVITAS DIPERBAIKI ---
        double maxDivider = 35.0; 
        double divider = maxDivider - _gyroSensitivity;
        double movement = (tilt / divider).clamp(-1.0, 1.0);
        // --- AKHIR PERBAIKAN ---

        if (mounted) {
          setState(() {
            _playerX = movement;
          });
        }
      },
      onError: (error) {
        print('[Arcade] Gyro error: $error');
      },
    );
  }

  void _stopGyroControl() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    print('[Arcade] Gyro control stopped.');
  }

  Future<void> _calibrateGyro() async {
    try {
      final event = await accelerometerEventStream().first
          .timeout(const Duration(seconds: 2));
      _centerCalibration = event.x;
      print('[Arcade] Gyro calibrated. Center: $_centerCalibration');
    } catch (e) {
      print('[Arcade] Calibration failed: $e');
      _centerCalibration = 0.0;
    }
  }

  void _startGame() {
    if (_gameStatus == GameStatus.playing) return;
    print("[ArcadeScreen] Starting game...");

    _resetGame(keepStatus: false);

    setState(() {
      _gameStatus = GameStatus.playing;
      _frameCount = 0;
      _gameSpeed = 5.0;
      _playerX = 0.0; // Reset posisi
    });

    _playMusic();
    
    if (_isGyroControl) {
      _startGyroControl();
    }

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
    _stopGyroControl(); // Hentikan gyro
    _playCrashSound();
    _vibrate();
    
    _saveGameData(_score); // Simpan skor

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
      _stopGyroControl(); // Hentikan gyro

    if (mounted) {
      setState(() {
        if (!keepStatus) _gameStatus = GameStatus.ready;
        _score = 0;
        _playerX = 0.0;
        _obstacles.clear();
      });
      _loadGameData(); // Muat ulang skor/rank
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

    // --- 4. Tingkatkan Kesulitan ---
    if (_score > 0 && _score % 100 == 0) {
      _gameSpeed += 0.2;
      print("[ArcadeScreen] Level Up! Speed: $_gameSpeed");
    }

    // Hanya panggil setState jika tidak pakai gyro (karena gyro punya setState sendiri)
    if (!_isGyroControl) {
      setState(() {});
    }
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

  // --- FUNGSI KONTROL PEMAIN (TOMBOL) ---
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Williams Arcade'),
        centerTitle: true,
        actions: [
          // Tombol Misi Harian
          IconButton(
            icon: const Icon(Icons.military_tech_outlined),
            onPressed: _showDailyMissionDialog,
            tooltip: 'Lihat Misi Harian',
          ),
          // Tombol Settings Kontrol
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showControlSettingsDialog, // Panggil dialog settings
            tooltip: 'Pengaturan Kontrol',
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
          
          // 1. Tampilan Skor
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

          // 2. Game Area
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

          // 3. Tombol Kontrol (HANYA MUNCUL JIKA MODE BUTTON)
          if (!_isGyroControl)
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
          
          // 4. INSTRUKSI GYRO (MUNCUL JIKA MODE GYRO)
          if (_isGyroControl)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              color: theme.colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.screen_rotation,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Miringkan HP ke kiri dan kanan',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER UNTUK UI GAME ---

  Widget _buildRoadBackground() {
    return Container(
      color: Colors.grey[800],
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
          
          if (_gameStatus == GameStatus.gameOver)
              const SizedBox(height: 24),

          // Tampilkan info mode hanya saat 'ready'
          if (_gameStatus == GameStatus.ready) ...[
            Icon(
              _isGyroControl ? Icons.screen_rotation : Icons.touch_app,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _isGyroControl
                  ? 'Mode: Gyro Control'
                  : 'Mode: Button Control',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
          ],

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


  // --- WIDGET HELPER (DAILY MISSION & SETTINGS) ---

  void _showDailyMissionDialog() {
    _loadGameData().then((_) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Misi Harian & Peringkat'),
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

  // --- FUNGSI BARU: Menampilkan Dialog Pengaturan Kontrol ---
  void _showControlSettingsDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan Kontrol'),
        content: _buildControlToggle(theme), // Panggil widget toggle
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveControlSettings(); // Simpan pengaturan saat dialog ditutup
            },
            child: const Text('Simpan & Tutup'),
          )
        ],
      ),
    );
  }


  Widget _buildDailyMissionCard(ThemeData theme) {
    String nextRank = "Legend";
    int nextThreshold = 1000;
    bool isMaxRank = false;
    
    // Gunakan _calculateRank untuk mendapatkan rank terbaru
    final currentRank = _calculateRank(_todayHighScore);
    
    _rankThresholds.forEach((key, value) {
      if (value > _todayHighScore && (value < nextThreshold || nextRank == "Legend")) {
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
    double progress = (nextThreshold == 0 || isMaxRank) ? 1.0 : (_todayHighScore / nextThreshold).clamp(0.0, 1.0);
    
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peringkat Harian',
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
                  currentRank.toUpperCase(),
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

  /// Widget untuk toggle control mode (dipanggil di dialog)
  Widget _buildControlToggle(ThemeData theme) {
    // Gunakan StatefulBuilder agar slider/switch bisa update
    // di dalam dialog tanpa menutupnya.
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isGyroControl ? Icons.screen_rotation : Icons.touch_app,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kontrol',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // TOGGLE SWITCH
                  Switch(
                    value: _isGyroControl,
                    onChanged: _gameStatus == GameStatus.playing
                        ? null // Disable saat sedang main
                        : (bool value) {
                            // Panggil setState utama (untuk logika game)
                            setState(() {
                              _isGyroControl = value;
                            });
                            // Panggil setState dialog (untuk update UI dialog)
                            setDialogState(() {
                              // _isGyroControl = value; // (sudah di-set di atas)
                            });

                            // Tampilkan feedback (di SnackBar utama)
                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Mode Gyro aktif - Miringkan HP untuk bermain'
                                      : 'Mode Tombol aktif',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: theme.colorScheme.primary,
                              ),
                            );
                          },
                    activeColor: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isGyroControl
                    ? '🎮 Gyro: Miringkan HP kiri-kanan'
                    : '🎮 Tombol: Tap untuk bergerak',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 13,
                ),
              ),
              
              // SENSITIVITY SLIDER (HANYA MUNCUL JIKA GYRO MODE)
              if (_isGyroControl) ...[
                const SizedBox(height: 16),
                Text(
                  'Sensitivitas: ${_gyroSensitivity.toInt()}',
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
                Slider(
                  value: _gyroSensitivity,
                  min: 5.0, // Lambat
                  max: 30.0, // Cepat
                  divisions: 25,
                  label: _gyroSensitivity.toInt().toString(),
                  onChanged: _gameStatus == GameStatus.playing
                      ? null // Disable saat main
                      : (double value) {
                          // Panggil setState utama (untuk logika game)
                          setState(() {
                            _gyroSensitivity = value;
                          });
                          // Panggil setState dialog (untuk update UI)
                          setDialogState(() {
                            // _gyroSensitivity = value; // (sudah di-set di atas)
                          });
                        },
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.surfaceContainerHigh,
                ),
                Text(
                  // Perbaiki deskripsi
                  'Lebih tinggi = lebih responsif (lebih cepat)',
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }
}