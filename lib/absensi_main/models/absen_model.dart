class AbsenModel {
  final int id;
  final int userId;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final double latitude;
  final double longitude;
  final String address;
  final String? alasanIzin;
  final String? createdAt;

  const AbsenModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.alasanIzin,
    required this.createdAt,
  });

  factory AbsenModel.fromJson(Map<String, dynamic> json) {
    final checkOutRaw = json['check_out'] ?? json['checkOut'];
    final checkInRaw = json['check_in'] ?? json['checkIn'];
    final izinRaw = json['alasan_izin'] ?? json['alasanIzin'];
    final createdRaw = json['created_at'] ?? json['createdAt'];

    double? lat;
    double? lng;

    if (json['check_in_lat'] != null) {
      final v = _toDouble(json['check_in_lat']);
      if (v != 0.0) lat = v;
    }
    if (json['check_in_lng'] != null) {
      final v = _toDouble(json['check_in_lng']);
      if (v != 0.0) lng = v;
    }

    if (lat == null && json['check_out_lat'] != null) {
      final v = _toDouble(json['check_out_lat']);
      if (v != 0.0) lat = v;
    }
    if (lng == null && json['check_out_lng'] != null) {
      final v = _toDouble(json['check_out_lng']);
      if (v != 0.0) lng = v;
    }

    if (lat == null && json['latitude'] != null) {
      final v = _toDouble(json['latitude']);
      if (v != 0.0) lat = v;
    }
    if (lng == null && json['longitude'] != null) {
      final v = _toDouble(json['longitude']);
      if (v != 0.0) lng = v;
    }

    if (lat == null && json['lat'] != null) {
      final v = _toDouble(json['lat']);
      if (v != 0.0) lat = v;
    }
    if (lng == null && json['lng'] != null) {
      final v = _toDouble(json['lng']);
      if (v != 0.0) lng = v;
    }

    if (lat == null || lng == null) {
      final loc =
          json['check_in_location'] ??
          json['check_out_location'] ??
          json['location'] ??
          json['lokasi'];
      if (loc != null) {
        final parts = loc.toString().split(RegExp(r'[,;]'));
        if (parts.length >= 2) {
          final pLat = double.tryParse(parts[0].trim());
          final pLng = double.tryParse(parts[1].trim());
          if (pLat != null && pLng != null && (pLat != 0.0 || pLng != 0.0)) {
            lat ??= pLat;
            lng ??= pLng;
          }
        }
      }
    }

    final finalLat = lat ?? -6.175392;
    final finalLng = lng ?? 106.827153;

    String? addr;
    final rawAddr =
        json['check_in_address'] ??
        json['check_out_address'] ??
        json['address'] ??
        json['alamat'] ??
        json['location_name'] ??
        json['lokasi_nama'];
    if (rawAddr != null) {
      final t = rawAddr.toString().trim();
      if (t.isNotEmpty &&
          t.toLowerCase() != 'null' &&
          t.toLowerCase() != 'lokasi tidak diketahui') {
        addr = t;
      }
    }

    if (addr == null || addr.isEmpty) {
      if (finalLat == -6.175392 && finalLng == 106.827153) {
        addr = 'Kantor PPKD Jakarta Pusat, Jl. Kebon Sirih';
      } else {
        addr =
            'Koordinat: ${finalLat.toStringAsFixed(4)}, ${finalLng.toStringAsFixed(4)}';
      }
    }

    return AbsenModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id'] ?? json['userId']),
      status: _toText(json['status'], 'masuk').toLowerCase(),
      checkIn: _optionalText(checkInRaw),
      checkOut: _optionalText(checkOutRaw),
      latitude: finalLat,
      longitude: finalLng,
      address: addr,
      alasanIzin: _optionalText(izinRaw),
      createdAt: _optionalText(createdRaw),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'check_in': checkIn,
      'check_out': checkOut,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'alasan_izin': alasanIzin,
      'created_at': createdAt,
    };
  }

  bool get isIzin => status.toLowerCase() == 'izin';

  bool get sudahPulang => checkOut != null && checkOut!.isNotEmpty;

  String get statusLabel {
    if (isIzin) return 'Izin';
    if (sudahPulang) return 'Selesai';
    return 'Masuk';
  }

  String get tanggalFormatted {
    final raw = createdAt ?? checkIn;
    if (raw == null || raw.isEmpty) {
      return '-';
    }
    final bebas = raw.replaceAll('T', ' ').split('.').first.trim();
    if (bebas.length >= 10) {
      return bebas.substring(0, 10);
    }
    return bebas;
  }

  String get jamFormatted {
    final raw = checkIn ?? createdAt;
    if (raw == null || raw.isEmpty) {
      return '-';
    }
    final bebas = raw.replaceAll('T', ' ');
    final bagian = bebas.split(' ');
    if (bagian.length >= 2) {
      final jam = bagian[1].split('.').first;
      return jam.length >= 5 ? jam.substring(0, 5) : jam;
    }
    return '-';
  }

  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _toDouble(dynamic value, [double fallback = 0.0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _toText(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _optionalText(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
