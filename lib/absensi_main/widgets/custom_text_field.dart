import 'package:flutter/material.dart';

/// Widget input teks modular dan reusable yang menyediakan styling seragam,
/// validasi input, kontrol visibilitas sandi, serta ikon awalan/akhiran.
///
/// Digunakan pada formulir autentikasi (Login, Register) dan dialog edit data (Ubah Nama).
///
/// Parameter:
/// - [controller]: Pengendali teks untuk membaca atau memodifikasi nilai input (opsional).
/// - [label]: Label teks formulir yang ditampilkan di atas atau di dalam field (wajib).
/// - [hintText]: Teks petunjuk saat input masih kosong (opsional).
/// - [prefixIcon]: Ikon yang ditempatkan di sisi kiri field (opsional).
/// - [suffixIcon]: Widget yang ditempatkan di sisi kanan field, misalnya tombol mata untuk password (opsional).
/// - [obscureText]: Menyembunyikan karakter teks untuk input sandi/password, default: `false` (opsional).
/// - [keyboardType]: Tipe keyboard virtual yang ditampilkan, default: `TextInputType.text` (opsional).
/// - [validator]: Fungsi callback untuk memvalidasi teks input (opsional).
/// - [maxLines]: Jumlah baris maksimum input, default: 1 (opsional).
/// - [autofocus]: Menentukan apakah field langsung mendapat fokus saat terbuka, default: `false` (opsional).
/// - [onChanged]: Callback saat teks input mengalami perubahan (opsional).
///
/// Contoh Penggunaan:
/// ```dart
/// CustomTextField(
///   controller: _emailController,
///   label: 'Email',
///   hintText: 'nama@email.com',
///   prefixIcon: Icons.email_outlined,
///   keyboardType: TextInputType.emailAddress,
///   validator: (value) => value == null || value.isEmpty ? 'Email wajib diisi' : null,
/// );
/// ```
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.autofocus = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
    );
  }
}
