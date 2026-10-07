import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static Future<void> showAsModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.9,
        child: PrivacyPolicyScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.privacy_tip_rounded,
                        color: Color(0xFF1E3A8A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kebijakan Privasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Aplikasi Presensi SAPTA • Terakhir diperbarui: Oktober 2026',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildIntroCard(isDark),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.location_on_rounded,
                  title: '1. Penggunaan & Izin Lokasi (Location Data)',
                  content:
                      'Aplikasi SAPTA memerlukan izin akses lokasi presisi (ACCESS_FINE_LOCATION) dan perkiraan (ACCESS_COARSE_LOCATION) saat aplikasi aktif digunakan (Foreground Only).\n\n'
                      '• Tujuan: Data lokasi Anda dikumpulkan saat Anda menekan tombol "Absen Masuk" atau "Absen Pulang" untuk memvalidasi bahwa Anda berada dalam radius area kerja / kantor pelatihan yang telah ditentukan (seperti PPKD Jakarta Pusat).\n'
                      '• Latar Belakang (Background): Aplikasi SAPTA TIDAK mengakses, melacak, atau mengumpulkan data lokasi saat aplikasi ditutup atau berjalan di latar belakang (background).\n'
                      '• Pembagian Pihak Ketiga: Titik koordinat dan alamat Anda hanya disimpan pada server instansi untuk keperluan absensi dan tidak pernah dijual atau dibagikan kepada pihak ketiga untuk kepentingan iklan.',
                  isDark: isDark,
                ),
                _buildSection(
                  icon: Icons.badge_rounded,
                  title: '2. Informasi Pribadi Pengguna',
                  content:
                      'Saat Anda mendaftar atau masuk ke akun SAPTA, kami mengumpulkan:\n'
                      '• Nama Lengkap dan Alamat Email untuk identifikasi akun peserta/pegawai.\n'
                      '• Kata Sandi yang disimpan dalam bentuk hash terenkripsi aman.\n'
                      '• Riwayat presensi, termasuk tanggal, jam check-in/out, status kehadiran, dan foto selfie (jika diaktifkan oleh institusi).',
                  isDark: isDark,
                ),
                _buildSection(
                  icon: Icons.security_rounded,
                  title: '3. Keamanan Data',
                  content:
                      'Kami menerapkan protokol keamanan standar industri untuk melindungi data Anda. Seluruh komunikasi data antara aplikasi SAPTA dan server pusat diamankan menggunakan enkripsi SSL/TLS (HTTPS). Token autentikasi disimpan secara terenkripsi di penyimpanan lokal perangkat Anda.',
                  isDark: isDark,
                ),
                _buildSection(
                  icon: Icons.delete_outline_rounded,
                  title: '4. Hak Pengguna & Penghapusan Data (Account Deletion)',
                  content:
                      'Sesuai dengan kebijakan Google Play, Anda memiliki hak penuh untuk meminta peninjauan, pembaruan, atau penghapusan permanen atas akun dan data pribadi Anda. Anda dapat menghubungi administrator pelatihan atau mengirimkan permintaan penghapusan akun ke email pengembang.',
                  isDark: isDark,
                ),
                _buildSection(
                  icon: Icons.support_agent_rounded,
                  title: '5. Hubungi Kami',
                  content:
                      'Jika Anda memiliki pertanyaan seputar Kebijakan Privasi atau izin aplikasi ini, silakan hubungi tim kami:\n'
                      '• Email: support@sapta.id / admin@sapta.id\n'
                      '• Instansi: PPKD Jakarta Pusat, DKI Jakarta\n'
                      '• Website: https://sapta.id',
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Saya Mengerti',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFF1E3A8A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aplikasi SAPTA berkomitmen menjaga privasi data Anda. Kebijakan ini menjelaskan bagaimana data dan izin lokasi Anda digunakan demi kepatuhan kebijakan Google Play Store.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF1E3A8A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
