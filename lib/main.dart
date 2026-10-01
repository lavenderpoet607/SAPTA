import 'package:flutter/material.dart';
import 'package:absensi/absensi_main/absensi.dart';

/// Titik masuk utama (entry point) aplikasi Flutter Absensi PPKD.
void main() {
  runApp(const MyApp());
}

/// Widget root aplikasi yang membungkus navigasi utama dan tema MaterialApp.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Absensi PPKD',
      debugShowCheckedModeBanner: false,
      home: Absensi(),
    );
  }
}
