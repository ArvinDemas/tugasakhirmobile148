/**
 * File: home_screen.dart
 * Deskripsi: Halaman utama (tab pertama) aplikasi yang fokus pada tim Williams.
 *
 * UPDATE:
 * - Menambahkan parameter 'onProfilePressed' untuk menerima fungsi
 * dari main_screen.dart guna membuka drawer.
 * - Menghapus Scaffold dan body, widget ini sekarang adalah 'body' murni
 * untuk IndexedStack di main_screen.dart.
 * - Mengubah onTap pada profil untuk memanggil 'widget.onProfilePressed'.
 * - Menerapkan UI _buildCustomAppBar baru (tombol menu + nama)
 * dan memastikan tombol menu tersebut memanggil widget.onProfilePressed.
 */

 // Untuk File di avatar
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Paket untuk carousel gambar
import 'package:intl/intl.dart'; // Paket untuk format tanggal dan waktu
import 'dart:async'; // Dibutuhkan untuk Timer (update jam & countdown)
import '../../../services/api_service.dart'; // Impor ApiService
import 'package:hive_flutter/hive_flutter.dart'; // Impor Hive

class HomeScreen extends StatefulWidget {
  // --- 1. MEMILIKI PARAMETER INI ---
  final VoidCallback onProfilePressed;
  
  const HomeScreen({
    super.key,
    // --- 2. MEMILIKI PARAMETER INI ---
    required this.onProfilePressed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instance ApiService
  final ApiService _apiService = ApiService();
  
  // Future untuk data Home (dipanggil sekali di initState)
  late Future<Map<String, dynamic>> _homeDataFuture;
  
  // State untuk data pengguna
  String userName = "Pengguna";
  String? userProfileImagePath; // userProfileImagePath tidak digunakan di AppBAr baru

  // State untuk jam konversi waktu
  String currentTimeWIB = '--:--:--';
  String currentTimeWITA = '--:--:--';
  String currentTimeWIT = '--:--:--';
  String currentTimeLondon = '--:--:--';
  Timer? _clockTimer;

  // Daftar path asset lokal untuk gambar carousel
  final List<String> imgList = [
    'assets/images/williams_carousel_1.png',
    'assets/images/williams_carousel_2.png',
  ];

  // ID Tim Williams (dari API-Sports)
  final int williamsTeamId = 12; // Diambil dari log sebelumnya

  @override
  void initState() {
    super.initState();
    // Panggil semua data API sekaligus saat halaman dibuka
    _homeDataFuture = _apiService.getHomeData();
    
    // Muat data pengguna dari Hive
    _loadUserData();
    
    // Mulai jam konversi
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateClock();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // --- FUNGSI UNTUK MEMUAT DATA PENGGUNA DARI HIVE ---
  Future<void> _loadUserData() async {
      try {
        final userBox = Hive.box('users');
        final currentUserEmail = userBox.get('currentUserEmail');
        if (currentUserEmail != null) {
          final userData = userBox.get(currentUserEmail) as Map?;
          if (userData != null && mounted) {
              setState(() {
                userName = userData['username'] ?? "Pengguna";
                // userProfileImagePath tidak lagi dibutuhkan untuk app bar baru
                // userProfileImagePath = userData['profileImagePath'] as String?;
              });
          }
        }
      } catch (e) {
        print("[HomeScreen] Error loading user data from Hive: $e");
      }
  }

  // --- FUNGSI UNTUK MENGUPDATE WAKTU KONVERSI ---
  void _updateClock() {
    final nowUtc = DateTime.now().toUtc();
    final formatter = DateFormat('HH:mm:ss');
    final wibTime = nowUtc.add(const Duration(hours: 7));
    final witaTime = nowUtc.add(const Duration(hours: 8));
    final witTime = nowUtc.add(const Duration(hours: 9));
    final londonTime = nowUtc;
    if (mounted) {
      setState(() {
        currentTimeWIB = formatter.format(wibTime);
        currentTimeWITA = formatter.format(witaTime);
        currentTimeWIT = formatter.format(witTime);
        currentTimeLondon = formatter.format(londonTime);
      });
    }
  }

  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // --- 3. TIDAK ADA SCAFFOLD DI SINI ---
    return SafeArea(
      child: ListView( // Gunakan ListView agar bisa scroll
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // Bagian 1: Custom App Bar (Profil & Countdown)
          _buildCustomAppBar(context), // Memanggil fungsi yang sudah di-update
          const SizedBox(height: 16),

          // Bagian 2: Bar Konversi Waktu
          _buildTimeZoneConverter(),
          const SizedBox(height: 24),

          // Bagian 3: Carousel Gambar
          _buildImageCarousel(),
          const SizedBox(height: 24),

          // --- BAGIAN 4: KONTEN DATA API (BARU) ---
          FutureBuilder<Map<String, dynamic>>(
            future: _homeDataFuture, // Panggil Future yang sudah di-init
            builder: (context, snapshot) {
              
              // State 1: Sedang Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // State 2: Terjadi Error
              if (snapshot.hasError) {
                print("[HomeScreen] Error FutureBuilder: ${snapshot.error}");
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      'Gagal memuat data Williams.\nMohon periksa koneksi internet Anda atau coba lagi nanti.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
                );
              }

              // State 3: Data Berhasil Didapat
              if (snapshot.hasData) {
                final data = snapshot.data!;
                
                // Ekstrak data dari Map
                final List<dynamic> constructorStandings = data['constructorStandings'] ?? [];
                final List<dynamic> driverRankings = data['driverRankings'] ?? [];
                final List<dynamic> lastRaceResults = data['lastRaceResults'] ?? [];
                final List<dynamic> lastRaceGrid = data['lastRaceGrid'] ?? [];
                final String lastRaceName = data['lastRaceName'] ?? 'Balapan Terakhir';

                // Tampilkan widget-widget baru dengan data
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Widget 1: Klasemen (Tim & Pembalap)
                      _buildSectionTitle('Klasemen Musim ${_apiService.currentSeasonYear}'), // Judul dinamis
                      _buildStandingsHub(constructorStandings, driverRankings),
                      const SizedBox(height: 24),
                      
                      // Widget 2: Hasil Balapan Terakhir
                      _buildSectionTitle(lastRaceName), // Judul dinamis
                      _buildLastRaceResult(lastRaceResults, lastRaceGrid),
                      const SizedBox(height: 24),
                      
                      // Widget 3: Deskripsi Tim (Statis)
                        _buildSectionTitle('Tentang Tim'),
                      _buildTeamDescription(), // Tetap tampilkan
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              }
              
              // Fallback jika state tidak terduga
              return const Center(child: Text('Tidak ada data tersedia.'));
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER (UI) ---

  /**
    * Membangun AppBar Custom (Profil & Countdown).
    * --- INI ADALAH FUNGSI YANG DI-UPDATE ---
    */
  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bagian Kiri: Menu Icon + Nama User
          Row(
            children: [
              // ICON MENU (SIDEBAR)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  onPressed: () {
                    // --- FUNGSI ONPRESSEDF KITA YANG SUDAH BENAR ---
                    // Ini akan membuka sidebar di main_screen.dart
                    widget.onProfilePressed();
                  },
                  tooltip: 'Menu',
                ),
              ),
              const SizedBox(width: 12),
              // NAMA USER
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $userName! 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Selamat datang kembali',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Bagian Kanan: Countdown (tetap sama)
          const CountdownTimer(),
        ],
      ),
    );
  }

  /**
    * Membangun bar konversi waktu (Sama).
    */
  Widget _buildTimeZoneConverter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTimeColumn("WIB", currentTimeWIB),
          _buildTimeColumn("WITA", currentTimeWITA),
          _buildTimeColumn("WIT", currentTimeWIT),
          _buildTimeColumn("LONDON", currentTimeLondon),
        ],
      ),
    );
  }
  Widget _buildTimeColumn(String zone, String time) {
    return Column(
      children: [
        Text(zone, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        Text(time, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  /**
    * Membangun Carousel Gambar (Sama, pakai asset lokal).
    */
  Widget _buildImageCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
          height: 180.0, autoPlay: true, enlargeCenterPage: true, aspectRatio: 16/9,
          autoPlayCurve: Curves.fastOutSlowIn, enableInfiniteScroll: true,
          autoPlayAnimationDuration: const Duration(milliseconds: 800), viewportFraction: 0.85,
      ),
      items: imgList.map((itemPath) {
        return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration( color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12.0)),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.asset(
                      itemPath, fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)),
                    ),
                ),
              );
            }
        );
      }).toList(),
    );
  }

  /**
    * Membangun bagian deskripsi statis tim Williams (Sama).
    */
  Widget _buildTeamDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tentang Williams Racing', style: TextStyle( fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Williams Racing adalah salah satu tim paling ikonik dalam sejarah Formula Satu. Didirikan oleh Sir Frank Williams dan Patrick Head, tim ini dikenal dengan semangat juang dan inovasi teknisnya.',
              style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BARU DENGAN DATA API PRO ---

  /**
    * [BARU] Membangun Card "Pusat Klasemen Williams".
    * Menggunakan data dari /rankings/teams dan /rankings/drivers.
    */
  Widget _buildStandingsHub(List<dynamic> constructorStandings, List<dynamic> driverRankings) {
    final theme = Theme.of(context);
    
    // --- 1. Proses Data Klasemen Konstruktor ---
    Map<String, dynamic>? williamsTeamData;
    Map<String, dynamic>? teamAheadData;
    int williamsPosition = 0;
    int williamsPoints = 0;
    String gapToTeamAhead = "-";

    try {
      // Cari data Williams
      williamsTeamData = constructorStandings.firstWhere(
        (team) => team['team']?['id'] == williamsTeamId, // Cari berdasarkan ID
        orElse: () => null,
      );

      if (williamsTeamData != null) {
        williamsPosition = williamsTeamData['position'] ?? 0;
        williamsPoints = williamsTeamData['points'] ?? 0;

        // Jika Williams bukan P1, cari tim di depannya
        if (williamsPosition > 1) {
          teamAheadData = constructorStandings.firstWhere(
            (team) => team['position'] == (williamsPosition - 1), // Cari pos P-1
            orElse: () => null,
          );
          if (teamAheadData != null) {
            int teamAheadPoints = teamAheadData['points'] ?? 0;
            int gap = teamAheadPoints - williamsPoints;
            gapToTeamAhead = "$gap Poin"; // Format selisih
          }
        } else if (williamsPosition == 1) {
          gapToTeamAhead = "Memimpin"; // Jika P1
        }
      }
    } catch (e) {
      print("[HomeScreen] Error parsing constructor standings: $e");
      // Biarkan nilai default
    }
    
    // --- 2. Proses Data Klasemen Pembalap ---
    List<dynamic> williamsDriversData = [];
    try {
       williamsDriversData = driverRankings.where(
         (driver) => driver['team']?['id'] == williamsTeamId // Filter berdasarkan ID Tim
       ).toList();
       // Urutkan berdasarkan posisi (jika API belum urut)
       williamsDriversData.sort((a,b) => (a['position'] ?? 99).compareTo(b['position'] ?? 99));
    } catch (e) {
       print("[HomeScreen] Error parsing driver rankings: $e");
    }


    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Bagian Peringkat Tim ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Peringkat Tim', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                // Peringkat (P7)
                Text(
                  'P${williamsPosition > 0 ? williamsPosition : "?"}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary, // Warna ungu
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Detail Poin Tim
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Poin Tim:', style: TextStyle(color: theme.colorScheme.outline, fontSize: 14)),
                Text('$williamsPoints Poin', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            // Selisih Poin
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Selisih ke P${williamsPosition > 1 ? williamsPosition - 1 : '?'} (${teamAheadData?['team']?['name'] ?? '??'}):', style: TextStyle(color: theme.colorScheme.outline, fontSize: 14)),
                Text(gapToTeamAhead, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            
            const Divider(height: 32.0), // Pemisah

            // --- Bagian Peringkat Pembalap ---
            // Gunakan Column untuk menampilkan kedua pembalap
            Column(
              children: williamsDriversData.isNotEmpty
                ? williamsDriversData.map((driver) {
                    // Parsing data 1 pembalap
                    final String name = driver['driver']?['name'] ?? 'N/A';
                    final String image = driver['driver']?['image'] ?? '';
                    final int pos = driver['position'] ?? 0;
                    final int points = driver['points'] ?? 0;

                    return _buildDriverRankingRow(theme, image, name, pos, points);
                  }).toList()
                // Tampilkan placeholder jika list kosong
                : [ const Text('Data pembalap tidak ditemukan.', style: TextStyle(color: Colors.grey)) ],
            ),
          ],
        ),
      ),
    );
  }

  /**
    * [BARU] Helper untuk 1 baris pembalap di klasemen.
    */
  Widget _buildDriverRankingRow(ThemeData theme, String imageUrl, String name, int position, int points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // Foto
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.surfaceVariant,
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          // Nama & Posisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                Text('Posisi: $position', style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
              ],
            ),
          ),
          // Poin
          Text(
            '$points Pts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary), // Ungu
          ),
        ],
      ),
    );
  }

  /**
    * [BARU] Membangun Card "Hasil Balapan Terakhir".
    * Menggunakan data dari /rankings/races dan /rankings/starting_grid.
    */
  Widget _buildLastRaceResult(List<dynamic> raceResults, List<dynamic> startingGrid) {
    final theme = Theme.of(context);
    
    // --- 1. Cari data Williams di Hasil Balapan ---
    final List<dynamic> williamsResults = raceResults.where(
      (r) => r['team']?['id'] == williamsTeamId
    ).toList();
    
    // --- 2. Cari data Williams di Starting Grid ---
    final List<dynamic> williamsGrid = startingGrid.where(
      (g) => g['team']?['id'] == williamsTeamId
    ).toList();

    // Jika data tidak lengkap, tampilkan pesan
    if (williamsResults.isEmpty) { // Cek results saja, grid bisa jadi 0 jika DNF/DNS
      return const Card(
        child: ListTile(
          title: Text('Data Balapan Terakhir Williams Tidak Tersedia'),
          subtitle: Text('Data mungkin belum dirilis oleh API.'),
        ),
      );
    }
    
    // Urutkan (jika perlu, tapi biasanya sudah)
    williamsResults.sort((a,b) => (a['driver']?['id'] ?? 0).compareTo(b['driver']?['id'] ?? 0));
    williamsGrid.sort((a,b) => (a['driver']?['id'] ?? 0).compareTo(b['driver']?['id'] ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: williamsResults.map((result) {
            // Cari data grid yang sesuai (berdasarkan ID driver)
            final driverId = result['driver']?['id'];
            Map<String, dynamic>? gridData = williamsGrid.firstWhere(
              (g) => g['driver']?['id'] == driverId,
              orElse: () => null, // Kembalikan null jika tidak ketemu di grid (misal start dari pit)
            );
            
            // Parsing data
            final String name = result['driver']?['name'] ?? 'N/A';
            final int finishPos = result['position'] ?? 0;
            final int startPos = gridData?['position'] ?? 0; // Ambil posisi start (0 jika null)
            
            // Hitung selisih posisi
            int posChange = 0;
            // Hanya hitung jika finis dan start valid
            if (finishPos > 0 && startPos > 0) {
              posChange = startPos - finishPos; // Start (10) - Finish (8) = +2
            }

            return _buildLastRaceRow(theme, name, finishPos, posChange);
          }).toList(),
        ),
      ),
    );
  }

  /**
    * [BARU] Helper untuk 1 baris hasil balapan terakhir.
    */
  Widget _buildLastRaceRow(ThemeData theme, String driverName, int finishPos, int posChange) {
    Color posColor = Colors.grey; // Warna untuk selisih
    String posSign = "";
    if (posChange > 0) {
      posColor = Colors.greenAccent[400]!; // Naik
      posSign = "+";
    } else if (posChange < 0) {
      posColor = Colors.redAccent[100]!; // Turun
      // Tanda minus sudah otomatis ada
    }

    return ListTile(
      // Pisahkan nama (misal "Alex Albon" -> "A. Albon")
      title: Text(driverName, style: const TextStyle(fontWeight: FontWeight.w500)),
      // Posisi Finis
      leading: Text(
        'P$finishPos',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
      ),
      // Selisih Posisi
      trailing: Text(
        (posChange == 0 ? '(0)' : '($posSign$posChange)'), // Tampilkan (0) jika tidak berubah
        style: TextStyle(color: posColor, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }


  /**
    * Helper Widget untuk membuat judul section.
    */
    Widget _buildSectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

} // Akhir Class _HomeScreenState


// --- Widget CountdownTimer (Perlu update API call) ---
// Widget ini akan di-rebuild dan otomatis memanggil API-nya sendiri
class CountdownTimer extends StatefulWidget {
    const CountdownTimer({super.key});
  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}
class _CountdownTimerState extends State<CountdownTimer> {
  final ApiService _apiService = ApiService(); // Panggil ApiService baru
  Timer? _timer;
  Duration? _timeRemaining;
  String _sessionName = 'Memuat Balapan...'; // Teks awal
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() { super.initState(); _fetchNextRaceTime(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _fetchNextRaceTime() async {
      if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // Panggil getNextRace() versi baru (yang pakai tahun 2025)
      final nextRaceDataList = await _apiService.getNextRace();
      if (!mounted) return;
      
      if (nextRaceDataList.isNotEmpty) {
        final nextRaceData = nextRaceDataList[0];
        // --- VERIFIKASI KEY JSON /races ---
        final dateString = nextRaceData['date'] as String?;
        final competitionName = nextRaceData['competition']?['name']; // Nama GP
        
        // --- FIX 2: Hapus 'sessionType' yang tidak terpakai ---
        // final sessionType = nextRaceData['type']; // "Race"
        
        String tempSessionName = 'Balapan Berikutnya';
        // --- FIX 2.1: Perbaiki logika, 'sessionType' tidak perlu ---
        if(competitionName != null) {
            tempSessionName = competitionName;
        }
        if (mounted) setState(() { _sessionName = tempSessionName; });

        if (dateString != null) {
          final raceTimeUtc = DateTime.parse(dateString);
          print('[Countdown] Race time UTC: $raceTimeUtc');
          _startTimer(raceTimeUtc);
        } else { throw Exception('Format tanggal balapan tidak valid.'); }
      } else { throw Exception('Tidak ada data balapan berikutnya.'); }
    } catch (e) {
        print('[Countdown] Error fetching next race time: $e');
      if (mounted) setState(() { _errorMessage = 'Gagal memuat'; _isLoading = false; });
    }
  }

  void _startTimer(DateTime raceTimeUtc) {
      _timer?.cancel();
      if (mounted) setState(() { _isLoading = false; }); // Sembunyikan loading
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      final nowUtc = DateTime.now().toUtc();
      if (nowUtc.isBefore(raceTimeUtc)) {
        if (mounted) setState(() { _timeRemaining = raceTimeUtc.difference(nowUtc); });
      } else {
        timer.cancel();
        if (mounted) setState(() { _timeRemaining = Duration.zero; });
      }
    });
  }

  String _formatDuration(Duration duration) {
      if (duration <= Duration.zero) return "SEDANG BERLANGSUNG"; // Teks saat balapan
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    
    if (days > 0) {
      return '${days}h ${hoursStr}j ${minutesStr}m'; // Tampilkan Hari, Jam, Menit
    } else {
      return '${hoursStr}j ${minutesStr}m ${secondsStr}d'; // Tampilkan Jam, Menit, Detik
    }
  }

  @override
  Widget build(BuildContext context) {
      if (_isLoading) return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54));
    if (_errorMessage != null) return Tooltip(message: _errorMessage!, child: const Icon(Icons.error_outline, color: Colors.orangeAccent, size: 18));
    if (_timeRemaining == null) return const Text('...', style: TextStyle(color: Colors.white, fontSize: 10));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(_sessionName, style: TextStyle(fontSize: 10, color: Colors.grey[400]), overflow: TextOverflow.ellipsis, maxLines: 1),
        Text(
          _formatDuration(_timeRemaining!),
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ],
    );
  }
}