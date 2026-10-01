import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Model hasil pembacaan lokasi yang berisi koordinat GPS dan alamat teks.
class LocationResult {
  /// Nilai garis lintang (latitude) posisi saat ini.
  final double latitude;

  /// Nilai garis bujur (longitude) posisi saat ini.
  final double longitude;

  /// Alamat lengkap hasil reverse geocoding atau teks koordinat.
  final String address;

  /// Menandakan apakah lokasi ini merupakan nilai fallback (bukan GPS asli).
  final bool isFallback;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isFallback = false,
  });

  /// Alias singkat untuk [latitude].
  double get lat => latitude;

  /// Alias singkat untuk [longitude].
  double get lng => longitude;
}

/// Layanan untuk mengelola izin GPS, pengambilan koordinat, dan reverse geocoding lokasi.
class LocationService {
  /// Koordinat lintang default (Kantor PPKD Jakarta Pusat).
  static const double defaultLat = -6.175392;

  /// Koordinat bujur default (Kantor PPKD Jakarta Pusat).
  static const double defaultLng = 106.827153;

  /// Alamat teks default jika lokasi perangkat tidak terdeteksi.
  static const String defaultAddress =
      'Kantor PPKD Jakarta Pusat, Jl. Kebon Sirih';

  static final Geocoding _geocoding = Geocoding();

  /// Memeriksa apakah aplikasi telah memiliki izin akses lokasi dari pengguna.
  static Future<bool> hasPermission() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Memeriksa apakah sensor GPS atau layanan lokasi perangkat sedang aktif.
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Memastikan izin lokasi tersedia dengan meminta izin ke pengguna jika belum diberikan.
  static Future<LocationPermission> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Mengambil koordinat GPS akurat perangkat beserta alamat lengkap secara real-time.
  static Future<LocationResult> getCurrentLocation() async {
    Position? lastKnown;
    try {
      final perm = await ensurePermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return fallback('Izin lokasi belum diberikan');
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return fallback('Layanan GPS perangkat nonaktif');
      }

      try {
        lastKnown = await Geolocator.getLastKnownPosition().timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {}

      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
        } catch (_) {
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 3),
              ),
            );
          } catch (_) {
            try {
              position = await Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.low,
                ),
              ).first.timeout(const Duration(seconds: 3));
            } catch (_) {}
          }
        }
      }

      final targetPos = position ?? lastKnown;

      if (targetPos != null) {
        final address = await _resolveAddress(
          targetPos.latitude,
          targetPos.longitude,
        );
        return LocationResult(
          latitude: targetPos.latitude,
          longitude: targetPos.longitude,
          address: address,
          isFallback: false,
        );
      }

      return fallback('Lokasi sedang dimuat');
    } catch (_) {
      if (lastKnown != null) {
        final address = await _resolveAddress(
          lastKnown.latitude,
          lastKnown.longitude,
        );
        return LocationResult(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          address: address,
          isFallback: false,
        );
      }
      return fallback('Gagal mendeteksi lokasi');
    }
  }

  /// Menerjemahkan koordinat lintang dan bujur menjadi nama jalan dan wilayah via reverse geocoding.
  static Future<String> _resolveAddress(double lat, double lng) async {
    try {
      final places = await _geocoding
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 4));
      if (places.isEmpty) {
        return 'Koordinat ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      }
      final place = places.first;
      final bagian = <String>[
        if (place.street != null && place.street!.isNotEmpty) place.street!,
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          place.subLocality!,
        if (place.locality != null && place.locality!.isNotEmpty)
          place.locality!,
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          place.administrativeArea!,
      ];
      if (bagian.isEmpty) {
        return 'Koordinat ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      }
      return bagian.join(', ');
    } catch (_) {
      return 'Koordinat ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
  }

  /// Menghasilkan objek [LocationResult] cadangan menggunakan koordinat default PPKD.
  static LocationResult fallback([String alasan = 'Lokasi default']) {
    return LocationResult(
      latitude: defaultLat,
      longitude: defaultLng,
      address: '$defaultAddress ($alasan)',
      isFallback: true,
    );
  }

  /// Membuka halaman pengaturan lokasi sistem perangkat Android/iOS.
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Membuka pengaturan aplikasi di perangkat untuk mengaktifkan izin yang diblokir.
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
