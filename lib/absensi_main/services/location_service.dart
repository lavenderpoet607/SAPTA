import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    // 1. Coba geocoding native perangkat
    try {
      final places = await _geocoding
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 4));
      if (places.isNotEmpty) {
        final place = places.first;
        final bagian = <String>[
          if (place.street != null && place.street!.trim().isNotEmpty)
            place.street!.trim(),
          if (place.subLocality != null && place.subLocality!.trim().isNotEmpty)
            place.subLocality!.trim(),
          if (place.locality != null && place.locality!.trim().isNotEmpty)
            place.locality!.trim(),
          if (place.administrativeArea != null &&
              place.administrativeArea!.trim().isNotEmpty)
            place.administrativeArea!.trim(),
        ];
        if (bagian.isNotEmpty) {
          final result = bagian.join(', ');
          if (!result.toLowerCase().startsWith('koordinat')) {
            return result;
          }
        }
      }
    } catch (_) {
      // Native geocoder sering gagal di emulator Android / Play Services offline
    }

    // 2. Fallback HTTP Geocoder: OpenStreetMap Nominatim
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'AbsensiPPKD/1.0 (contact: app@ppkd.local)');
      final response = await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data is Map) {
          final addr = data['address'];
          if (addr is Map) {
            final road = addr['road'] ?? addr['pedestrian'] ?? addr['street'] ?? addr['amenity'];
            final suburb = addr['suburb'] ?? addr['neighbourhood'] ?? addr['city_block'] ?? addr['village'];
            final city = addr['city_district'] ?? addr['city'] ?? addr['town'] ?? addr['county'];
            final state = addr['state'];
            final parts = <String>[
              if (road != null && road.toString().trim().isNotEmpty) road.toString().trim(),
              if (suburb != null && suburb.toString().trim().isNotEmpty) suburb.toString().trim(),
              if (city != null && city.toString().trim().isNotEmpty) city.toString().trim(),
              if (state != null && state.toString().trim().isNotEmpty) state.toString().trim(),
            ];
            if (parts.isNotEmpty) {
              return parts.join(', ');
            }
          }
          final displayName = data['display_name'];
          if (displayName != null && displayName.toString().trim().isNotEmpty) {
            return displayName.toString().trim();
          }
        }
      }
    } catch (_) {}

    // 3. Fallback HTTP Geocoder: BigDataCloud Reverse Geocode Client API
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=id',
      );
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body);
        if (data is Map) {
          final locality = data['locality'];
          final city = data['city'];
          final sub = data['principalSubdivision'];
          final parts = <String>[
            if (locality != null && locality.toString().trim().isNotEmpty) locality.toString().trim(),
            if (city != null && city.toString().trim().isNotEmpty) city.toString().trim(),
            if (sub != null && sub.toString().trim().isNotEmpty) sub.toString().trim(),
          ];
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (_) {}

    // 4. Jika koordinat berada di sekitar lokasi default PPKD (< 500 meter)
    final distance = Geolocator.distanceBetween(lat, lng, defaultLat, defaultLng);
    if (distance <= 500) {
      return defaultAddress;
    }

    return 'Koordinat ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
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
