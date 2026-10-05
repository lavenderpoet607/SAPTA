import 'package:flutter/material.dart';

/// Kumpulan fungsi pembantu (utility helper) untuk menampilkan elemen antarmuka umum
/// seperti SnackBar pemberitahuan status sukses maupun galat.
class UiHelper {
  /// Menampilkan SnackBar notifikasi di layar dengan warna dan durasi yang konsisten.
  ///
  /// Parameter:
  /// - [context]: BuildContext layar aplikasi (wajib).
  /// - [message]: Pesan teks yang ingin disampaikan kepada pengguna (wajib).
  /// - [isError]: Menandakan apakah notifikasi ini merupakan error (merah) atau sukses (hijau), default: `false` (opsional).
  /// - [backgroundColor]: Warna latar belakang kustom jika ingin warna selain default hijau/merah (opsional).
  /// - [behavior]: Penempatan SnackBar (misal: SnackBarBehavior.floating), default: `SnackBarBehavior.fixed` (opsional).
  ///
  /// Contoh:
  /// ```dart
  /// UiHelper.showSnackBar(context, 'Data berhasil disimpan');
  /// UiHelper.showSnackBar(context, 'Terjadi kesalahan jaringan', isError: true);
  /// ```
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Color? backgroundColor,
    SnackBarBehavior? behavior,
  }) {
    final effectiveBg = backgroundColor ?? (isError ? Colors.red : const Color(0xFF059669));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: effectiveBg,
        behavior: behavior,
      ),
    );
  }
}
