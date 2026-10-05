import 'package:flutter/material.dart';
import 'package:absensi/absensi_main/helpers/ui_helper.dart';
import 'package:absensi/absensi_main/models/absen_model.dart';
import 'package:absensi/absensi_main/screens/map_detail_screen.dart';
import 'package:absensi/absensi_main/services/api_service.dart';
import 'package:absensi/absensi_main/widgets/confirmation_dialog.dart';
import 'package:absensi/absensi_main/widgets/detail_info_row.dart';
import 'package:absensi/absensi_main/widgets/empty_state_widget.dart';
import 'package:absensi/absensi_main/widgets/stat_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();

  List<AbsenModel> _history = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'semua';

  static const List<Map<String, String>> _filterOptions = [
    {'key': 'semua', 'label': 'Semua'},
    {'key': 'masuk', 'label': 'Masuk'},
    {'key': 'izin', 'label': 'Izin'},
    {'key': 'selesai', 'label': 'Selesai'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getHistory();
      data.sort((a, b) {
        final ka = a.createdAt ?? '';
        final kb = b.createdAt ?? '';
        return kb.compareTo(ka);
      });
      if (mounted) {
        setState(() {
          _history = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _konfirmasiHapus(AbsenModel absen) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final contentBox = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${absen.tanggalFormatted} (${absen.statusLabel})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Masuk: ${absen.checkIn ?? '-'} | Pulang: ${absen.checkOut ?? '-'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                absen.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Tindakan ini tidak dapat dibatalkan. Catatan presensi akan dihapus dari server.',
          style: TextStyle(fontSize: 11, color: Colors.red),
        ),
      ],
    );

    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Hapus Absensi',
      message: 'Apakah Anda yakin ingin menghapus data presensi berikut?',
      confirmText: 'Hapus',
      confirmColor: Colors.red.shade600,
      icon: Icons.delete_forever_rounded,
      contentWidget: contentBox,
      isDestructive: true,
    );

    if (konfirmasi != true) return;

    try {
      await _apiService.deleteAbsen(absen.id);
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        'Data absensi berhasil dihapus',
        backgroundColor: const Color(0xFF059669),
      );
      _loadHistory();
    } catch (e) {
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  List<AbsenModel> get _filtered {
    if (_filter == 'semua') return _history;
    if (_filter == 'masuk') {
      return _history.where((a) => !a.isIzin && !a.sudahPulang).toList();
    }
    if (_filter == 'izin') {
      return _history.where((a) => a.isIzin).toList();
    }
    if (_filter == 'selesai') {
      return _history.where((a) => a.sudahPulang).toList();
    }
    return _history;
  }

  int _hitung(String status) {
    if (status == 'masuk') {
      return _history.where((a) => !a.isIzin && !a.sudahPulang).length;
    }
    if (status == 'izin') {
      return _history.where((a) => a.isIzin).length;
    }
    return _history.where((a) => a.sudahPulang).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Masuk',
                  value: _hitung('masuk'),
                  color: const Color(0xFF059669),
                  icon: Icons.how_to_reg_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Izin',
                  value: _hitung('izin'),
                  color: const Color(0xFFD97706),
                  icon: Icons.pending_actions_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Selesai',
                  value: _hitung('selesai'),
                  color: const Color(0xFF2563EB),
                  icon: Icons.task_alt_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final opsi = _filterOptions[index];
                final aktif = _filter == opsi['key'];
                return ChoiceChip(
                  label: Text(opsi['label'] ?? ''),
                  selected: aktif,
                  onSelected: (_) {
                    setState(() {
                      _filter = opsi['key'] ?? 'semua';
                    });
                  },
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
                    color: aktif ? Colors.white : null,
                  ),
                  selectedColor: const Color(0xFF4F46E5),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ${_filtered.length} catatan',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadHistory,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Muat ulang',
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              iconColor: Colors.red,
              title: 'Gagal memuat riwayat',
              message: _errorMessage!,
              onRetry: _loadHistory,
              isDark: isDark,
            )
          else if (_filtered.isEmpty)
            EmptyStateWidget(
              imagePath: 'assets/images/empty_attendance.png',
              title: 'Belum Ada Data Presensi',
              message: 'Riwayat absensi akan muncul setelah Anda melakukan presensi masuk atau mengajukan izin.',
              icon: Icons.calendar_today_outlined,
              isDark: isDark,
            )
          else
            ..._filtered.map((absen) => _kartuRiwayat(absen, isDark)),
        ],
      ),
    );
  }

  Widget _kartuRiwayat(AbsenModel absen, bool isDark) {
    final warna = absen.isIzin
        ? const Color(0xFFD97706)
        : absen.sudahPulang
        ? const Color(0xFF2563EB)
        : const Color(0xFF059669);

    final ikon = absen.isIzin
        ? Icons.pending_actions_rounded
        : absen.sudahPulang
        ? Icons.task_alt_rounded
        : Icons.how_to_reg_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: CircleAvatar(
            backgroundColor: warna.withValues(alpha: 0.15),
            foregroundColor: warna,
            child: Icon(ikon, size: 20),
          ),
          title: Text(
            '${absen.tanggalFormatted} - ${absen.statusLabel}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Masuk: ${absen.checkIn ?? '-'}  |  Pulang: ${absen.checkOut ?? '-'}',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                absen.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 22,
                ),
                tooltip: 'Hapus data absensi',
                onPressed: () => _konfirmasiHapus(absen),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
          onTap: () => _bukaDetail(absen),
        ),
      ),
    );
  }

  void _bukaDetail(AbsenModel absen) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final warna = absen.isIzin
            ? const Color(0xFFD97706)
            : absen.sudahPulang
            ? const Color(0xFF2563EB)
            : const Color(0xFF059669);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: warna.withValues(alpha: 0.15),
                    foregroundColor: warna,
                    child: Icon(
                      absen.isIzin
                          ? Icons.note_alt_outlined
                          : Icons.fact_check_outlined,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Absensi',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${absen.tanggalFormatted} - ${absen.statusLabel}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              DetailInfoRow(
                icon: Icons.login_rounded,
                label: 'Jam Masuk',
                value: absen.checkIn ?? '-',
                isDark: isDark,
              ),
              DetailInfoRow(
                icon: Icons.logout_rounded,
                label: 'Jam Pulang',
                value: absen.checkOut ?? '-',
                isDark: isDark,
              ),
              DetailInfoRow(
                icon: Icons.my_location_outlined,
                label: 'Koordinat',
                value:
                    '${absen.latitude.toStringAsFixed(6)}, ${absen.longitude.toStringAsFixed(6)}',
                isDark: isDark,
              ),
              DetailInfoRow(
                icon: Icons.location_on_outlined,
                label: 'Alamat',
                value: absen.address,
                isDark: isDark,
              ),
              if (absen.alasanIzin != null)
                DetailInfoRow(
                  icon: Icons.description_outlined,
                  label: 'Alasan Izin',
                  value: absen.alasanIzin!,
                  isDark: isDark,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final nav = Navigator.of(this.context);
                    Navigator.pop(context);
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => MapDetailScreen(
                          latitude: absen.latitude,
                          longitude: absen.longitude,
                          title: 'Lokasi Absensi',
                          address: absen.address,
                          time:
                              '${absen.tanggalFormatted} ${absen.jamFormatted}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Lihat Peta Lokasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _konfirmasiHapus(absen);
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'Hapus Data Absensi Ini',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
