import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/home/data/laporan_service.dart';
import 'package:infrast/presentation/pages/laporan/detail/laporan_detail_page.dart';
import 'package:latlong2/latlong.dart';


class PetaPage extends StatefulWidget {
  const PetaPage({super.key});

  @override
  State<PetaPage> createState() => _PetaPageState();
}

class _PetaPageState extends State<PetaPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  LatLng _userLocation = const LatLng(-8.1724, 113.7007); // Default: Kabupaten Jember
  bool _locationLoaded = false;
  bool _isLoadingLaporan = true;
  bool _mapReady = false;

  List<Map<String, dynamic>> _laporanList = [];

  Map<String, dynamic>? _selectedLaporan;
  late AnimationController _sheetAnimCtrl;
  late Animation<double> _sheetAnim;

  @override
  void initState() {
    super.initState();
    _sheetAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _sheetAnim = CurvedAnimation(
      parent: _sheetAnimCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _initLocation();
    _loadLaporan();
  }

  @override
  void dispose() {
    _sheetAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // Coba last known position dulu agar lebih cepat
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        final loc = LatLng(lastPos.latitude, lastPos.longitude);
        setState(() {
          _userLocation = loc;
          _locationLoaded = true;
        });
        if (_mapReady) _mapController.move(loc, 14.0);
      }

      // Kemudian dapatkan posisi akurat
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      final accurate = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = accurate;
        _locationLoaded = true;
      });
      if (_mapReady) _mapController.move(accurate, 14.0);
    } catch (_) {}
  }

  Future<void> _loadLaporan() async {
    setState(() => _isLoadingLaporan = true);
    try {
      final result = await LaporanService.fetchAllLaporan();
      if (!mounted) return;
      if (result['success'] == true) {
        final data = List<Map<String, dynamic>>.from(result['data'] ?? []);
        final withCoord = data.where((l) {
          final lat = _parseDouble(l['latitude']);
          final lng = _parseDouble(l['longitude']);
          return lat != null && lng != null;
        }).toList();
        setState(() {
          _laporanList = withCoord;
          _isLoadingLaporan = false;
        });
      } else {
        setState(() => _isLoadingLaporan = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLaporan = false);
    }
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  void _onMarkerTap(Map<String, dynamic> laporan) {
    setState(() => _selectedLaporan = laporan);
    _sheetAnimCtrl.forward(from: 0);
  }

  void _closeSheet() {
    _sheetAnimCtrl.reverse().then((_) {
      if (mounted) setState(() => _selectedLaporan = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // ── Peta OpenStreetMap ────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14.0,
              onMapReady: () {
                _mapReady = true;
                // Langsung pindah ke lokasi user jika sudah tersedia
                if (_locationLoaded) {
                  _mapController.move(_userLocation, 14.0);
                }
              },
              onTap: (_, _) => _closeSheet(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.infrast.app',
              ),
              // Marker laporan
              MarkerLayer(
                markers: _laporanList.map((laporan) {
                  final lat = _parseDouble(laporan['latitude'])!;
                  final lng = _parseDouble(laporan['longitude'])!;
                  final status = laporan['status'] as String? ?? 'baru';
                  final (markerColor, _) = _statusColors(status);
                  final isSelected = _selectedLaporan?['id'] == laporan['id'];

                  return Marker(
                    point: LatLng(lat, lng),
                    width: isSelected ? 52 : 44,
                    height: isSelected ? 60 : 52,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(laporan),
                      child: _buildMarker(markerColor, isSelected),
                    ),
                  );
                }).toList(),
              ),
              // Marker lokasi pengguna
              if (_locationLoaded)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Header overlay ────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, MediaQuery.of(context).padding.top + 12, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white.withOpacity(0)],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Peta Laporan Infrastruktur',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (_isLoadingLaporan)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentPink,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_laporanList.length} Laporan',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      if (_locationLoaded) {
                        _mapController.move(_userLocation, 14.0);
                      } else {
                        _initLocation();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Legenda ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07), blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  _legendItem(AppColors.statusPending, 'Baru'),
                  _legendItem(AppColors.statusVerification, 'Ditinjau'),
                  _legendItem(AppColors.statusProcessing, 'Dikerjakan'),
                  _legendItem(AppColors.statusCompleted, 'Selesai'),
                ],
              ),
            ),
          ),

          // ── Slide-up card laporan ─────────────────────────────────
          if (_selectedLaporan != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _sheetAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, (1 - _sheetAnim.value) * 320),
                  child: Opacity(
                      opacity: _sheetAnim.value.clamp(0.0, 1.0),
                      child: child),
                ),
                child: _buildLaporanCard(_selectedLaporan!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarker(Color color, bool isSelected) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            width: isSelected ? 20 : 16,
            height: isSelected ? 8 : 6,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Container(
          width: isSelected ? 44 : 36,
          height: isSelected ? 44 : 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white, width: isSelected ? 3 : 2),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: isSelected ? 16 : 8,
                  spreadRadius: 2),
            ],
          ),
          child: Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: isSelected ? 22 : 18),
        ),
        Positioned(
          bottom: isSelected ? 6 : 4,
          child: CustomPaint(
            size: Size(isSelected ? 14 : 10, isSelected ? 10 : 7),
            painter: _TrianglePainter(color),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildLaporanCard(Map<String, dynamic> l) {
    final status = l['status'] as String? ?? 'baru';
    final (statusColor, statusBg) = _statusColors(status);
    final foto = l['foto'] as List?;
    final fotoUrl =
        (foto != null && foto.isNotEmpty) ? foto.first['url'] as String? : null;

    return GestureDetector(
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! > 200) {
          _closeSheet();
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  MediaQuery.of(context).padding.bottom + 90),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: fotoUrl != null
                              ? Image.network(fotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _thumbPlaceholder())
                              : _thumbPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l['nomor'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                  child: Text(
                                    l['status_label'] ??
                                        _capitalizeFirst(status),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l['judul'] ?? '-',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    l['kecamatan']?['nama'] ??
                                        l['lokasi'] ??
                                        '-',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.category_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text(
                                  l['kategori']?['nama'] ?? '-',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _closeSheet();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                LaporanDetailPage(laporanId: l['id']),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Lihat Detail Laporan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: AppColors.accentPink,
      child: const Icon(Icons.photo_camera_outlined,
          color: AppColors.primary, size: 28),
    );
  }

  (Color, Color) _statusColors(String status) {
    return switch (status) {
      'baru' => (AppColors.statusPending, AppColors.statusPendingBg),
      'ditinjau' =>
        (AppColors.statusVerification, AppColors.statusVerificationBg),
      'ditugaskan' =>
        (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'dikerjakan' =>
        (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'selesai' =>
        (AppColors.statusCompleted, AppColors.statusCompletedBg),
      'dikonfirmasi' =>
        (AppColors.statusCompleted, AppColors.statusCompletedBg),
      _ => (AppColors.textSecondary, AppColors.border),
    };
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

