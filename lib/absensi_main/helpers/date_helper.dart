class DateHelper {
  static const List<String> days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

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

  static String getGreeting([DateTime? time]) {
    final hour = (time ?? DateTime.now()).hour;
    if (hour >= 4 && hour < 11) return 'Selamat Pagi';
    if (hour >= 11 && hour < 15) return 'Selamat Siang';
    if (hour >= 15 && hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  static String formatIndonesianDate([DateTime? date]) {
    final now = date ?? DateTime.now();
    final dayName = days[now.weekday - 1];
    final monthName = months[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  static String getTodayKey([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String extractDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    final clean = rawDate.replaceAll('T', ' ').split('.').first.trim();
    if (clean.length >= 10) return clean.substring(0, 10);
    return clean;
  }

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
