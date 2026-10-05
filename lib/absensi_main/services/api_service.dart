import 'package:dio/dio.dart';
import 'package:absensi/absensi_main/models/absen_model.dart';
import 'package:absensi/absensi_main/models/absen_response.dart';
import 'package:absensi/absensi_main/models/user_model.dart';
import 'package:absensi/absensi_main/services/session_manager.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  static const String _defaultBaseUrl =
      'https://absensib1.mobileprojp.com/api/';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  Dio get dio => _dio;

  String get baseUrl => _dio.options.baseUrl;

  Map<String, String> _authHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _request(
      method: 'POST',
      path: '/login',
      body: {'email': email, 'password': password},
      errorPrefix: 'Gagal masuk',
    );
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String batch,
    required int trainingId,
  }) async {
    return _request(
      method: 'POST',
      path: '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'batch': batch,
        'training_id': trainingId,
      },
      errorPrefix: 'Registrasi gagal',
    );
  }

  Future<UserModel> getProfile() async {
    final token = await SessionManager.getToken();
    final json = await _request(
      method: 'GET',
      path: '/profile',
      token: token,
      errorPrefix: 'Gagal memuat profil',
    );
    final data = json['data'] ?? json['user'] ?? json;
    if (data is Map) {
      return UserModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Data profil tidak valid');
  }

  Future<UserModel> updateName({required String name}) async {
    final token = await SessionManager.getToken();
    final currentUser = await SessionManager.getUser();

    try {
      final json = await _request(
        method: 'POST',
        path: '/profile/update',
        token: token,
        body: {'name': name},
        errorPrefix: 'Gagal memperbarui profil',
      );
      final data = json['data'] ?? json['user'] ?? json;
      if (data is Map) {
        final updated = UserModel.fromJson(Map<String, dynamic>.from(data));
        await SessionManager.saveUser(updated);
        return updated;
      }
    } catch (_) {
      try {
        final json = await _request(
          method: 'PUT',
          path: '/profile',
          token: token,
          body: {'name': name},
          errorPrefix: 'Gagal memperbarui profil',
        );
        final data = json['data'] ?? json['user'] ?? json;
        if (data is Map) {
          final updated = UserModel.fromJson(Map<String, dynamic>.from(data));
          await SessionManager.saveUser(updated);
          return updated;
        }
      } catch (_) {}
    }

    final updated =
        (currentUser ??
                const UserModel(
                  id: 0,
                  name: '',
                  email: '-',
                  role: 'peserta',
                  createdAt: '-',
                ))
            .copyWith(name: name);
    await SessionManager.saveUser(updated);
    return updated;
  }

  Future<AbsenResponse> checkIn({
    required double lat,
    required double lng,
    required String address,
    String status = 'masuk',
    String? alasanIzin,
  }) async {
    final token = await SessionManager.getToken();
    final latStr = lat.toString();
    final lngStr = lng.toString();
    final locStr = '$lat, $lng';
    final body = <String, dynamic>{
      'latitude': lat,
      'longitude': lng,
      'lat': lat,
      'lng': lng,
      'address': address,
      'check_in_lat': latStr,
      'check_in_lng': lngStr,
      'check_in_location': locStr,
      'check_in_address': address,
      'location': locStr,
      'status': status,
    };
    if (alasanIzin != null && alasanIzin.isNotEmpty) {
      body['alasan_izin'] = alasanIzin;
    }
    final json = await _request(
      method: 'POST',
      path: '/absen/check-in',
      token: token,
      body: body,
      errorPrefix: status == 'izin'
          ? 'Pengajuan izin gagal'
          : 'Absen masuk gagal',
    );
    return AbsenResponse.fromJson(json);
  }

  Future<bool> deleteAbsen(int id) async {
    final token = await SessionManager.getToken();
    try {
      await _request(
        method: 'DELETE',
        path: '/absen/$id',
        token: token,
        errorPrefix: 'Gagal menghapus absensi',
      );
      return true;
    } catch (_) {
      await _request(
        method: 'DELETE',
        path: '/absen/izin/$id',
        token: token,
        errorPrefix: 'Gagal menghapus absensi',
      );
      return true;
    }
  }

  Future<AbsenResponse> checkOut({
    required double lat,
    required double lng,
    required String address,
  }) async {
    final token = await SessionManager.getToken();
    final latStr = lat.toString();
    final lngStr = lng.toString();
    final locStr = '$lat, $lng';
    final body = <String, dynamic>{
      'latitude': lat,
      'longitude': lng,
      'lat': lat,
      'lng': lng,
      'address': address,
      'check_out_lat': latStr,
      'check_out_lng': lngStr,
      'check_out_location': locStr,
      'check_out_address': address,
      'location': locStr,
    };
    final json = await _request(
      method: 'POST',
      path: '/absen/check-out',
      token: token,
      body: body,
      errorPrefix: 'Absen pulang gagal',
    );
    return AbsenResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> ajukanIzin({required String alasan}) async {
    final token = await SessionManager.getToken();
    return _request(
      method: 'POST',
      path: '/absen/check-in',
      token: token,
      body: {'status': 'izin', 'alasan_izin': alasan},
      errorPrefix: 'Pengajuan izin gagal',
    );
  }

  Future<Map<String, dynamic>> logout() async {
    final token = await SessionManager.getToken();
    try {
      return await _request(
        method: 'POST',
        path: '/logout',
        token: token,
        errorPrefix: 'Logout gagal',
      );
    } catch (_) {
      return {'message': 'Sesi lokal telah dihapus'};
    }
  }

  Future<List<AbsenModel>> getHistory({int limit = 100}) async {
    final token = await SessionManager.getToken();
    final json = await _request(
      method: 'GET',
      path: '/absen/history',
      token: token,
      query: {'limit': limit},
      errorPrefix: 'Gagal memuat riwayat',
    );

    final dynamic raw = json['data'] ?? json['history'] ?? json['items'];

    if (raw is List) {
      return _mapAbsenList(raw);
    }

    if (raw is Map) {
      final nested = raw['data'] ?? raw['items'];
      if (nested is List) {
        return _mapAbsenList(nested);
      }
    }

    return <AbsenModel>[];
  }

  List<AbsenModel> _mapAbsenList(List<dynamic> items) {
    final hasil = <AbsenModel>[];
    for (final item in items) {
      if (item is Map) {
        hasil.add(AbsenModel.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return hasil;
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    String? token,
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    required String errorPrefix,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: token != null && token.isNotEmpty
              ? _authHeaders(token)
              : null,
        ),
      );

      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {'message': 'Permintaan berhasil', 'data': data};
    } on DioException catch (dioErr) {
      throw Exception(_mapDioError(dioErr, errorPrefix));
    } catch (e) {
      final pesan = e.toString().replaceFirst('Exception: ', '');
      throw Exception('$errorPrefix: $pesan');
    }
  }

  String _mapDioError(DioException dioErr, String errorPrefix) {
    final status = dioErr.response?.statusCode;
    final responseData = dioErr.response?.data;

    if (responseData is Map) {
      final pesan =
          responseData['message'] ??
          responseData['error'] ??
          responseData['pesan'];
      if (pesan != null && pesan.toString().trim().isNotEmpty) {
        return pesan.toString();
      }
    }

    switch (dioErr.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi timeout. Periksa jaringan internet Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badResponse:
        if (status == 401) {
          return 'Sesi Anda berakhir. Silakan masuk kembali.';
        }
        if (status == 404) {
          return 'Endpoint tidak ditemukan.';
        }
        if (status != null && status >= 500) {
          return 'Server sedang bermasalah. Coba beberapa saat lagi.';
        }
        return dioErr.message ?? '$errorPrefix ($status)';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan jaringan: ${dioErr.message}';
    }
  }
}
