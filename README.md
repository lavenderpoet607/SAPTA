<div align="center">
  <img src="assets/images/app_logo.png" alt="SAPTA Logo" width="120" />

  # 📱 SAPTA
  ### Sistem Aplikasi Presensi & Tracking Absensi

  [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://www.android.com/)
  [![Version](https://img.shields.io/badge/version-1.0.0%2B1-blue?style=for-the-badge)](#)

  <p align="center">
    Aplikasi mobile presensi berbasis Flutter yang modern, akurat, dan efisien dengan validasi lokasi berbasis GPS (Geolocator) dan integrasi Google Maps.
  </p>
</div>

---

## 📌 Tentang Aplikasi

**SAPTA** dirancang untuk memudahkan pencatatan kehadiran karyawan/pegawai secara real-time. Dengan memanfaatkan teknologi geolokasi dan antarmuka yang intuitif, aplikasi ini memastikan kehadiran dicatat secara valid berdasarkan posisi fisik pengguna.

Aplikasi ini juga dilengkapi visualisasi waktu analog & digital, ringkasan statistik kehadiran, serta riwayat presensi yang transparan.

---

## ✨ Fitur Utama

- 🔐 **Autentikasi Pengguna**: Login & Registrasi akun dengan penyimpanan sesi (*Session Management*) yang aman.
- 🕒 **Jam Analog & Digital Real-time**: Tampilan waktu presisi langsung di halaman utama.
- 📍 **Presensi Berbasis Lokasi (GPS)**:
  - Deteksi koordinat pengguna secara otomatis menggunakan `geolocator`.
  - Konversi koordinat menjadi alamat lengkap (*Reverse Geocoding*).
  - Tampilan peta interaktif menggunakan `google_maps_flutter`.
- 📊 **Dashboard & Statistik Kehadiran**:
  - Banner status kehadiran hari ini (Jam Masuk & Jam Pulang).
  - Kartu statistik (Hadir, Izin, Terlambat).
- 📜 **Riwayat Presensi Lengkap**:
  - Daftar riwayat kehadiran harian/bulanan.
  - Filter pencarian dan status kehadiran.
  - Detail lokasi absensi beserta peta.
- 🌓 **Dukungan Dark & Light Mode**: Tampilan fleksibel yang nyaman untuk mata pengguna di berbagai kondisi pencahayaan.
- 👤 **Manajemen Profil**: Pengelolaan informasi akun pengguna dan kontrol logout sesi.

---

## 🏗️ Struktur Proyek

```text
absensi/
├── android/                   # Konfigurasi platform Android
├── assets/
│   └── images/                # Aset gambar & logo aplikasi
├── lib/
│   ├── absensi_main/
│   │   ├── helpers/           # Helper utilitas UI & formatting
│   │   ├── models/            # Model data aplikasi
│   │   ├── reusable/          # Konstanta & styling bersama
│   │   ├── screens/           # Tampilan utama:
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── history_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── map_detail_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── services/          # Layanan API, Lokasi (GPS), & Sesi
│   │   │   ├── api_service.dart
│   │   │   ├── location_service.dart
│   │   │   └── session_manager.dart
│   │   ├── widgets/           # Komponen widget kustom (Clock, Card, dll.)
│   │   └── absensi.dart       # Wrapper navigasi & state utama
│   └── main.dart              # Entry point aplikasi Flutter
└── pubspec.yaml               # Dependensi & konfigurasi aset
```

---

## 🛠️ Teknologi & Dependensi

| Paket / Library | Versi | Fungsi |
|---|---|---|
| [Flutter](https://flutter.dev) | SDK ^3.13.3 | Framework UI Multiplatform |
| [geolocator](https://pub.dev/packages/geolocator) | ^14.1.1 | Pengambilan posisi GPS perangkat |
| [geocoding](https://pub.dev/packages/geocoding) | ^5.0.0 | Konversi koordinat latitude/longitude ke alamat |
| [google_maps_flutter](https://pub.dev/packages/google_maps_flutter) | ^2.18.2 | Integrasi peta Google Maps |
| [dio](https://pub.dev/packages/dio) | ^5.11.1 | HTTP Client untuk integrasi REST API |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | ^2.5.5 | Penyimpanan sesi & preferensi tema lokal |
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) | ^0.14.3 | Generator ikon aplikasi Android/iOS |

---

## 🚀 Memulai (Getting Started)

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.13.3 atau lebih baru)
- [Android Studio](https://developer.android.com/studio) / VS Code
- Perangkat Android fisik atau Emulator Android dengan Google Play Services (untuk Google Maps)

### Langkah Instalasi

1. **Clone repositori**:
   ```bash
   git clone https://github.com/username/sapta.git
   cd absensi
   ```

2. **Pasang seluruh dependensi**:
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Izin Android**:
   Pastikan izin lokasi telah aktif di `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   ```

4. **Jalankan aplikasi (Development)**:
   ```bash
   flutter run
   ```

5. **Build APK Rilis (Production)**:
   ```bash
   flutter build apk --release
   ```
   *File APK keluaran dapat ditemukan di: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 📄 Lisensi

Proyek ini dikembangkan untuk kebutuhan pelatihan dan pengelolaan absensi internal.

