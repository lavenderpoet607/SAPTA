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

- 🔐 **Autentikasi Pengguna**: Login & Registrasi akun dengan penyimpanan sesi (_Session Management_) yang aman.
- 🕒 **Jam Analog & Digital Real-time**: Tampilan waktu presisi langsung di halaman utama.
- 📍 **Presensi Berbasis Lokasi (GPS)**:
  - Deteksi koordinat pengguna secara otomatis menggunakan `geolocator`.
  - Konversi koordinat menjadi alamat lengkap (_Reverse Geocoding_).
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

### 🔄 Flowchart Arsitektur & Prosedur Aplikasi

```mermaid
flowchart TD
    classDef terminal fill:#0891b2,stroke:#06b6d4,stroke-width:2px,color:#ffffff,rx:15,ry:15;
    classDef process fill:#1e293b,stroke:#3b82f6,stroke-width:2px,color:#f8fafc,rx:4,ry:4;
    classDef decision fill:#7c2d12,stroke:#f97316,stroke-width:2px,color:#ffedd5;
    classDef storage fill:#581c87,stroke:#a855f7,stroke-width:2px,color:#f3e8ff;
    classDef inputOut fill:#134e4a,stroke:#14b8a6,stroke-width:2px,color:#ccfbf1;
    classDef subproc fill:#1e1b4b,stroke:#6366f1,stroke-width:2px,color:#e0e7ff;

    StartApp([START: Android Native Host<br/>android/MainActivity.kt]):::terminal --> RunMain[lib/main.dart<br/>runApp: MyApp]:::process
    RunMain --> RunAbsensi[lib/absensi_main/absensi.dart<br/>Wrapper Navigasi & Mode Tema]:::process

    RunAbsensi --> DecLogin{Sudah Ada Sesi Login?<br/>session_manager.dart}:::decision

    DecLogin -->|Tidak| FormLogin[/Input Form: Username & Password<br/>reusable/custom_text_field.dart/]:::inputOut
    FormLogin --> RunLogin[screens/login_screen.dart]:::process
    RunLogin -->|Belum Punya Akun| RunReg[screens/register_screen.dart]:::process
    RunReg --> RunLogin
    RunLogin --> SaveSession[(services/session_manager.dart<br/>Simpan ke SharedPreferences)]:::storage

    DecLogin -->|Ya| ViewDash[screens/dashboard_screen.dart<br/>Analog Clock & Kartu Statistik]:::process
    SaveSession -.->|Arahkan ke Dashboard| ViewDash

    ViewDash --> DecAction{Pilih Menu / Aksi Presensi?}:::decision

    DecAction -->|1. Presensi Masuk / Pulang| DecGPS{Izin GPS & Internet Aktif?<br/>android/AndroidManifest.xml}:::decision

    DecGPS -->|Belum Aktif| ReqPerm[Request Permission Dialog<br/>widgets/confirmation_dialog.dart]:::process
    ReqPerm --> DecGPS

    DecGPS -->|Aktif| RunGPS[services/location_service.dart<br/>Geolocator GPS & Geocoding Alamat]:::process
    RunGPS --> RunAPI[[services/api_service.dart<br/>Kirim HTTP POST via Dio]]:::subproc

    RunAPI --> ParseModel[models/absen_model.dart<br/>Mapping Data Response]:::process
    ParseModel --> UpdateData[(Update Status Kehadiran Hari Ini)]:::storage
    UpdateData --> Finish([FINISH: Presensi Berhasil Tercatat]):::terminal

    DecAction -->|2. Riwayat Presensi| ViewHist[screens/history_screen.dart]:::process
    ViewHist --> ViewMap[screens/map_detail_screen.dart<br/>Google Maps Flutter]:::process
    ViewMap --> Finish

    DecAction -->|3. Kelola Profil & Logout| ViewProf[screens/profile_screen.dart]:::process
    ViewProf --> DecLogout{Konfirmasi Logout?}:::decision
    DecLogout -->|Ya: Hapus Token| SaveSession
    DecLogout -->|Batal| ViewDash
```

---

## 🛠️ Teknologi & Dependensi

| Paket / Library                                                           | Versi       | Fungsi                                          |
| ------------------------------------------------------------------------- | ----------- | ----------------------------------------------- |
| [Flutter](https://flutter.dev)                                            | SDK ^3.13.3 | Framework UI Multiplatform                      |
| [geolocator](https://pub.dev/packages/geolocator)                         | ^14.1.1     | Pengambilan posisi GPS perangkat                |
| [geocoding](https://pub.dev/packages/geocoding)                           | ^5.0.0      | Konversi koordinat latitude/longitude ke alamat |
| [google_maps_flutter](https://pub.dev/packages/google_maps_flutter)       | ^2.18.2     | Integrasi peta Google Maps                      |
| [dio](https://pub.dev/packages/dio)                                       | ^5.11.1     | HTTP Client untuk integrasi REST API            |
| [shared_preferences](https://pub.dev/packages/shared_preferences)         | ^2.5.5      | Penyimpanan sesi & preferensi tema lokal        |
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) | ^0.14.3     | Generator ikon aplikasi Android/iOS             |

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
   _File APK keluaran dapat ditemukan di: `build/app/outputs/flutter-apk/app-release.apk`_

---

## 📄 Lisensi

Proyek ini dikembangkan untuk kebutuhan pelatihan dan pengelolaan absensi internal.
