import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:absensi/absensi_main/helpers/date_helper.dart';
import 'package:absensi/absensi_main/helpers/ui_helper.dart';
import 'package:absensi/absensi_main/models/absen_model.dart';
import 'package:absensi/absensi_main/models/user_model.dart';
import 'package:absensi/absensi_main/screens/map_detail_screen.dart';
import 'package:absensi/absensi_main/services/api_service.dart';
import 'package:absensi/absensi_main/services/location_service.dart';
import 'package:absensi/absensi_main/services/session_manager.dart';
import 'package:absensi/absensi_main/widgets/confirmation_dialog.dart';
import 'package:absensi/absensi_main/widgets/empty_state_widget.dart';
import 'package:absensi/absensi_main/widgets/header_banner_card.dart';
import 'package:absensi/absensi_main/widgets/primary_button.dart';
import 'package:absensi/absensi_main/widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
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

  Future<void> _loadAbsenHistory() async {
    try {
      final history = await _apiService.getHistory();
      if (!mounted) return;

      int masuk = 0;
      int izin = 0;
      int selesai = 0;

      final todayStr = DateHelper.getTodayKey();

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

  Widget _buildLocationPreviewBox() {
    return Container(
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
              const Icon(Icons.place, size: 16, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _currentLocation?.address ?? 'Lokasi saat ini',
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        Colors.black87, // <-- Mengunci teks agar selalu hitam
                  ),
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
    );
  }

  Future<void> _handleCheckIn() async {
    if (_currentLocation == null) {
      await _loadLocationData();
    }
    if (!mounted) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Konfirmasi Absen Masuk',
      message: 'Apakah Anda yakin ingin melakukan absen masuk saat ini?',
      confirmText: 'Ya, Absen Masuk',
      confirmColor: const Color(0xFF059669),
      icon: Icons.login_rounded,
      contentWidget: _buildLocationPreviewBox(),
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
        UiHelper.showSnackBar(
          context,
          'Absen masuk berhasil tercatat (ID: ${res.id})',
          backgroundColor: const Color(0xFF059669),
        );
        _loadAbsenHistory();
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
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

  Future<void> _handleCheckOut() async {
    if (_currentLocation == null) {
      await _loadLocationData();
    }
    if (!mounted) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Konfirmasi Absen Pulang',
      message: 'Apakah Anda yakin ingin melakukan absen pulang dan mengakhiri kehadiran hari ini?',
      confirmText: 'Ya, Absen Pulang',
      confirmColor: const Color(0xFFEA580C),
      icon: Icons.logout_rounded,
      contentWidget: _buildLocationPreviewBox(),
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
        UiHelper.showSnackBar(
          context,
          'Absen pulang berhasil tercatat (ID: ${res.id})',
          backgroundColor: const Color(0xFFEA580C),
        );
        _loadAbsenHistory();
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
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

  Future<void> _handleIzin() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
        UiHelper.showSnackBar(
          context,
          'Pengajuan izin berhasil dicatat (ID: ${res.id})',
          backgroundColor: const Color(0xFFD97706),
        );
        _loadAbsenHistory();
      }
    } catch (e) {
      if (mounted) {
        UiHelper.showSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
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
            HeaderBannerCard(
              title: DateHelper.getGreeting(),
              userName: _currentUser?.name ?? 'Peserta PPKD',
              subtitle: DateHelper.formatIndonesianDate(),
              subtitleIcon: Icons.calendar_today_rounded,
              avatarIcon: Icons.person_rounded,
              gradientColors: const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
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
                  child: PrimaryButton(
                    height: 76,
                    borderRadius: 14,
                    isLoading: _isActionProcessing,
                    backgroundColor: const Color(0xFF059669),
                    onPressed: _isActionProcessing ? null : _handleCheckIn,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.login_rounded, size: 26),
                        SizedBox(height: 4),
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
                  child: PrimaryButton(
                    height: 76,
                    borderRadius: 14,
                    isLoading: _isActionProcessing,
                    backgroundColor: const Color(0xFFEA580C),
                    onPressed: _isActionProcessing ? null : _handleCheckOut,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded, size: 26),
                        SizedBox(height: 4),
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
            PrimaryButton(
              height: 46,
              borderRadius: 12,
              isOutlined: true,
              backgroundColor: const Color(0xFFD97706),
              icon: Icons.assignment_late_outlined,
              text: 'Pengajuan Izin / Sakit Hari Ini',
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
                  child: StatCard(
                    label: 'Total Masuk',
                    value: _countMasuk,
                    color: const Color(0xFF059669),
                    icon: Icons.check_circle_outline_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Total Izin',
                    value: _countIzin,
                    color: const Color(0xFFD97706),
                    icon: Icons.time_to_leave_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Selesai Pulang',
                    value: _countSelesai,
                    color: const Color(0xFF2563EB),
                    icon: Icons.done_all_rounded,
                    isDark: isDark,
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
              EmptyStateWidget(
                title: 'Belum Ada Presensi Hari Ini',
                message:
                    'Belum ada data presensi yang tercatat untuk hari ini.',
                icon: Icons.schedule_rounded,
                isDark: isDark,
              ),
          ],
        ),
      ),
    );
  }
}
