import 'package:absensi/absensi_main/models/absen_model.dart';

class AbsenResponse {
  final int id;
  final String message;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final AbsenModel? absen;

  const AbsenResponse({
    required this.id,
    required this.message,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.absen,
  });

  factory AbsenResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'] ?? json['absen'];
    if (rawData is Map) {
      final data = Map<String, dynamic>.from(rawData);
      final model = AbsenModel.fromJson(data);
      return AbsenResponse(
        id: model.id,
        message: _text(json['message'], 'Absensi berhasil dicatat'),
        status: model.status,
        checkIn: model.checkIn,
        checkOut: model.checkOut,
        absen: model,
      );
    }

    return AbsenResponse(
      id: _toInt(json['id']),
      message: _text(json['message'], 'Absensi berhasil dicatat'),
      status: _text(json['status'], 'masuk').toLowerCase(),
      checkIn: _optional(json['check_in'] ?? json['checkIn']),
      checkOut: _optional(json['check_out'] ?? json['checkOut']),
      absen: null,
    );
  }

  static int _toInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _text(dynamic value, String fallback) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _optional(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
