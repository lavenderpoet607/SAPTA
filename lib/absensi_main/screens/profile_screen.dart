import 'package:flutter/material.dart';
import 'package:absensi/absensi_main/helpers/ui_helper.dart';
import 'package:absensi/absensi_main/models/absen_model.dart';
import 'package:absensi/absensi_main/models/user_model.dart';
import 'package:absensi/absensi_main/services/api_service.dart';
import 'package:absensi/absensi_main/services/session_manager.dart';
import 'package:absensi/absensi_main/widgets/confirmation_dialog.dart';
import 'package:absensi/absensi_main/reusable/custom_text_field.dart';
import 'package:absensi/absensi_main/widgets/detail_info_row.dart';
import 'package:absensi/absensi_main/widgets/header_banner_card.dart';
import 'package:absensi/absensi_main/widgets/primary_button.dart';
import 'package:absensi/absensi_main/widgets/stat_card.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final bool isDarkMode;
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
          title: const Text(
            'Ubah Nama Pengguna',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                CustomTextField(
                  controller: controller,
                  autofocus: true,
                  label: 'Nama',
                  hintText: 'Contoh: Budi Santoso',
                  prefixIcon: Icons.person_outline_rounded,
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
      UiHelper.showSnackBar(
        context,
        'Nama pengguna berhasil diperbarui!',
        behavior: SnackBarBehavior.floating,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      UiHelper.showSnackBar(
        context,
        'Gagal memperbarui nama: $e',
        isError: true,
        behavior: SnackBarBehavior.floating,
      );
    }
  }

  Future<void> _konfirmasiLogout() async {
    final konfirmasi = await showConfirmationDialog(
      context: context,
      title: 'Keluar Akun',
      message: 'Anda yakin ingin keluar dari akun ini? Sesi absensi Anda akan diakhiri.',
      confirmText: 'Keluar',
      confirmColor: Colors.red,
      icon: Icons.logout_rounded,
      isDestructive: true,
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

  int get _totalHadir => _riwayat.where((a) => !a.isIzin).length;

  int get _totalIzin => _riwayat.where((a) => a.isIzin).length;

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
          HeaderBannerCard(
            userName: user?.name ?? 'Peserta PPKD',
            subtitle: user?.email ?? '-',
            badgeText: user?.role ?? 'peserta',
            avatarText: user?.inisial ?? 'P',
            avatarOnLeft: true,
            gradientColors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            onEdit: () => _tampilkanDialogEditNama(user?.name),
            onRefresh: _muatData,
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) _kartuPeringatan(isDark),
          _judulSeksi('Ringkasan Absensi', isDark),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Hadir',
                  value: _totalHadir,
                  color: const Color(0xFF059669),
                  icon: Icons.how_to_reg_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Izin',
                  value: _totalIzin,
                  color: const Color(0xFFD97706),
                  icon: Icons.pending_actions_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatCard(
                  label: 'Pulang',
                  value: _totalPulang,
                  color: const Color(0xFF2563EB),
                  icon: Icons.task_alt_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _judulSeksi('Data Peserta Pelatihan', isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                DetailInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Nama Peserta',
                  value: user?.name ?? '-',
                  isDark: isDark,
                  onEdit: () => _tampilkanDialogEditNama(user?.name),
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : Colors.grey.shade200,
                ),
                DetailInfoRow(
                  icon: Icons.alternate_email_rounded,
                  label: 'Email Akun',
                  value: user?.email ?? '-',
                  isDark: isDark,
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF334155)
                      : Colors.grey.shade200,
                ),
                DetailInfoRow(
                  icon: Icons.verified_user_rounded,
                  label: 'Peran / Status',
                  value: user?.role ?? 'peserta',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _judulSeksi('Pengaturan', isDark),
          const SizedBox(height: 10),
          _kartuTema(isDark),
          const SizedBox(height: 22),
          PrimaryButton(
            text: 'KELUAR AKUN',
            isLoading: _isLoggingOut,
            onPressed: _konfirmasiLogout,
            backgroundColor: Colors.red.shade600,
            icon: Icons.logout_rounded,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'SAPTA',
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
