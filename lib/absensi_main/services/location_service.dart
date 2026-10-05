import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;
  final bool isFallback;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.isFallback = false,
  });

  double get lat => latitude;

  double get lng => longitude;
}

class LocationService {
  static const double defaultLat = -6.175392;
  static const double defaultLng = 106.827153;
  static const String defaultAddress =
      'Kantor PPKD Jakarta Pusat, Jl. Kebon Sirih';

  static final Geocoding _geocoding = Geocoding();

  static Future<bool> hasPermission() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

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

  static LocationResult fallback([String alasan = 'Lokasi default']) {
    return LocationResult(
      latitude: defaultLat,
      longitude: defaultLng,
      address: '$defaultAddress ($alasan)',
      isFallback: true,
    );
  }

  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
