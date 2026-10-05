import 'package:flutter/material.dart';

/// Widget kartu ringkasan statistik modular untuk menampilkan metrik kehadiran
/// berupa angka hitungan, label status, warna aksen, dan ikon penanda.
///
/// Digunakan pada Dashboard, Riwayat Absensi, dan Profil Pengguna untuk menampilkan
/// ringkasan presensi Masuk, Izin, dan Selesai/Pulang secara konsisten.
///
/// Parameter:
/// - [label]: Teks deskripsi kategori statistik, contoh: 'Total Masuk' atau 'Hadir' (wajib).
/// - [value]: Nilai numerik atau teks statistik yang ditampilkan secara menonjol (wajib).
/// - [color]: Warna tema aksen untuk teks angka, garis border, dan ikon (wajib).
/// - [icon]: Ikon penanda metrik di sudut kartu (opsional).
/// - [isDark]: Nilai boolean untuk menyesuaikan warna latar belakang kartu dengan mode gelap (opsional).
/// - [onTap]: Callback opsional jika kartu statistik dapat diklik (opsional).
///
/// Contoh Penggunaan:
/// ```dart
/// StatCard(
///   label: 'Total Masuk',
///   value: 12,
///   color: const Color(0xFF059669),
///   icon: Icons.check_circle_outline_rounded,
/// );
/// ```
class StatCard extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;
  final IconData? icon;
  final bool? isDark;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final bgColor = effectiveDark ? const Color(0xFF1E293B) : Colors.white;

    Widget cardContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: icon != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
          ],
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
