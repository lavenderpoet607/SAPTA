import 'package:flutter/material.dart';

/// Widget baris informasi detail modular yang menyusun ikon, label nama, dan nilai teks
/// secara konsisten dan rapi, serta mendukung tombol aksi edit jika data dapat diubah.
///
/// Digunakan pada lembar detail riwayat absensi, rincian profil peserta, dan panel detail lokasi peta.
///
/// Parameter:
/// - [icon]: Ikon penanda jenis informasi (wajib).
/// - [label]: Nama label atribut informasi, contoh: 'Alamat' atau 'Jam Masuk' (wajib).
/// - [value]: Teks isi dari atribut informasi yang ditampilkan (wajib).
/// - [iconColor]: Warna kustom untuk ikon penanda (opsional).
/// - [onEdit]: Callback tombol aksi edit jika atribut dapat diubah oleh pengguna (opsional).
/// - [labelWidth]: Lebar area teks label agar semua baris sejajar, default: 88.0 (opsional).
/// - [isDark]: Menentukan apakah tampilan disesuaikan dengan tema gelap (opsional).
///
/// Contoh Penggunaan:
/// ```dart
/// DetailInfoRow(
///   icon: Icons.location_on_outlined,
///   label: 'Alamat',
///   value: 'Jl. Kebon Sirih No. 12',
/// );
/// ```
class DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final VoidCallback? onEdit;
  final double labelWidth;
  final bool? isDark;

  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.onEdit,
    this.labelWidth = 88.0,
    this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final effectiveColor = iconColor ?? const Color(0xFF4F46E5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: effectiveColor),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: effectiveDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: effectiveColor,
              tooltip: 'Ubah $label',
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
