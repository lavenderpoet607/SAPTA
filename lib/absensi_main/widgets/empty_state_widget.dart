import 'package:flutter/material.dart';

/// Widget modular untuk menampilkan kondisi kosong (empty state) atau kondisi galat (error state)
/// dengan visual ikon, teks keterangan, dan tombol aksi perbaikan (seperti muat ulang).
///
/// Digunakan pada Riwayat Absensi dan Dashboard saat data kosong atau gagal dimuat dari server.
///
/// Parameter:
/// - [title]: Judul pesan kondisi kosong/galat (wajib).
/// - [message]: Pesan penjelasan rincian kondisi (wajib).
/// - [icon]: Ikon representatif kondisi, default: `Icons.inbox_outlined` (opsional).
/// - [iconColor]: Warna ikon penanda (opsional).
/// - [onRetry]: Callback fungsi untuk mencoba memuat kembali data jika terjadi galat (opsional).
/// - [retryText]: Teks label tombol coba lagi, default: 'Coba Lagi' (opsional).
/// - [isDark]: Penyesuaian tema mode gelap untuk kontainer (opsional).
///
/// Contoh Penggunaan:
/// ```dart
/// EmptyStateWidget(
///   title: 'Belum ada data',
///   message: 'Riwayat absensi akan muncul setelah Anda melakukan presensi.',
///   icon: Icons.inbox_outlined,
///   onRetry: _loadHistory,
/// );
/// ```
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onRetry;
  final String retryText;
  final bool? isDark;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.onRetry,
    this.retryText = 'Coba Lagi',
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final effectiveIconColor = iconColor ?? (effectiveDark ? Colors.grey.shade400 : Colors.grey.shade500);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: effectiveDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: effectiveIconColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: effectiveDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(retryText),
            ),
          ],
        ],
      ),
    );
  }
}
