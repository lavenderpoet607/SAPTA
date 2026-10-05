import 'package:flutter/material.dart';

/// Widget modal dialog konfirmasi interaktif untuk meminta persetujuan pengguna
/// sebelum mengeksekusi tindakan sensitif atau penting (Absen Masuk, Absen Pulang,
/// Hapus Absen, dan Keluar Akun).
///
/// Parameter:
/// - [title]: Judul dialog konfirmasi (wajib).
/// - [message]: Pesan penjelasan konfirmasi kepada pengguna (wajib).
/// - [confirmText]: Teks pada tombol konfirmasi persetujuan, default: 'Ya' (opsional).
/// - [cancelText]: Teks pada tombol batal, default: 'Batal' (opsional).
/// - [confirmColor]: Warna tombol konfirmasi (opsional).
/// - [icon]: Ikon header dialog (opsional).
/// - [contentWidget]: Widget konten tambahan yang disisipkan di antara pesan dan tombol (opsional).
/// - [isDestructive]: Menandakan apakah tindakan ini merusak/menghapus sehingga diberi styling merah, default: `false` (opsional).
///
/// Contoh Penggunaan:
/// ```dart
/// final confirmed = await showConfirmationDialog(
///   context: context,
///   title: 'Konfirmasi Absen Masuk',
///   message: 'Apakah Anda yakin ingin melakukan absen masuk saat ini?',
///   confirmText: 'Ya, Absen Masuk',
///   confirmColor: const Color(0xFF059669),
/// );
/// ```
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final Widget? contentWidget;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Ya',
    this.cancelText = 'Batal',
    this.confirmColor,
    this.icon,
    this.contentWidget,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveConfirmColor = confirmColor ?? (isDestructive ? Colors.red : const Color(0xFF1E3A8A));

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveConfirmColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: effectiveConfirmColor, size: 22),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
            if (contentWidget != null) ...[
              const SizedBox(height: 12),
              contentWidget!,
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveConfirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Fungsi pembantu untuk memunculkan modal [ConfirmationDialog] dengan mudah dan mengembalikan boolean `true`/`false`.
///
/// Parameter:
/// - [context]: BuildContext dari widget pemanggil (wajib).
/// - [title]: Judul dialog konfirmasi (wajib).
/// - [message]: Pesan penjelasan konfirmasi (wajib).
/// - [confirmText]: Label tombol aksi konfirmasi, default: 'Ya' (opsional).
/// - [cancelText]: Label tombol pembatalan, default: 'Batal' (opsional).
/// - [confirmColor]: Warna khusus untuk tombol konfirmasi (opsional).
/// - [icon]: Ikon header dialog (opsional).
/// - [contentWidget]: Widget kustom tambahan (opsional).
/// - [isDestructive]: Indikator aksi destruktif untuk styling bahaya, default: `false` (opsional).
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Ya',
  String cancelText = 'Batal',
  Color? confirmColor,
  IconData? icon,
  Widget? contentWidget,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: confirmColor,
      icon: icon,
      contentWidget: contentWidget,
      isDestructive: isDestructive,
    ),
  );
}
