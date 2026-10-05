import 'package:flutter/material.dart';
import 'package:absensi/absensi_main/absensi.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SAPTA',
      debugShowCheckedModeBanner: false,
      home: Absensi(),
    );
  }
}
