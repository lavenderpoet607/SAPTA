/// Kumpulan fungsi pembantu (utility helper) modular untuk kalkulasi waktu,
/// pembuatan salam jam sistem, serta pemformatan tanggal dan waktu berbahasa Indonesia.
class DateHelper {
  /// Daftar nama hari dalam bahasa Indonesia (dimulai dari Senin).
  static const List<String> days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Daftar nama bulan dalam bahasa Indonesia (dimulai dari Januari).
  static const List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  /// Menghasilkan teks ucapan salam ('Selamat Pagi', 'Selamat Siang', 'Selamat Sore', 'Selamat Malam')
  /// berdasarkan waktu jam saat fungsi dipanggil.
  ///
  /// Parameter:
  /// - [time]: Waktu DateTime yang diuji. Jika `null`, menggunakan waktu sistem saat ini (opsional).
  ///
  /// Contoh:
  /// ```dart
  /// final greeting = DateHelper.getGreeting(); // 'Selamat Pagi'
  /// ```
  static String getGreeting([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  /// Mengonversi objek [DateTime] menjadi format teks tanggal lengkap berbahasa Indonesia
  /// (contoh: 'Kamis, 2 Oktober 2026').
  ///
  /// Parameter:
  /// - [date]: Waktu tanggal yang ingin diformat. Jika `null`, menggunakan waktu saat ini (opsional).
  ///
  /// Contoh:
  /// ```dart
  /// final dateStr = DateHelper.formatIndonesianDate(); // 'Kamis, 2 Oktober 2026'
  /// ```
  static String formatIndonesianDate([DateTime? date]) {
    final now = date ?? DateTime.now();
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  /// Mengembalikan string tanggal hari ini dalam format YYYY-MM-DD.
  ///
  /// Parameter:
  /// - [date]: Tanggal acuan (opsional).
  static String getTodayKey([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Mengambil representasi tanggal 'YYYY-MM-DD' dari teks tanggal API.
  ///
  /// Parameter:
  /// - [rawDate]: Teks tanggal mentah dari API (opsional).
  static String extractDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    final clean = rawDate.replaceAll('T', ' ').split('.').first.trim();
    if (clean.length >= 10) return clean.substring(0, 10);
    return clean;
  }

  /// Mengambil representasi jam 'HH:mm' dari teks waktu API.
  ///
  /// Parameter:
  /// - [rawTime]: Teks waktu mentah dari API (opsional).
  static String extractTime(String? rawTime) {
    if (rawTime == null || rawTime.isEmpty) return '-';
    final clean = rawTime.replaceAll('T', ' ');
    final parts = clean.split(' ');
    if (parts.length >= 2) {
      final timePart = parts[1].split('.').first;
      return timePart.length >= 5 ? timePart.substring(0, 5) : timePart;
    }
    return '-';
  }
}
