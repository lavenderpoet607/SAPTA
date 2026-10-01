import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Halaman untuk menampilkan peta interaktif Google Maps dengan penanda (marker) lokasi presensi.
class MapDetailScreen extends StatefulWidget {
  /// Titik garis lintang (latitude) dari lokasi presensi.
  final double latitude;

  /// Titik garis bujur (longitude) dari lokasi presensi.
  final double longitude;

  /// Judul penanda atau header pada peta.
  final String title;

  /// Alamat jalan atau deskripsi lokasi presensi.
  final String address;

  /// Waktu tanggal dan jam saat presensi dicatat.
  final String time;

  /// Membuat instance baru dari [MapDetailScreen].
  const MapDetailScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = 'Detail Lokasi',
    this.address = 'Alamat tidak tersedia',
    this.time = '-',
  });

  @override
  State<MapDetailScreen> createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends State<MapDetailScreen> {
  GoogleMapController? _mapController;
  late final Set<Marker> _markers;

  static const double _zoom = 17.0;

  double get _safeLat => (widget.latitude != 0.0) ? widget.latitude : -6.175392;
  double get _safeLng =>
      (widget.longitude != 0.0) ? widget.longitude : 106.827153;

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('lokasi_absen'),
        position: LatLng(_safeLat, _safeLng),
        infoWindow: InfoWindow(title: widget.title, snippet: widget.address),
      ),
    };
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Memperbesar tingkat perbesaran peta (zoom in) secara animasi.
  Future<void> _zoomIn() async {
    await _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  /// Memperkecil tingkat perbesaran peta (zoom out) secara animasi.
  Future<void> _zoomOut() async {
    await _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  /// Mengembalikan fokus kamera peta ke titik koordinat presensi pengguna.
  Future<void> _kembaliKeLokasi() async {
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(_safeLat, _safeLng), zoom: _zoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coordText =
        '${_safeLat.toStringAsFixed(6)}, ${_safeLng.toStringAsFixed(6)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_safeLat, _safeLng),
                    zoom: _zoom,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: Column(
                    children: [
                      _mapButton(
                        icon: Icons.add,
                        tooltip: 'Perbesar',
                        onPressed: _zoomIn,
                      ),
                      const SizedBox(height: 8),
                      _mapButton(
                        icon: Icons.remove,
                        tooltip: 'Perkecil',
                        onPressed: _zoomOut,
                      ),
                      const SizedBox(height: 8),
                      _mapButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Kembali ke lokasi',
                        onPressed: _kembaliKeLokasi,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.address,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _barisInfo(
                  icon: Icons.my_location_outlined,
                  label: 'Koordinat',
                  value: coordText,
                ),
                const SizedBox(height: 8),
                _barisInfo(
                  icon: Icons.schedule_rounded,
                  label: 'Waktu',
                  value: widget.time,
                ),
                const SizedBox(height: 8),
                _barisInfo(
                  icon: Icons.map_outlined,
                  label: 'Tipe Peta',
                  value: 'Normal',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tombol interaktif kontrol overlay pada peta dengan ikon dan pesan bantuan [tooltip].
  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
          ),
        ),
      ),
    );
  }

  /// Membangun baris teks informasi dengan ikon [icon], nama [label], dan isi nilai [value].
  Widget _barisInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
