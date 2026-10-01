import 'package:flutter/material.dart';
import 'package:absensi/absensi_main/models/absen_model.dart';
import 'package:absensi/absensi_main/models/user_model.dart';
import 'package:absensi/absensi_main/services/api_service.dart';
import 'package:absensi/absensi_main/services/session_manager.dart';

/// Halaman profil pengguna yang menampilkan identitas peserta, ringkasan kehadiran,
/// fitur edit nama, pengaturan tema, dan tombol keluar akun.
class ProfileScreen extends StatefulWidget {
  /// Callback yang dipanggil saat pengguna berhasil melakukan logout.
  final VoidCallback onLogout;

  /// Status apakah mode gelap sedang aktif.
  final bool isDarkMode;

  /// Callback untuk mengubah preferensi tema gelap/terang.
  final ValueChanged<bool> onThemeToggle;

  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  UserModel? _user;
  List<AbsenModel> _riwayat = const [];
  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  /// Mengambil data profil pengguna dan riwayat absensi dari sesi lokal dan server.
  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    UserModel? lokal;
    List<AbsenModel> riwayat = const [];

    try {
      lokal = await SessionManager.getUser();
      riwayat = await _apiService.getHistory();
    } catch (_) {
      lokal ??= await SessionManager.getUser();
    }

    UserModel? profil;
    try {
      profil = await _apiService.getProfile();
      await SessionManager.saveUser(profil);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      profil = lokal;
    }

    if (mounted) {
      setState(() {
        _user = profil ?? lokal;
        _riwayat = riwayat;
        _isLoading = false;
      });
    }
  }

  /// Menampilkan dialog modal interaktif untuk mengubah nama lengkap pengguna.
  Future<void> _tampilkanDialogEditNama(String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');
    final formKey = GlobalKey<FormState>();

    final namaBaru = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'Ubah Nama Pengguna',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masukkan nama lengkap baru Anda:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Contoh: Budi Santoso',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama minimal 2 karakter';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, controller.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (namaBaru == null || namaBaru.isEmpty || namaBaru == currentName) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = await _apiService.updateName(name: namaBaru);
      if (!mounted) return;
      setState(() {
        _user = updatedUser;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama pengguna berhasil diperbarui!'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui nama: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Menampilkan dialog konfirmasi sebelum mengeluarkan sesi akun pengguna.
  Future<void> _konfirmasiLogout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Keluar Akun'),
          content: const Text(
            'Anda yakin ingin keluar dari akun ini? Sesi absensi Anda akan diakhiri.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (konfirmasi != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    await SessionManager.clearSession();

    if (!mounted) return;
    setState(() {
      _isLoggingOut = false;
    });
    widget.onLogout();
  }

  /// Menghitung total kehadiran berstatus masuk.
  int get _totalHadir => _riwayat.where((a) => !a.isIzin).length;

  /// Menghitung total kehadiran berstatus izin.
  int get _totalIzin => _riwayat.where((a) => a.isIzin).length;

  /// Menghitung total kehadiran yang sudah absen pulang (check-out).
  int get _totalPulang => _riwayat.where((a) => a.sudahPulang).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _user;

    return RefreshIndicator(
      onRefresh: _muatData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _kartuProfil(user, isDark),
          const SizedBox(height: 16),
          if (_errorMessage != null) _kartuPeringatan(isDark),
          _judulSeksi('Ringkasan Absensi', isDark),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _kartuStatistik(
                  label: 'Hadir',
                  nilai: _totalHadir,
                  warna: const Color(0xFF059669),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kartuStatistik(
                  label: 'Izin',
                  nilai: _totalIzin,
                  warna: const Color(0xFFD97706),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _kartuStatistik(
                  label: 'Pulang',
                  nilai: _totalPulang,
                  warna: const Color(0xFF2563EB),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _judulSeksi('Data Peserta', isDark),
          const SizedBox(height: 10),
          _kartuInfo(
            isDark: isDark,
            baris: [
              _BarisInfo(
                icon: Icons.person_outline_rounded,
                label: 'Nama Lengkap',
                value: user?.name ?? '-',
                onEdit: () => _tampilkanDialogEditNama(user?.name),
              ),
              _BarisInfo(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user?.email ?? '-',
              ),
              _BarisInfo(
                icon: Icons.verified_user_outlined,
                label: 'Peran',
                value: user?.role ?? 'peserta',
              ),
            ],
          ),
          const SizedBox(height: 22),
          _judulSeksi('Pengaturan', isDark),
          const SizedBox(height: 10),
          _kartuTema(isDark),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoggingOut ? null : _konfirmasiLogout,
              icon: _isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.logout_rounded, size: 19),
              label: Text(
                _isLoggingOut ? 'KELUAR...' : 'KELUAR AKUN',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Absensi PPKD',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat widget kartu identitas profil di bagian atas halaman profil.
  Widget _kartuProfil(UserModel? user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: Text(
              user?.inisial ?? 'P',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.name ?? 'Peserta PPKD',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Ubah Nama',
                      onPressed: () => _tampilkanDialogEditNama(user?.name),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role ?? 'peserta',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _muatData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Muat ulang profil',
          ),
        ],
      ),
    );
  }

  /// Membuat widget banner informasi peringatan saat terjadi error jaringan.
  Widget _kartuPeringatan(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Menampilkan data tersimpan. ${_errorMessage!}',
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat widget judul seksi pada tampilan profil.
  Widget _judulSeksi(String judul, bool isDark) {
    return Text(
      judul,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
      ),
    );
  }

  /// Membuat widget kotak statistik ringkasan kehadiran.
  Widget _kartuStatistik({
    required String label,
    required int nilai,
    required Color warna,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warna.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$nilai',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: warna,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  /// Membuat widget kontainer daftar baris informasi profil.
  Widget _kartuInfo({required bool isDark, required List<_BarisInfo> baris}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < baris.length; i++) ...[
            _barisData(baris[i], isDark),
            if (i != baris.length - 1)
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              ),
          ],
        ],
      ),
    );
  }

  /// Membuat widget satu baris rincian informasi pengguna beserta tombol aksinya jika ada.
  Widget _barisData(_BarisInfo info, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(info.icon, size: 17, color: const Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (info.onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: const Color(0xFF4F46E5),
              tooltip: 'Ubah ${info.label}',
              onPressed: info.onEdit,
            ),
        ],
      ),
    );
  }

  /// Membuat widget kartu toggle pengaturan tema gelap/terang.
  Widget _kartuTema(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: widget.isDarkMode,
        onChanged: widget.onThemeToggle,
        secondary: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            size: 18,
            color: const Color(0xFF4F46E5),
          ),
        ),
        title: const Text(
          'Mode Gelap',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          widget.isDarkMode ? 'Tema gelap aktif' : 'Tema terang aktif',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Model pembantu untuk merender setiap baris data informasi pada kartu profil.
class _BarisInfo {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _BarisInfo({
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });
}
