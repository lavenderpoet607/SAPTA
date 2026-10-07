# Kebijakan Privasi - SAPTA (Sistem Aplikasi Presensi & Absensi)

**Terakhir Diperbarui:** 7 Oktober 2026  
**Pengembang:** Tim SAPTA  
**Aplikasi:** SAPTA (com.sapta.absensi)  
**Kontak:** support@sapta.id / admin@sapta.id  

---

## 1. Pendahuluan
Aplikasi **SAPTA** menghormati privasi pengguna dan berkomitmen untuk melindungi informasi pribadi Anda. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi informasi pribadi serta data izin perangkat Anda sesuai dengan ketentuan dan kebijakan pengembang **Google Play Store**.

---

## 2. Data yang Dikumpulkan dan Tujuannya

### A. Izin dan Data Lokasi (Location Data)
* **Jenis Data:** Lokasi Presisi (`ACCESS_FINE_LOCATION` via GPS) dan Lokasi Perkiraan (`ACCESS_COARSE_LOCATION` via Jaringan Seluler/Wi-Fi).
* **Tujuan Pengumpulan:** Data lokasi Anda dikumpulkan secara eksklusif saat Anda melakukan aksi **"Absen Masuk"** atau **"Absen Pulang"** untuk memvalidasi radius kehadiran fisik Anda di lokasi kantor / pelatihan resmi (seperti PPKD Jakarta Pusat).
* **Mode Penggunaan (Foreground Only):** Aplikasi SAPTA **HANYA** mengakses data lokasi saat aplikasi sedang aktif dibuka dan digunakan oleh pengguna di layar (Foreground).
* **Tidak Ada Pelacakan Latar Belakang (No Background Location):** Aplikasi SAPTA **TIDAK PERNAH** melacak, memonitor, atau mengumpulkan lokasi Anda di latar belakang saat aplikasi diminimalkan atau ditutup.
* **Pembagian Data:** Titik koordinat dan alamat yang terdeteksi disimpan di server instansi semata-mata untuk verifikasi absensi dan **TIDAK PERNAH dibagikan atau dijual ke pihak ketiga atau jaringan periklanan**.

### B. Informasi Akun Pengguna
* **Data:** Nama Lengkap, Alamat Email, Peran/Role Peserta/Pegawai.
* **Tujuan:** Autentikasi identitas, login akun, dan pelaporan absensi yang sah.
* **Kata Sandi:** Disimpan dalam bentuk hash kriptografi satu arah yang aman.

### C. Data Aktivitas Presensi
* **Data:** Tanggal dan jam check-in/check-out, status kehadiran (Masuk/Izin/Selesai), serta alasan izin (jika mengajukan izin).

---

## 3. Keamanan Data (Data Security)
Kami menerapkan standar keamanan teknis yang ketat:
* Seluruh pertukaran data antara aplikasi SAPTA dan server backend dienkripsi menggunakan protokol **HTTPS / TLS (SSL)** berstandar industri.
* Kunci sesi dan token autentikasi disimpan secara aman di dalam penyimpanan lokal terisolasi pada perangkat Anda.

---

## 4. Retensi dan Penghapusan Data (Account & Data Deletion)
Sesuai dengan kebijakan Google Play mengenai Penghapusan Akun:
* Data kehadiran Anda disimpan selama periode pelatihan atau masa kerja Anda aktif di instansi terkait.
* Anda berhak mengajukan permohonan peninjauan, pembetulan, atau **penghapusan akun dan data pribadi** secara permanen dengan menghubungi administrator instansi atau melalui email: `support@sapta.id`.

---

## 5. Kepatuhan Kebijakan Pengembang Google Play
Aplikasi ini tunduk pada kebijakan:
1. **User Data Policy & Prominent Disclosure:** Aplikasi menampilkan dialog pemberitahuan izin lokasi di dalam aplikasi sebelum dialog izin runtime Android ditampilkan.
2. **Foreground Service & Location Exemption:** Aplikasi tidak meminta izin `ACCESS_BACKGROUND_LOCATION`.
3. **Data Safety:** Detail transmisi data dideklarasikan secara transparan pada formulir Keamanan Data di Google Play Console.

---

## 6. Perubahan Kebijakan Privasi
Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Pembaruan akan ditampilkan melalui halaman ini dan pembaruan aplikasi.

---

## 7. Kontak Kami
Jika Anda memiliki pertanyaan seputar Kebijakan Privasi ini, silakan hubungi:
* **Email:** support@sapta.id
* **Alamat:** PPKD Jakarta Pusat, DKI Jakarta, Indonesia
* **Website:** https://sapta.id
