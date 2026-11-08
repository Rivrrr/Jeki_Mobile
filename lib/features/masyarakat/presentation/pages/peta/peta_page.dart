import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/storage_service.dart';
import 'package:infrast/features/masyarakat/data/laporan_service.dart';
import 'package:infrast/features/masyarakat/presentation/pages/laporan/detail/laporan_detail_page.dart';
import 'package:latlong2/latlong.dart';

class PetaPage extends StatefulWidget {
  const PetaPage({super.key});

  @override
  State<PetaPage> createState() => _PetaPageState();
}

class _PetaPageState extends State<PetaPage> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Koordinat default: Alun-Alun Kabupaten Jember
  static const LatLng _defaultJember = LatLng(-8.1724, 113.7007);
  LatLng _userLocation = _defaultJember;

  bool _locationLoaded = false;
  bool _isGpsDisabled = false;
  bool _isLoadingLaporan = true;
  bool _mapReady = false;
  int? _currentUserId;
  double? _heading;
  bool _isFollowingLocation = true;

  List<Map<String, dynamic>> _laporanList = [];
  Map<String, dynamic>? _selectedLaporan;

  late AnimationController _sheetAnimCtrl;
  late Animation<double> _sheetAnim;

  // Animasi pulsing untuk marker GPS pengguna
  late AnimationController _pulseController;
  StreamSubscription<Position>? _positionStreamSub;
  StreamSubscription<CompassEvent>? _compassStreamSub;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _initLocation();
    _loadLaporan();
    _loadCurrentUser();
    _initCompass();
  }

  void _initCompass() {
    _compassStreamSub = FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => _heading = event.heading);
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await StorageService.getUser();
    if (!mounted) return;
    setState(() {
      _currentUserId = _parseInt(user?['id']);
    });
  }

  @override
  void dispose() {
    _positionStreamSub?.cancel();
    _compassStreamSub?.cancel();
    _pulseController.dispose();
    _sheetAnimCtrl.dispose();
    super.dispose();
  }

  /// Inisialisasi dan deteksi GPS pengguna
  Future<void> _initLocation({bool userInitiated = false}) async {
    try {
      // 1. Cek apakah layanan lokasi / GPS perangkat diaktifkan
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isGpsDisabled = true;
            _locationLoaded = false;
          });
          if (userInitiated) {
            _showGpsDisabledDialog();
          }
        }
        return;
      }

      // 2. Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted && userInitiated) {
            _showSnackBar(
              'Izin akses lokasi ditolak oleh pengguna.',
              isError: true,
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted && userInitiated) {
          _showPermissionDeniedForeverDialog();
        }
        return;
      }

      if (mounted) {
        setState(() => _isGpsDisabled = false);
      }

      // 3. Ambil posisi cepat (last known position)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        final loc = LatLng(lastPos.latitude, lastPos.longitude);
        setState(() {
          _userLocation = loc;
          _locationLoaded = true;
        });
        if (_mapReady) _mapController.move(loc, 15.0);
      }

      // 4. Ambil posisi akurat real-time
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      final accurate = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = accurate;
        _locationLoaded = true;
      });

      if (_mapReady && _isFollowingLocation) {
        _mapController.move(accurate, 15.5);
      }

      // 5. Dengarkan pergerakan pengguna secara real-time via stream
      _positionStreamSub?.cancel();
      _positionStreamSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 10, // update setiap bergeser 10 meter untuk stabilitas
            ),
          ).listen((Position newPos) {
            if (mounted) {
              final newLoc = LatLng(newPos.latitude, newPos.longitude);
              
              // Stabilitas: Hanya update state jika posisi benar-benar berubah signifikan
              if (newLoc != _userLocation) {
                setState(() {
                  _userLocation = newLoc;
                  _locationLoaded = true;
                });

                // Hanya gerakkan kamera jika mode follow aktif
                if (_mapReady && _isFollowingLocation) {
                  _mapController.move(newLoc, 15.5);
                }
              }
            }
          });
    } catch (_) {
      // Abaikan error koneksi GPS sementara
    }
  }

  /// Dialog ketika GPS device dimatikan
  void _showGpsDisabledDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: AppColors.error),
            SizedBox(width: 10),
            Text(
              'GPS Belum Aktif',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Layanan lokasi (GPS) pada perangkat Anda belum diaktifkan. '
          'Aktifkan GPS agar posisi Anda saat ini dapat ditampilkan di peta dan mendeteksi laporan di sekitar Anda.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Nanti Saja',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Geolocator.openLocationSettings();
              // Tunggu user kembali lalu refresh lokasi
              await Future.delayed(const Duration(seconds: 1));
              _initLocation(userInitiated: true);
            },
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Buka Pengaturan GPS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog ketika izin lokasi ditolak secara permanen
  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 10),
            Text(
              'Izin Lokasi Diperlukan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Izin akses lokasi ditolak permanen. Silakan berikan izin lokasi melalui Pengaturan Aplikasi untuk menampilkan posisi Anda di peta.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Geolocator.openAppSettings();
            },
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Buka Pengaturan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Memuat data laporan dari backend untuk ditandai pada peta
  Future<void> _loadLaporan() async {
    setState(() => _isLoadingLaporan = true);
    try {
      final result = await LaporanService.fetchAllLaporan();
      if (!mounted) return;
      if (result['success'] == true) {
        final rawList = result['data']?['data'] ?? result['data'] ?? [];
        final data = (rawList is List)
            ? rawList
                  .whereType<Map>()
                  .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
                  .toList()
            : <Map<String, dynamic>>[];
        final withCoord = data.where((l) {
          final lat = _parseDouble(l['latitude']);
          final lng = _parseDouble(l['longitude']);
          return lat != null && lng != null && lat != 0.0 && lng != 0.0;
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

    // Pusatkan sedikit di atas marker agar tidak tertutup kartu bawah
    final lat = _parseDouble(laporan['latitude']);
    final lng = _parseDouble(laporan['longitude']);
    if (lat != null && lng != null) {
      _mapController.move(LatLng(lat - 0.003, lng), _mapController.camera.zoom);
    }
  }

  void _closeSheet() {
    _sheetAnimCtrl.reverse().then((_) {
      if (mounted) setState(() => _selectedLaporan = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
      children: [
        // ── Peta Google Maps Standard View ──────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 14.5,
              minZoom: 5.0,
              maxZoom: 18.0,
              onMapReady: () {
                _mapReady = true;
                if (_locationLoaded && _isFollowingLocation) {
                  _mapController.move(_userLocation, 15.0);
                }
              },
              onTap: (_, _) {
                _closeSheet();
                setState(() => _isFollowingLocation = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                userAgentPackageName: 'com.infrast.app',
              ),

              // ── Marker Lokasi Seluruh Laporan ────────────────────────────
              MarkerLayer(
                markers: _laporanList.map((laporan) {
                  final lat = _parseDouble(laporan['latitude'])!;
                  final lng = _parseDouble(laporan['longitude'])!;
                  final status = laporan['status'] as String? ?? 'baru';
                  final (markerColor, _) = _statusColors(status);
                  final isSelected = _selectedLaporan?['id'] == laporan['id'];
                  final isMine = _isMyReport(laporan);

                  return Marker(
                    point: LatLng(lat, lng),
                    width: isSelected ? 52 : 44,
                    height: isSelected ? 60 : 52,
                    child: GestureDetector(
                      onTap: () => _onMarkerTap(laporan),
                      child: _buildLaporanMarker(
                        markerColor,
                        isSelected,
                        isMine,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ── Marker GPS Lokasi Pengguna (Real-time Pulsing Dot) ────────
              if (_locationLoaded)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation,
                      width: 70,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          _showSnackBar(
                            '📍 Lokasi Anda Saat Ini (GPS Terkunci)',
                          );
                        },
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulseValue = _pulseController.value;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Gelombang radar membesar
                                Container(
                                  width: 24 + (pulseValue * 44),
                                  height: 24 + (pulseValue * 44),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2563EB).withValues(
                                      alpha: (1.0 - pulseValue).clamp(
                                        0.0,
                                        0.45,
                                      ),
                                    ),
                                  ),
                                ),
                                // Lingkaran aura biru
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                // Titik inti GPS warna biru terang
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D4ED8),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1D4ED8)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Header Overlay & Kontrol Lokasi ─────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 10,
                16,
                12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white.withValues(alpha: 0)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (canPop)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: AppColors.textPrimary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,                                  offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
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
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPink,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_laporanList.length} Titik',
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
                      // Tombol GPS "My Location"
                      GestureDetector(
                        onTap: () {
                          if (_locationLoaded) {
                            _mapController.move(_userLocation, 16.0);
                            _showSnackBar('📍 Dipusatkan ke posisi GPS Anda');
                          } else {
                            _initLocation(userInitiated: true);
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _locationLoaded
                                ? Icons.my_location_rounded
                                : Icons.location_searching_rounded,
                            color: _locationLoaded
                                ? const Color(0xFF2563EB)
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Banner Peringatan jika GPS Device Belum Aktif
                  if (_isGpsDisabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => _initLocation(userInitiated: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.gps_off_rounded,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'GPS perangkat nonaktif. Ketuk untuk mengaktifkan',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Legenda Status & Lokasi GPS ─────────────────────────────────
          Positioned(
            top: 120,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keterangan Warna',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem(
                    const Color(0xFFF59E0B),
                    'Menunggu',
                  ),
                  _buildLegendItem(
                    const Color(0xFF3B82F6),
                    'Diproses',
                  ),
                  _buildLegendItem(
                    const Color(0xFF10B981),
                    'Selesai',
                  ),
                  _buildLegendItem(
                    const Color(0xFFE91E63),
                    'Laporan Saya',
                  ),
                ],
              ),
            ),
          ),

          // ── Kompas Navigasi ─────────────────────────────────────────────
          Positioned(
            bottom: 120,
            right: 20,
            child: _buildCompass(),
          ),

          // ── Slide-up Card Laporan Terpilih ──────────────────────────────
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
                    child: child,
                  ),
                ),
                child: _buildLaporanCard(_selectedLaporan!),
              ),
            ),
        ],
      ),
    );
  }

  /// Desain Marker Pin Laporan
  Widget _buildCompass() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFollowingLocation = true;
        });
        _mapController.rotate(0.0);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: (_heading ?? 0) * (3.14159 / 180),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 4,
                    child: Text('N', 
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.red,
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(30, 30),
                    painter: _CompassPainter(),
                  ),
                ],
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanMarker(Color color, bool isSelected, bool isMine) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.location_on,
            color: color,
            size: isSelected ? 40 : 32,
          ),
          Positioned(
            top: isSelected ? 10 : 7,
            child: Container(
              width: isSelected ? 8 : 6,
              height: isSelected ? 8 : 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  /// Kartu Pratinjau Laporan saat pin diketuk
  Widget _buildLaporanCard(Map<String, dynamic> l) {
    final status = (l['status'] as String? ?? 'baru').toLowerCase();
    final (statusColor, statusBg) = _statusColors(status);
    final isMine = _isMyReport(l);
    String? fotoUrl;
    final dynamic fotoData = l['foto'];
    if (fotoData is List && fotoData.isNotEmpty) {
      final first = fotoData.first;
      if (first is Map && first['url'] != null) {
        fotoUrl = first['url'].toString();
      } else if (first is String) {
        fotoUrl = first;
      }
    } else if (fotoData is String && fotoData.isNotEmpty) {
      fotoUrl = fotoData;
    }

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
              offset: Offset(0, -4),
            ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                MediaQuery.of(context).padding.bottom +
                    (Navigator.of(context).canPop() ? 20 : 90),
              ),
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
                              ? Image.network(
                                  fotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _thumbPlaceholder(),
                                )
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
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? const Color(0xFFFCE4EC)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isMine ? 'Laporan Anda' : 'Pengguna Lain',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isMine
                                          ? const Color(0xFFBE185D)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    l['status_label'] ??
                                        _capitalizeFirst(status),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
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
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_safeStr(l['deskripsi']).isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                _shorten(_safeStr(l['deskripsi']), 120),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    l['kecamatan']?['nama'] ??
                                        l['lokasi'] ??
                                        '-',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.category_outlined,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  l['kategori']?['nama'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
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
                        final laporanId = _parseInt(l['id']);
                        if (laporanId == null) {
                          _showSnackBar(
                            'ID laporan tidak valid.',
                            isError: true,
                          );
                          return;
                        }
                        _closeSheet();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                LaporanDetailPage(laporanId: laporanId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Lihat Detail Laporan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
      child: const Icon(
        Icons.photo_camera_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    return switch (status.toLowerCase()) {
      'baru' => (AppColors.statusPending, AppColors.statusPendingBg),
      'ditinjau' => (
        AppColors.statusVerification,
        AppColors.statusVerificationBg,
      ),
      'ditugaskan' => (
        AppColors.statusProcessing,
        AppColors.statusProcessingBg,
      ),
      'dikerjakan' => (
        AppColors.statusProcessing,
        AppColors.statusProcessingBg,
      ),
      'selesai' => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      'dikonfirmasi' => (
        AppColors.statusCompleted,
        AppColors.statusCompletedBg,
      ),
      _ => (AppColors.textSecondary, AppColors.border),
    };
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  int? _extractOwnerId(Map<String, dynamic> laporan) {
    final directKeys = [
      laporan['user_id'],
      laporan['pelapor_id'],
      laporan['masyarakat_id'],
      laporan['created_by'],
    ];

    for (final keyValue in directKeys) {
      final parsed = _parseInt(keyValue);
      if (parsed != null) return parsed;
    }

    final userMap = laporan['user'];
    if (userMap is Map) {
      final parsed = _parseInt(userMap['id']);
      if (parsed != null) return parsed;
    }

    final masyarakatMap = laporan['masyarakat'];
    if (masyarakatMap is Map) {
      final parsedUserId = _parseInt(masyarakatMap['user_id']);
      if (parsedUserId != null) return parsedUserId;
      final parsedId = _parseInt(masyarakatMap['id']);
      if (parsedId != null) return parsedId;
    }

    return null;
  }

  bool _isMyReport(Map<String, dynamic> laporan) {
    if (_currentUserId == null) return false;
    final ownerId = _extractOwnerId(laporan);
    if (ownerId == null) return false;
    return ownerId == _currentUserId;
  }

  String _safeStr(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'undefined') return fallback;
    return s;
  }

  String _shorten(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars).trimRight()}...';
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    // North needle (red)
    paint.color = Colors.red;
    canvas.drawLine(Offset(size.width / 2, size.height / 2), Offset(size.width / 2, 4), paint);

    // South needle (blue/grey)
    paint.color = Colors.blueGrey;
    canvas.drawLine(Offset(size.width / 2, size.height / 2), Offset(size.width / 2, size.height - 4), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


