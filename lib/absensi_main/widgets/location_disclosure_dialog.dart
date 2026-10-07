import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:absensi/absensi_main/screens/privacy_policy_screen.dart';

class LocationDisclosureDialog extends StatelessWidget {
  final bool isPermanentlyDenied;

  const LocationDisclosureDialog({
    super.key,
    this.isPermanentlyDenied = false,
  });

  /// Menampilkan dialog pemberitahuan izin lokasi sesuai ketentuan Google Play Store.
  /// Mengembalikan true jika pengguna menyetujui, false jika menolak.
  static Future<bool> show(
    BuildContext context, {
    bool isPermanentlyDenied = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationDisclosureDialog(
        isPermanentlyDenied: isPermanentlyDenied,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon & Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF1E3A8A),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPermanentlyDenied
                            ? 'Izin Lokasi Dinonaktifkan'
                            : 'Pemberitahuan Izin Lokasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Diperlukan untuk presensi presisi',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Google Play Prominent Disclosure Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aplikasi SAPTA memerlukan izin akses data lokasi Anda (ACCESS_FINE_LOCATION & ACCESS_COARSE_LOCATION) untuk:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'Memverifikasi bahwa Anda berada di dalam radius kantor / tempat pelatihan saat melakukan Absen Masuk dan Absen Pulang.',
                    isDark,
                  ),
                  const SizedBox(height: 4),
                  _buildBulletPoint(
                    'Mencatat koordinat dan nama alamat presensi untuk validasi kehadiran yang sah.',
                    isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Data Protection & Privacy Notice
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data lokasi Anda HANYA diakses saat aplikasi sedang aktif digunakan (Foreground Only) dan TIDAK PERNAH dilacak di latar belakang (background) ataupun dibagikan ke pihak ketiga.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Link ke Kebijakan Privasi
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () {
                  PrivacyPolicyScreen.showAsModal(context);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Pelajari selengkapnya di Kebijakan Privasi kami',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Nanti Saja',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: isPermanentlyDenied ? 2 : 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      if (isPermanentlyDenied) {
                        Navigator.of(context).pop(false);
                        await Geolocator.openAppSettings();
                      } else {
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: Text(
                      isPermanentlyDenied ? 'Buka Pengaturan' : 'Setuju & Lanjutkan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.blue.shade300 : const Color(0xFF1E3A8A),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
