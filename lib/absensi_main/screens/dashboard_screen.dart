import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:absensi/absensi_main/models/absen_model.dart';
import 'package:absensi/absensi_main/models/user_model.dart';
import 'package:absensi/absensi_main/screens/map_detail_screen.dart';
import 'package:absensi/absensi_main/services/api_service.dart';
import 'package:absensi/absensi_main/services/location_service.dart';
import 'package:absensi/absensi_main/services/session_manager.dart';

/// Halaman beranda utama yang menampilkan kartu sambutan, status lokasi GPS,
/// tombol aksi presensi (Masuk, Pulang, Izin), dan ringkasan kehadiran hari ini.
class DashboardScreen extends StatefulWidget {
  /// Callback untuk berpindah ke tab riwayat absensi.
  final VoidCallback onOpenHistory;

  const DashboardScreen({super.key, required this.onOpenHistory});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  LocationResult? _currentLocation;

  bool _isLoadingData = true;
  bool _isLoadingLocation = false;
  bool _isActionProcessing = false;

  AbsenModel? _todayAbsen;
  int _countMasuk = 0;
  int _countIzin = 0;
  int _countSelesai = 0;

  @override
  void initState() {
    super.initState();
    _loadAllDashboardData();
  }

  /// Memuat semua data yang dibutuhkan dashboard secara paralel (profil, lokasi, dan absensi).
  Future<void> _loadAllDashboardData() async {
    setState(() {
      _isLoadingData = true;
    });

    await Future.wait([
      _loadUserData(),
      _loadLocationData(),
      _loadAbsenHistory(),
    ]);

    if (mounted) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  /// Mengambil data identitas pengguna dari penyimpanan lokal lalu menyinkronkannya dengan server.
  Future<void> _loadUserData() async {
    final cached = await SessionManager.getUser();
    if (cached != null && mounted) {
      setState(() {
        _currentUser = cached;
      });
    }
    try {
      final user = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (_) {}
  }

  /// Membaca koordinat lintang-bujur dan alamat GPS perangkat secara real-time.
  Future<void> _loadLocationData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
    });
    final loc = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentLocation = loc;
        _isLoadingLocation = false;
      });
    }
  }

  /// Mengambil riwayat absensi dan menghitung ringkasan kehadiran untuk hari ini.
  Future<void> _loadAbsenHistory() async {
    try {
      final history = await _apiService.getHistory();
      if (!mounted) return;

      int masuk = 0;
      int izin = 0;
      int selesai = 0;

      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      AbsenModel? foundToday;

      for (var a in history) {
        if (a.status.toLowerCase() == 'izin') {
          izin++;
        } else {
          masuk++;
        }
        if (a.checkOut != null && a.checkOut!.isNotEmpty) {
          selesai++;
        }

        if (a.createdAt != null && a.createdAt!.startsWith(todayStr)) {
          foundToday = a;
        } else if (a.checkIn != null && a.checkIn!.startsWith(todayStr)) {
          foundToday = a;
        }
      }

      setState(() {
        _countMasuk = masuk;
        _countIzin = izin;
        _countSelesai = selesai;
        _todayAbsen = foundToday ?? (history.isNotEmpty ? history.first : null);
      });
    } catch (_) {}
  }

  /// Menghasilkan ucapan salam berdasarkan waktu jam sistem lokal saat ini.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  /// Mengembalikan format teks tanggal hari ini dalam format bahasa Indonesia.
  String _getFormattedDate() {
    final now = DateTime.now();
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  /// Menampilkan dialog konfirmasi dan memproses presensi masuk ke API.
  Future<void> _handleCheckIn() async {
    if (_currentLocation == null) {
      await _loadLocationData();
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Absen Masuk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin melakukan absen masuk saat ini?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        size: 16,
                        color: Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentLocation?.address ?? 'Lokasi saat ini',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Koordinat: ${_currentLocation?.latitude.toStringAsFixed(4)}, ${_currentLocation?.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Absen Masuk'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isActionProcessing = true;
    });

    try {
      final res = await _apiService.checkIn(
        lat: _currentLocation?.latitude ?? LocationService.defaultLat,
        lng: _currentLocation?.longitude ?? LocationService.defaultLng,
        address: _currentLocation?.address ?? LocationService.defaultAddress,
        status: 'masuk',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Absen masuk berhasil tercatat (ID: ${res.id})'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        _loadAbsenHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionProcessing = false;
        });
      }
    }
  }

  /// Menampilkan dialog konfirmasi dan memproses presensi pulang (check-out) ke API.
  Future<void> _handleCheckOut() async {
    if (_currentLocation == null) {
      await _loadLocationData();
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Absen Pulang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apakah Anda yakin ingin melakukan absen pulang dan mengakhiri kehadiran hari ini?',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        size: 16,
                        color: Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentLocation?.address ?? 'Lokasi saat ini',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Koordinat: ${_currentLocation?.latitude.toStringAsFixed(4)}, ${_currentLocation?.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Absen Pulang'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isActionProcessing = true;
    });

    try {
      final res = await _apiService.checkOut(
        lat: _currentLocation?.latitude ?? LocationService.defaultLat,
        lng: _currentLocation?.longitude ?? LocationService.defaultLng,
        address: _currentLocation?.address ?? LocationService.defaultAddress,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Absen pulang berhasil tercatat (ID: ${res.id})'),
            backgroundColor: const Color(0xFFEA580C),
          ),
        );
        _loadAbsenHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionProcessing = false;
        });
      }
    }
  }

  /// Menampilkan dialog isian alasan dan memproses pengajuan izin tidak hadir ke API.
  Future<void> _handleIzin() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pengajuan Izin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alasan izin atau sakit yang ingin disampaikan:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Contoh: Izin sakit demam / Keperluan mendesak keluarga',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            child: const Text('Kirim Izin'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    setState(() {
      _isActionProcessing = true;
    });

    try {
      final res = await _apiService.checkIn(
        lat: _currentLocation?.latitude ?? LocationService.defaultLat,
        lng: _currentLocation?.longitude ?? LocationService.defaultLng,
        address: _currentLocation?.address ?? LocationService.defaultAddress,
        status: 'izin',
        alasanIzin: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengajuan izin berhasil dicatat (ID: ${res.id})'),
            backgroundColor: const Color(0xFFD97706),
          ),
        );
        _loadAbsenHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionProcessing = false;
        });
      }
    }
  }

  /// Membuka tampilan peta interaktif layar penuh pada koordinat saat ini.
  void _openFullMap() {
    if (_currentLocation == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapDetailScreen(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          title: 'Lokasi Anda Saat Ini',
          address: _currentLocation!.address,
          time: 'Diperbarui baru saja',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllDashboardData,
      color: const Color(0xFF1E3A8A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentUser?.name ?? 'Peserta PPKD',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getFormattedDate(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF1E3A8A),
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Lokasi Presensi Anda',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: _isLoadingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 20),
                          tooltip: 'Perbarui Lokasi',
                          onPressed: _isLoadingLocation
                              ? null
                              : _loadLocationData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentLocation?.address ??
                          'Sedang mendeteksi alamat...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Latitude: ${_currentLocation?.latitude.toStringAsFixed(6)} | Longitude: ${_currentLocation?.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _openFullMap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 130,
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Stack(
                          children: [
                            if (_currentLocation != null)
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(
                                    _currentLocation!.latitude,
                                    _currentLocation!.longitude,
                                  ),
                                  zoom: 15,
                                ),
                                zoomControlsEnabled: false,
                                myLocationButtonEnabled: false,
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('live_pos'),
                                    position: LatLng(
                                      _currentLocation!.latitude,
                                      _currentLocation!.longitude,
                                    ),
                                  ),
                                },
                              ),
                            Container(
                              color: Colors.black.withValues(alpha: 0.15),
                              alignment: Alignment.bottomRight,
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fullscreen_rounded,
                                      size: 16,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Buka Peta Penuh',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _isActionProcessing ? null : _handleCheckIn,
                    child: _isActionProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login_rounded, size: 28),
                              SizedBox(height: 6),
                              Text(
                                'ABSEN MASUK',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _isActionProcessing ? null : _handleCheckOut,
                    child: _isActionProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded, size: 28),
                              SizedBox(height: 6),
                              Text(
                                'ABSEN PULANG',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD97706),
                side: const BorderSide(color: Color(0xFFD97706)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.assignment_late_outlined, size: 18),
              label: const Text(
                'Pengajuan Izin / Sakit Hari Ini',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _isActionProcessing ? null : _handleIzin,
            ),
            const SizedBox(height: 20),
            const Text(
              'Statistik Kehadiran Anda',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF059669),
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_countMasuk',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Total Masuk',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD97706).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.time_to_leave_rounded,
                          color: Color(0xFFD97706),
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_countIzin',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Total Izin',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.done_all_rounded,
                          color: Color(0xFF2563EB),
                          size: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_countSelesai',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Selesai Pulang',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aktivitas Terakhir',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: widget.onOpenHistory,
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            if (_todayAbsen != null)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _todayAbsen!.status == 'izin'
                        ? Colors.amber.shade100
                        : Colors.green.shade100,
                    foregroundColor: _todayAbsen!.status == 'izin'
                        ? Colors.amber.shade900
                        : Colors.green.shade900,
                    child: Icon(
                      _todayAbsen!.status == 'izin'
                          ? Icons.note_alt_outlined
                          : Icons.access_time_rounded,
                    ),
                  ),
                  title: Text(
                    'Presensi: ${_todayAbsen!.status.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Masuk: ${_todayAbsen!.checkIn ?? '-'} | Pulang: ${_todayAbsen!.checkOut ?? '-'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: widget.onOpenHistory,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Belum ada data presensi yang tercatat untuk hari ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
