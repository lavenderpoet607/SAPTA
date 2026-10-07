# Panduan Lengkap Perizinan & Rilis Google Play Store - SAPTA

Dokumen ini memandu Anda langkah demi langkah agar aplikasi **SAPTA (`com.sapta.absensi`)** lolos peninjauan (*review*) dan mendapatkan perizinan penuh dari **Google Play Store**.

---

## 1. Persiapan Kode yang Telah Diselesaikan
Proyek telah diperbarui dengan standar Google Play terbaru:
1. **Package Name Unik:** `com.sapta.absensi` (bebas dari nama default `com.example.*`).
2. **Prominent In-App Disclosure Dialog:** Dialog pemberitahuan izin lokasi muncul sebelum dialog sistem Android muncul, memenuhi kebijakan *Google Play Location Policy*.
3. **Pembersihan Background Location:** Izin `ACCESS_BACKGROUND_LOCATION` telah dihapus secara eksplisit menggunakan `tools:node="remove"`, mencegah penolakan otomatis dari bot Google Play.
4. **Halaman Kebijakan Privasi di Dalam Aplikasi:** Dapat diakses langsung dari menu Profil, halaman Login, dan dialog izin lokasi.
5. **Dukungan Keystore Release:** `build.gradle.kts` telah siap membaca `key.properties` untuk *signing* rilis.

---

## 2. Cara Mengisi Formulir di Google Play Console

### A. Kebijakan Privasi (Privacy Policy)
1. Buka **Google Play Console** > Pilih Aplikasi Anda.
2. Di menu samping, buka **Konten aplikasi (App Content)** > **Kebijakan Privasi (Privacy Policy)**.
3. Masukkan tautan/URL halaman Kebijakan Privasi Anda (Anda dapat mengunggah file `PRIVACY_POLICY.md` ini ke GitHub Pages, Google Sites, atau website instansi Anda).

---

### B. Formulir Keamanan Data (Data Safety Form)
Di menu **Konten aplikasi** > **Keamanan Data (Data Safety)**, jawab pertanyaan berikut:

1. **Apakah aplikasi Anda mengumpulkan atau membagikan data pengguna?**
   * Pilih: **Ya**
2. **Apakah semua data pengguna yang dikumpulkan oleh aplikasi Anda dienkripsi saat transit?**
   * Pilih: **Ya** (Semua API menggunakan HTTPS/SSL)
3. **Apakah Anda menyediakan cara bagi pengguna untuk meminta penghapusan data mereka?**
   * Pilih: **Ya**
4. **Kategori Data yang Dikumpulkan:**
   * **Lokasi (Location):**
     * Centang: **Lokasi Perkiraan (Approximate Location)** dan **Lokasi Presisi (Precise Location)**.
     * Dikumpulkan? **Ya**
     * Dibagikan ke pihak ketiga? **Tidak**
     * Apakah diproses secara efemeral? **Tidak** (disimpan di database server untuk catatan riwayat presensi).
     * Apakah data ini wajib bagi pengguna? **Ya, fungsi aplikasi tidak dapat berjalan tanpa data ini** (untuk validasi radius kantor).
     * Tujuan pengumpulan: Centang **Fungsi Aplikasi (App functionality)**.
   * **Informasi Pribadi (Personal Info):**
     * Centang: **Nama (Name)** dan **Alamat Email (Email address)**.
     * Tujuan: **Fungsi Aplikasi (App functionality)** dan **Pengelolaan Akun (Account management)**.

---

### C. Deklarasi Izin Lokasi (Location Permission Declaration)
Jika Google Play meminta penjelasan mengenai penggunaan izin lokasi:
* **Pertanyaan:** *Mengapa aplikasi memerlukan izin lokasi presisi?*
* **Jawaban Rekomendasi:**
  > "Aplikasi SAPTA adalah aplikasi presensi pegawai dan peserta pelatihan. Izin akses lokasi presisi (ACCESS_FINE_LOCATION) hanya diakses di latar depan (foreground) saat pengguna menekan tombol Absen Masuk atau Absen Pulang untuk memvalidasi bahwa pengguna berada dalam batas radius lokasi kantor atau tempat pelatihan yang sah (PPKD Jakarta Pusat)."
* **Apakah aplikasi menggunakan lokasi di latar belakang (background)?**
  * Pilih: **TIDAK (No, foreground only)**.

---

## 3. Cara Membuat File Rilis (.aab) untuk Play Store

### Langkah 1: Buat Upload Keystore (Jika Belum Ada)
Buka terminal dan jalankan perintah berikut (ganti kata sandi sesuai kebutuhan):
```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Langkah 2: Buat File `android/key.properties`
Buat file baru di `android/key.properties` (lihat contoh di `android/key.properties.example`):
```properties
keyAlias=upload
keyPassword=kata_sandi_key_anda
storeFile=../upload-keystore.jks
storePassword=kata_sandi_keystore_anda
```

### Langkah 3: Build Android App Bundle (.aab)
Jalankan perintah Flutter build:
```bash
flutter build appbundle --release
```
File hasil rilis akan berada di:
`build/app/outputs/bundle/release/app-release.aab`

File `.aab` inilah yang Anda unggah ke **Google Play Console** pada menu **Produksi (Production)** atau **Pengujian Terbuka/Tertutup (Testing Track)**.
