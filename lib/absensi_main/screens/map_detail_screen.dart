import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:absensi/absensi_main/widgets/detail_info_row.dart';
import 'package:absensi/absensi_main/reusable/usable.dart';

class MapDetailScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String title;
  final String address;
  final String time;

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

  Future<void> _zoomIn() async {
    await _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    await _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

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
        backgroundColor: appBarBackgroundColor,
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
                DetailInfoRow(
                  icon: Icons.my_location_outlined,
                  label: 'Koordinat',
                  value: coordText,
                  labelWidth: 84,
                ),
                DetailInfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Waktu',
                  value: widget.time,
                  labelWidth: 84,
                ),
                const DetailInfoRow(
                  icon: Icons.map_outlined,
                  label: 'Tipe Peta',
                  value: 'Normal',
                  labelWidth: 84,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}
