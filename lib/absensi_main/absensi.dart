import 'package:flutter/material.dart';
import 'package:absensi/absensi_main/screens/dashboard_screen.dart';
import 'package:absensi/absensi_main/screens/history_screen.dart';
import 'package:absensi/absensi_main/screens/login_screen.dart';
import 'package:absensi/absensi_main/screens/profile_screen.dart';
import 'package:absensi/absensi_main/screens/register_screen.dart';
import 'package:absensi/absensi_main/services/session_manager.dart';

/// Halaman pembungkus utama aplikasi Absensi PPKD.
///
/// Mengelola status autentikasi sesi, navigasi antar tab (Dashboard, Riwayat, Profil),
/// serta pergantian tema terang dan gelap.
class Absensi extends StatefulWidget {
  /// Status tema awal (opsional).
  final bool? isDarkMode;

  /// Callback notifikasi saat tema berubah.
  final ValueChanged<bool>? onThemeChanged;

  const Absensi({super.key, this.isDarkMode, this.onThemeChanged});

  @override
  State<Absensi> createState() => _AbsensiState();
}

class _AbsensiState extends State<Absensi> {
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;
  bool _showRegister = false;
  int _currentIndex = 0;
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode ?? false;
    _checkInitialState();
  }

  /// Memeriksa status login dan preferensi tema yang tersimpan di perangkat saat aplikasi dibuka.
  Future<void> _checkInitialState() async {
    final loggedIn = await SessionManager.isLoggedIn();
    final savedDarkMode = await SessionManager.getDarkMode();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        if (widget.isDarkMode == null) {
          _darkMode = savedDarkMode;
        }
        _isCheckingAuth = false;
      });
    }
  }

  /// Mengubah tema aplikasi antara terang dan gelap lalu menyimpannya ke preferensi lokal.
  void _handleThemeToggle(bool value) {
    setState(() {
      _darkMode = value;
    });
    SessionManager.setDarkMode(value);
    widget.onThemeChanged?.call(value);
  }

  /// Menangani aksi logout dan mengembalikan tampilan ke form login.
  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _showRegister = false;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = _darkMode
        ? ThemeData.dark().copyWith(
            primaryColor: const Color(0xFF4F46E5),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              secondary: Color(0xFF10B981),
              surface: Color(0xFF0F172A),
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
          )
        : ThemeData.light().copyWith(
            primaryColor: const Color(0xFF4F46E5),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              secondary: Color(0xFF10B981),
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          );

    return Theme(
      data: themeData,
      child: Builder(
        builder: (context) {
          if (_isCheckingAuth) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!_isLoggedIn) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  _showRegister ? 'Daftar Akun PPKD' : 'Masuk Akun PPKD',
                ),
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0.5,
                actions: [
                  IconButton(
                    icon: Icon(
                      _darkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                    ),
                    tooltip: 'Ubah Tema',
                    onPressed: () => _handleThemeToggle(!_darkMode),
                  ),
                ],
              ),
              body: _showRegister
                  ? RegisterScreen(
                      onRegisterSuccess: () {
                        setState(() {
                          _isLoggedIn = true;
                          _showRegister = false;
                          _currentIndex = 0;
                        });
                      },
                      onNavigateToLogin: () {
                        setState(() {
                          _showRegister = false;
                        });
                      },
                    )
                  : LoginScreen(
                      onLoginSuccess: () {
                        setState(() {
                          _isLoggedIn = true;
                          _currentIndex = 0;
                        });
                      },
                      onNavigateToRegister: () {
                        setState(() {
                          _showRegister = true;
                        });
                      },
                    ),
            );
          }

          final pages = [
            DashboardScreen(
              onOpenHistory: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
            const HistoryScreen(),
            ProfileScreen(
              onLogout: _handleLogout,
              isDarkMode: _darkMode,
              onThemeToggle: _handleThemeToggle,
            ),
          ];

          final titles = ['ABSENSI PPKD', 'Riwayat Absensi', 'Profil Pengguna'];

          return Scaffold(
            appBar: AppBar(
              title: Text(
                titles[_currentIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0.5,
              actions: [
                IconButton(
                  icon: Icon(
                    _darkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                  ),
                  tooltip: 'Ubah Tema',
                  onPressed: () => _handleThemeToggle(!_darkMode),
                ),
              ],
            ),
            body: IndexedStack(index: _currentIndex, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history_rounded),
                  label: 'Riwayat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
