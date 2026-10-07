import 'package:absensi/absensi_main/widgets/confirmation_dialog.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> _loadLocationData({bool promptDisclosure = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
    });
    final loc = await LocationService.getCurrentLocation(
      context: promptDisclosure ? context : null,
      promptDisclosureIfNeeded: promptDisclosure,
    );
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
    if (_currentLocation == null || _currentLocation!.isFallback) {
      await _loadLocationData(promptDisclosure: true);
    }
    if (!mounted) return;

    // final now = DateTime.now();
    // final islate = now.hour > 8 || (now.hour == 8 && now.minute > 30);

    // if (islate) {
    //   UiHelper.showSnackBar(
    //     context,
    //     'Waktu absen masuk telah ditutup (Maksimal pukul 08:00 WIB)',
    //     isError: true,
    //   );
    //   return;
    // }

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
    if (_currentLocation == null || _currentLocation!.isFallback) {
      await _loadLocationData(promptDisclosure: true);
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
              key: const Key('DashboardHeaderBanner'),
              title: DateHelper.getGreeting(),
              userName: _currentUser?.name ?? 'Peserta PPKD',
              subtitle: DateHelper.formatIndonesianDate(),
              subtitleIcon: Icons.calendar_today_rounded,
              showAnalogClock: true,
              gradientColors: const [Color(0xFF1E3A8A), Color(0xFF2563EB)],
            ),
            const SizedBox(height: 16),
            _LocationInfoCard(
              key: const Key('LocationInfoCard'),
              currentLocation: _currentLocation,
              isLoadingLocation: _isLoadingLocation,
              isDark: isDark,
              onRefreshLocation: () => _loadLocationData(promptDisclosure: true),
              onOpenFullMap: _openFullMap,
            ),
            const SizedBox(height: 16),
            _AttendanceActionButtons(
              key: const Key('AttendanceActionButtons'),
              isProcessing: _isActionProcessing,
              onCheckIn: _handleCheckIn,
              onCheckOut: _handleCheckOut,
            ),
            const SizedBox(height: 10),
            _LeavePermitButton(
              key: const Key('LeavePermitButton'),
              isProcessing: _isActionProcessing,
              onApplyLeave: _handleIzin,
            ),
            const SizedBox(height: 20),
            _AttendanceStatsSection(
              key: const Key('AttendanceStatsSection'),
              countMasuk: _countMasuk,
              countIzin: _countIzin,
              countSelesai: _countSelesai,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _RecentActivitySection(
              key: const Key('RecentActivitySection'),
              todayAbsen: _todayAbsen,
              isDark: isDark,
              onOpenHistory: widget.onOpenHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInfoCard extends StatelessWidget {
  final LocationResult? currentLocation;
  final bool isLoadingLocation;
  final bool isDark;
  final VoidCallback onRefreshLocation;
  final VoidCallback onOpenFullMap;

  const _LocationInfoCard({
    super.key,
    required this.currentLocation,
    required this.isLoadingLocation,
    required this.isDark,
    required this.onRefreshLocation,
    required this.onOpenFullMap,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<LocationResult?>('currentLocation', currentLocation),
    );
    properties.add(
      StringProperty(
        'address',
        currentLocation?.address,
        defaultValue: 'Belum terdeteksi',
      ),
    );
    properties.add(DoubleProperty('latitude', currentLocation?.latitude));
    properties.add(DoubleProperty('longitude', currentLocation?.longitude));
    properties.add(
      FlagProperty(
        'isLoadingLocation',
        value: isLoadingLocation,
        ifTrue: 'Sedang Memuat',
        ifFalse: 'Siap',
      ),
    );
    properties.add(
      FlagProperty(
        'isDark',
        value: isDark,
        ifTrue: 'Mode Gelap',
        ifFalse: 'Mode Terang',
      ),
    );
    properties.add(
      ObjectFlagProperty<VoidCallback>.has(
        'onRefreshLocation (Call: _loadLocationData)',
        onRefreshLocation,
      ),
    );
    properties.add(
      ObjectFlagProperty<VoidCallback>.has(
        'onOpenFullMap (Call: _openFullMap)',
        onOpenFullMap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('LocationInfoCardContainer'),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  key: const Key('RefreshLocationButton'),
                  icon: isLoadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Perbarui Lokasi (Call: _loadLocationData)',
                  onPressed: isLoadingLocation ? null : onRefreshLocation,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isLoadingLocation && currentLocation == null)
              Row(
                key: const Key('LocationDetectingState'),
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sedang mendeteksi alamat...',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            else
              Text(
                currentLocation?.address ??
                    'Alamat belum terdeteksi. Silakan ketuk tombol segarkan.',
                key: const Key('LocationAddressText'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.grey.shade100
                      : const Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              currentLocation != null
                  ? 'Latitude: ${currentLocation!.latitude.toStringAsFixed(6)} | Longitude: ${currentLocation!.longitude.toStringAsFixed(6)}'
                  : 'Koordinat belum tersedia',
              key: const Key('LocationCoordinatesText'),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            if (currentLocation?.isFallback == true)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: InkWell(
                  onTap: onRefreshLocation,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Izin lokasi belum aktif. Ketuk untuk mengizinkan.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.amber),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            InkWell(
              key: const Key('LocationMapPreviewTap'),
              onTap: onOpenFullMap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 130,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: Stack(
                  children: [
                    if (currentLocation != null)
                      GoogleMap(
                        key: const Key('GoogleMapMiniPreview'),
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            currentLocation!.latitude,
                            currentLocation!.longitude,
                          ),
                          zoom: 15,
                        ),
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        markers: {
                          Marker(
                            markerId: const MarkerId('live_pos'),
                            position: LatLng(
                              currentLocation!.latitude,
                              currentLocation!.longitude,
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
    );
  }
}

/// Tombol Aksi Utama Presensi (Masuk & Pulang)
class _AttendanceActionButtons extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _AttendanceActionButtons({
    super.key,
    required this.isProcessing,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty(
        'isProcessing',
        value: isProcessing,
        ifTrue: 'Sedang Proses',
        ifFalse: 'Siap',
      ),
    );
    properties.add(
      ObjectFlagProperty<VoidCallback>.has(
        'onCheckIn (Call: _handleCheckIn)',
        onCheckIn,
      ),
    );
    properties.add(
      ObjectFlagProperty<VoidCallback>.has(
        'onCheckOut (Call: _handleCheckOut)',
        onCheckOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('AttendanceButtonsRow'),
      children: [
        Expanded(
          child: PrimaryButton(
            key: const Key('CheckInButton'),
            height: 76,
            borderRadius: 14,
            isLoading: isProcessing,
            backgroundColor: const Color(0xFF059669),
            onPressed: isProcessing ? null : onCheckIn,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.how_to_reg_rounded, size: 26),
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
            key: const Key('CheckOutButton'),
            height: 76,
            borderRadius: 14,
            isLoading: isProcessing,
            backgroundColor: const Color(0xFFEA580C),
            onPressed: isProcessing ? null : onCheckOut,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_send_rounded, size: 26),
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
    );
  }
}

class _LeavePermitButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onApplyLeave;

  const _LeavePermitButton({
    super.key,
    required this.isProcessing,
    required this.onApplyLeave,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty(
        'isProcessing',
        value: isProcessing,
        ifTrue: 'Sedang Proses',
        ifFalse: 'Siap',
      ),
    );
    properties.add(
      ObjectFlagProperty<VoidCallback>.has(
        'onApplyLeave (Call: _handleIzin)',
        onApplyLeave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      key: const Key('LeavePermitPrimaryButton'),
      height: 46,
      borderRadius: 12,
      isOutlined: true,
      backgroundColor: const Color(0xFFD97706),
      icon: Icons.pending_actions_rounded,
      text: 'Pengajuan Izin / Sakit Hari Ini',
      onPressed: isProcessing ? null : onApplyLeave,
    );
  }
}

/// Bagian Statistik Kehadiran
class _AttendanceStatsSection extends StatelessWidget {
  final int countMasuk;
  final int countIzin;
  final int countSelesai;
  final bool isDark;

  const _AttendanceStatsSection({
    super.key,
    required this.countMasuk,
    required this.countIzin,
    required this.countSelesai,
    required this.isDark,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('countMasuk', countMasuk));
    properties.add(IntProperty('countIzin', countIzin));
    properties.add(IntProperty('countSelesai', countSelesai));
    properties.add(
      FlagProperty(
        'isDark',
        value: isDark,
        ifTrue: 'Mode Gelap',
        ifFalse: 'Mode Terang',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('AttendanceStatsColumn'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistik Kehadiran Anda',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          key: const Key('AttendanceStatsRow'),
          children: [
            Expanded(
              child: StatCard(
                key: const Key('StatMasukCard'),
                label: 'Total Masuk',
                value: countMasuk,
                color: const Color(0xFF059669),
                icon: Icons.how_to_reg_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                key: const Key('StatIzinCard'),
                label: 'Total Izin',
                value: countIzin,
                color: const Color(0xFFD97706),
                icon: Icons.pending_actions_rounded,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                key: const Key('StatSelesaiCard'),
                label: 'Selesai Pulang',
                value: countSelesai,
                color: const Color(0xFF2563EB),
                icon: Icons.task_alt_rounded,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bagian Aktivitas Terakhir
class _RecentActivitySection extends StatelessWidget {
  final AbsenModel? todayAbsen;
  final bool isDark;
  final VoidCallback onOpenHistory;

  const _RecentActivitySection({
    super.key,
    required this.todayAbsen,
    required this.isDark,
    required this.onOpenHistory,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AbsenModel?>('todayAbsen', todayAbsen));
    properties.add(StringProperty('status', todayAbsen?.status));
    properties.add(StringProperty('checkInTime', todayAbsen?.checkIn));
    properties.add(StringProperty('checkOutTime', todayAbsen?.checkOut));
    properties.add(
      FlagProperty(
        'isDark',
        value: isDark,
        ifTrue: 'Mode Gelap',
        ifFalse: 'Mode Terang',
      ),
    );
    properties.add(
      ObjectFlagProperty<VoidCallback>.has(
        'onOpenHistory (Call: widget.onOpenHistory)',
        onOpenHistory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('RecentActivityColumn'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Aktivitas Terakhir',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            TextButton(
              key: const Key('ViewAllHistoryButton'),
              onPressed: onOpenHistory,
              child: const Text('Lihat Semua'),
            ),
          ],
        ),
        if (todayAbsen != null)
          Card(
            key: const Key('TodayActivityCard'),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: todayAbsen!.status == 'izin'
                    ? Colors.amber.shade100
                    : Colors.green.shade100,
                foregroundColor: todayAbsen!.status == 'izin'
                    ? Colors.amber.shade900
                    : Colors.green.shade900,
                child: Icon(
                  todayAbsen!.status == 'izin'
                      ? Icons.pending_actions_rounded
                      : Icons.how_to_reg_rounded,
                ),
              ),
              title: Text(
                'Presensi: ${todayAbsen!.status.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Masuk: ${todayAbsen!.checkIn ?? '-'} | Pulang: ${todayAbsen!.checkOut ?? '-'}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: onOpenHistory,
            ),
          )
        else
          EmptyStateWidget(
            key: const Key('EmptyActivityWidget'),
            imagePath: 'assets/images/empty_attendance.png',
            title: 'Belum Ada Presensi Hari Ini',
            message: 'Belum ada data presensi yang tercatat untuk hari ini.',
            icon: Icons.schedule_rounded,
            isDark: isDark,
          ),
      ],
    );
  }
}
