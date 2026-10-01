import 'dart:convert';

import 'package:absensi/absensi_main/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengelola sesi lokal pengguna menggunakan [SharedPreferences].
class SessionManager {
  static const String _keyLoggedIn = 'absensi_is_logged_in';
  static const String _keyToken = 'absensi_token';
  static const String _keyUser = 'absensi_user';
  static const String _keyDarkMode = 'absensi_dark_mode';

  static SharedPreferences? _prefs;

  /// Mengambil atau menginisialisasi instance tunggal [SharedPreferences].
  static Future<SharedPreferences> _getInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Menyimpan sesi login pengguna dan opsional token autentikasi ke penyimpanan lokal.
  static Future<void> saveSession({
    required UserModel user,
    String? token,
  }) async {
    final prefs = await _getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_keyToken, token);
    }
  }

  /// Memperbarui dan menyimpan data objek [UserModel] pengguna ke penyimpanan lokal.
  static Future<void> saveUser(UserModel user) async {
    final prefs = await _getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Memeriksa apakah terdapat sesi login aktif di perangkat.
  static Future<bool> isLoggedIn() async {
    final prefs = await _getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  /// Mengambil token autentikasi Bearer yang tersimpan di penyimpanan lokal.
  static Future<String?> getToken() async {
    final prefs = await _getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  /// Mengambil data [UserModel] pengguna yang saat ini tersimpan di sesi lokal.
  static Future<UserModel?> getUser() async {
    final prefs = await _getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserModel.fromJson(decoded);
      }
      if (decoded is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Menghapus seluruh data sesi login, token, dan profil pengguna dari penyimpanan lokal.
  static Future<void> clearSession() async {
    final prefs = await _getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  /// Menyimpan preferensi tema gelap (dark mode) ke penyimpanan lokal.
  static Future<void> setDarkMode(bool value) async {
    final prefs = await _getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  /// Mengambil preferensi tema gelap (dark mode) yang tersimpan.
  static Future<bool> getDarkMode() async {
    final prefs = await _getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }
}
