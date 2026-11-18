import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:infrast/core/services/geocoding_service.dart';
import 'package:infrast/core/services/laporan_service.dart';

class StepLokasi extends StatefulWidget {
  final TextEditingController alamatController;
  final TextEditingController detailController;
  final int? selectedKecamatanId;
  final String? selectedKecamatanNama;
  final double? latitude;
  final double? longitude;
  final void Function(int id, String nama) onKecamatanSelected;
  final void Function(double lat, double lng, String label)? onCoordinateChanged;

  const StepLokasi({
    super.key,
    required this.alamatController,
    required this.detailController,
    required this.selectedKecamatanId,
    required this.selectedKecamatanNama,
    this.latitude,
    this.longitude,
    required this.onKecamatanSelected,
    this.onCoordinateChanged,
  });

  @override
  State<StepLokasi> createState() => _StepLokasiState();
}

class _StepLokasiState extends State<StepLokasi> {
  // Pusat Kabupaten Jember (Alun-Alun Jember)
  static const LatLng jemberCenter = LatLng(-8.1724, 113.7007);

  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _kecamatanList = [];
  bool _loadingKec = true;
  bool _isGettingLocation = false;
  LatLng _selectedPoint = jemberCenter;
  bool _hasUserLocation = false;
  String? _detectedAddress;
  double _currentZoom = 15.0;
  bool _isSatellite = false;
  bool _isInteractingWithMap = false;
  final FocusNode _alamatFocusNode = FocusNode();
  Timer? _searchDebounce;
  bool _isSearchingAddress = false;
  bool _isSelectingSuggestion = false;
  List<GeocodingSuggestion> _addressSuggestions = [];

  // Koordinat perkiraan pusat tiap kecamatan di Kab. Jember (fallback offline)
  static const Map<String, LatLng> _jemberKecamatanCentroids = {
    'Ajung': LatLng(-8.2258, 113.6700),
    'Ambulu': LatLng(-8.3496, 113.6067),
    'Arjasa': LatLng(-8.1158, 113.7431),
    'Balung': LatLng(-8.2719, 113.5350),
    'Bangsalsari': LatLng(-8.1969, 113.5283),
    'Gumukmas': LatLng(-8.3192, 113.4072),
    'Jelbuk': LatLng(-8.0772, 113.7436),
    'Jenggawah': LatLng(-8.2608, 113.6558),
    'Jombang': LatLng(-8.2567, 113.3444),
    'Kalisat': LatLng(-8.1258, 113.8114),
    'Kaliwates': LatLng(-8.1804, 113.6826),
    'Kencong': LatLng(-8.2792, 113.3711),
    'Ledokombo': LatLng(-8.1361, 113.8822),
    'Mayang': LatLng(-8.1906, 113.7878),
    'Mumbulsari': LatLng(-8.2619, 113.7436),
    'Pakusari': LatLng(-8.1714, 113.7661),
    'Panti': LatLng(-8.1067, 113.6169),
    'Patrang': LatLng(-8.1565, 113.7058),
    'Puger': LatLng(-8.3586, 113.4739),
    'Rambipuji': LatLng(-8.2032, 113.6053),
    'Semboro': LatLng(-8.2167, 113.4350),
    'Silo': LatLng(-8.2433, 113.9142),
    'Sukorambi': LatLng(-8.1472, 113.6558),
    'Sukowono': LatLng(-8.0667, 113.8219),
    'Sumberbaru': LatLng(-8.1417, 113.3639),
    'Sumberjambe': LatLng(-8.0967, 113.9056),
    'Sumbersari': LatLng(-8.1724, 113.7175),
    'Tanggul': LatLng(-8.1578, 113.4544),
    'Tempurejo': LatLng(-8.3267, 113.7067),
    'Umbulsari': LatLng(-8.2433, 113.4867),
    'Wuluhan': LatLng(-8.3308, 113.5358),
  };

  @override
  void initState() {
    super.initState();
    // Inisialisasi titik jika sudah ada koordinat sebelumnya
    if (widget.latitude != null && widget.longitude != null) {
      _selectedPoint = LatLng(widget.latitude!, widget.longitude!);
      _hasUserLocation = true;
    } else if (widget.selectedKecamatanNama != null &&
        _jemberKecamatanCentroids.containsKey(widget.selectedKecamatanNama)) {
      _selectedPoint = _jemberKecamatanCentroids[widget.selectedKecamatanNama!]!;
    }
    _loadKecamatan();

    _alamatFocusNode.addListener(() {
      if (!_alamatFocusNode.hasFocus && _addressSuggestions.isNotEmpty) {
        setState(() {
          _addressSuggestions = [];
        });
      }
    });

    // Otomatis pusatkan titik ke posisi riil perangkat (device) saat form lokasi dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasUserLocation && (widget.latitude == null || widget.longitude == null)) {
        _handleSetCurrentLocation(isAuto: true);
      } else if (widget.alamatController.text.trim().isEmpty) {
        _reverseGeocode(_selectedPoint);
      }
    });
  }

  @override
  void didUpdateWidget(covariant StepLokasi oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != null &&
        widget.longitude != null &&
        (widget.latitude != oldWidget.latitude || widget.longitude != oldWidget.longitude)) {
      final newPoint = LatLng(widget.latitude!, widget.longitude!);
      _selectedPoint = newPoint;
      _hasUserLocation = true;
      _mapController.move(newPoint, 17.0);
      if (widget.alamatController.text.trim().isEmpty) {
        _reverseGeocode(newPoint);
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _alamatFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadKecamatan() async {
    try {
      final res = await LaporanService.fetchKecamatan();
      if (!mounted) return;
      if (res['success'] == true) {
        final raw = res['data']?['data'] ?? res['data'] ?? [];
        final list = List<Map<String, dynamic>>.from(raw);
        if (list.isNotEmpty) {
          setState(() {
            _kecamatanList = list;
            _loadingKec = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (!mounted) return;
    int idCounter = 1;
    final fallbackList = _jemberKecamatanCentroids.keys.map((kNama) {
      return {
        'id': idCounter++,
        'nama': kNama,
      };
    }).toList();
    setState(() {
      _kecamatanList = fallbackList;
      _loadingKec = false;
    });
  }

  void _zoomIn() {
    final nextZoom = (_currentZoom + 1.0).clamp(6.0, 20.0);
    _currentZoom = nextZoom;
    _mapController.move(_selectedPoint, nextZoom);
    setState(() {});
  }

  void _zoomOut() {
    final nextZoom = (_currentZoom - 1.0).clamp(6.0, 20.0);
    _currentZoom = nextZoom;
    _mapController.move(_selectedPoint, nextZoom);
    setState(() {});
  }

  void _toggleMapType() {
    setState(() {
      _isSatellite = !_isSatellite;
    });
    _showSnackBar(_isSatellite ? 'Mode Peta Satelit Aktif' : 'Mode Peta Standar Google Aktif');
  }

  Future<void> _searchAddressSuggestions(String query) async {
    final keyword = query.trim();

    if (keyword.length < 3) {
      if (!mounted) return;
      setState(() {
        _addressSuggestions = [];
        _isSearchingAddress = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearchingAddress = true;
    });

    try {
      final suggestions = await GeocodingService.searchAddress(
        keyword,
        nearLat: _selectedPoint.latitude,
        nearLng: _selectedPoint.longitude,
      );

      if (!mounted) return;

      setState(() {
        _addressSuggestions = suggestions;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressSuggestions = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingAddress = false;
        });
      }
    }
  }

  void _onAlamatChanged(String value) {
    if (_isSelectingSuggestion) return;

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _searchAddressSuggestions(value);
    });
  }

  Future<void> _selectAddressSuggestion(GeocodingSuggestion suggestion) async {
    _isSelectingSuggestion = true;
    _searchDebounce?.cancel();

    final selected = LatLng(suggestion.latitude, suggestion.longitude);

    widget.alamatController.text = suggestion.shortAddress.isNotEmpty
        ? suggestion.shortAddress
        : suggestion.displayName;

    if (mounted) {
      setState(() {
        _selectedPoint = selected;
        _hasUserLocation = true;
        _currentZoom = 17.0;
        _detectedAddress = widget.alamatController.text.trim();
        _addressSuggestions = [];
      });
    }

    _mapController.move(selected, 17.0);

    try {
      await _reverseGeocode(selected);

      widget.onCoordinateChanged?.call(
        selected.latitude,
        selected.longitude,
        widget.selectedKecamatanNama != null
            ? 'Kec. ${widget.selectedKecamatanNama}, Kab. Jember'
            : 'Kab. Jember',
      );
    } finally {
      _isSelectingSuggestion = false;
      if (mounted) {
        _alamatFocusNode.unfocus();
        _showSnackBar('Alamat dipilih dan koordinat lokasi diperbarui.');
      }
    }
  }

  /// Melakukan Reverse Geocoding via GeocodingService (Nominatim Zoom 17 + Photon Komoot + BigDataCloud)
  /// untuk menjamin nama jalan, nomor rumah, dan kecamatan selalu terisi dengan akurat.
  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final result = await GeocodingService.reverseGeocode(
        point.latitude,
        point.longitude,
        availableKecamatans: _kecamatanList,
      );

      if (!mounted) return;

      var fullAlamat = result.fullAddress;

      // Titik pusat Alun-Alun Jember jika pas di pusat kota
      final dCenter = math.sqrt(
        math.pow(point.latitude - jemberCenter.latitude, 2) +
        math.pow(point.longitude - jemberCenter.longitude, 2),
      );
      if (dCenter < 0.005) {
        fullAlamat = 'Alun-Alun Jember, Jl. PB Sudirman';
      }

      // Otomatis isi detail/patokan jika field patokan masih kosong dan ada landmark terdeteksi
      if (result.poi != null &&
          result.poi!.trim().isNotEmpty &&
          widget.detailController.text.trim().isEmpty) {
        final poiStr = result.poi!.trim();
        if (!fullAlamat.toLowerCase().contains(poiStr.toLowerCase())) {
          widget.detailController.text = 'Dekat $poiStr';
        }
      }

      if (result.matchedKecamatanId != null && result.matchedKecamatanNama != null) {
        widget.onKecamatanSelected(result.matchedKecamatanId!, result.matchedKecamatanNama!);
      }

      if (fullAlamat.isNotEmpty) {
        widget.alamatController.text = fullAlamat;
        setState(() {
          _detectedAddress = fullAlamat;
        });
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
  }

  /// Tombol "Set Lokasi Terkini" ditekan atau otomatis mendeteksi saat halaman dibuka
  Future<void> _handleSetCurrentLocation({bool isAuto = false}) async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!isAuto && mounted) {
          _showSnackBar('Layanan lokasi (GPS) belum aktif. Harap aktifkan GPS.', isError: true);
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!isAuto && mounted) {
            _showSnackBar('Izin akses lokasi ditolak.', isError: true);
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!isAuto && mounted) {
          _showSnackBar('Izin lokasi ditolak permanen. Buka Pengaturan untuk mengaktifkannya.', isError: true);
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Ambil posisi riil perangkat (device)
      Position? position;
      try {
        // Coba last known terlebih dahulu untuk perpindahan instan
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // Ambil GPS presisi tinggi dari perangkat
      try {
        final currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 8),
          ),
        );
        position = currentPos;
      } catch (_) {}

      if (position != null) {
        final userPoint = LatLng(position.latitude, position.longitude);

        if (mounted) {
          setState(() {
            _selectedPoint = userPoint;
            _hasUserLocation = true;
            _currentZoom = 17.0;
          });

          _mapController.move(userPoint, 17.0);
        }

        // Auto-isi alamat & kecamatan via reverse geocoding akurat
        await _reverseGeocode(userPoint);

        final label = widget.selectedKecamatanNama != null
            ? 'Kec. ${widget.selectedKecamatanNama}, Kab. Jember'
            : 'Kab. Jember';

        widget.onCoordinateChanged?.call(userPoint.latitude, userPoint.longitude, label);

        if (mounted && !isAuto) {
          _showSnackBar('📍 Lokasi perangkat berhasil diset & alamat akurat terisi!');
        }
      } else {
        if (!isAuto && mounted) {
          _showSnackBar('Tidak dapat mendeteksi posisi perangkat.', isError: true);
        }
      }
    } catch (e) {
      if (!isAuto && mounted) {
        _showSnackBar('Terjadi kendala saat membaca GPS: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  void _onMapTapped(TapPosition _, LatLng point) {
    // Hanya menggeser kamera, tidak mengubah lokasi marker/alamat
    _mapController.move(point, _mapController.camera.zoom);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tile URL: Google Maps Standard (Roadmap) vs Google Maps Satelit (Hybrid)
    final googleTileUrl = _isSatellite
        ? 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}' // Google Hybrid Satellite
        : 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}'; // Google Standard Roadmap

    return SingleChildScrollView(
      physics: _isInteractingWithMap
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Peta Interaktif Standar Google Maps (Fokus Kabupaten Jember) ─────
          Listener(
            onPointerDown: (_) {
              if (!_isInteractingWithMap) setState(() => _isInteractingWithMap = true);
            },
            onPointerUp: (_) {
              if (_isInteractingWithMap) setState(() => _isInteractingWithMap = false);
            },
            onPointerCancel: (_) {
              if (_isInteractingWithMap) setState(() => _isInteractingWithMap = false);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPoint,
                        initialZoom: _currentZoom,
                        minZoom: 6.0,
                        maxZoom: 20.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                          pinchZoomThreshold: 0.5,
                        ),
                        onPositionChanged: (pos, hasGesture) {
                          _currentZoom = pos.zoom;
                        },
                        onTap: _onMapTapped,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: googleTileUrl,
                          subdomains: const ['0', '1', '2', '3'],
                          userAgentPackageName: 'com.infrast.app',
                        ),

                        // Marker Gaya Standar Google Maps (Pin Merah Presisi)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedPoint,
                              width: 50,
                              height: 60,
                              alignment: Alignment.topCenter,
                              child: Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  // Bayangan pin di aspal/tanah
                                  Positioned(
                                    bottom: 4,
                                    child: Container(
                                      width: 14,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  // Ikon Pin Google Maps
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFFEA4335), // Google Maps Red
                                    size: 46,
                                  ),
                                  // Titik putih di dalam pin
                                  Positioned(
                                    top: 14,
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Baris Kontrol Atas Peta (Responsif di semua lebar layar HP)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: [
                          // Chip Koordinat Aktif
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.gps_fixed, size: 13, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}'
                                      ' (${widget.selectedKecamatanNama != null ? "Kec. ${widget.selectedKecamatanNama}" : "Kab. Jember"})',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Tombol Ganti Tipe Peta (Jalan / Satelit)
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            elevation: 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _toggleMapType,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                                      size: 15,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isSatellite ? 'Peta' : 'Satelit',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Tombol Re-center ke Lokasi Perangkat
                          Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 3,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _handleSetCurrentLocation(isAuto: false),
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(Icons.my_location_rounded, size: 17, color: Color(0xFFE91E63)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Kontrol Zoom In & Zoom Out Vertikal Standar Google Maps (Bottom-Right)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol Zoom In (+)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                onTap: _zoomIn,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Icon(Icons.add, size: 20, color: Color(0xFF334155)),
                                ),
                              ),
                            ),
                            Container(width: 28, height: 1, color: const Color(0xFFE2E8F0)),
                            // Tombol Zoom Out (-)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                                onTap: _zoomOut,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  child: Icon(Icons.remove, size: 20, color: Color(0xFF334155)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Watermark / Info Google Maps Standar (Bottom-Left, aman dari tombol zoom)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 65,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png',
                              height: 12,
                              errorBuilder: (context, error, stackTrace) => const Text(
                                'Google Maps',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                '• Ketuk peta / cubit untuk zoom',
                                style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Tombol Utama: "Set Lokasi Terkini (GPS)" ─────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGettingLocation ? null : _handleSetCurrentLocation,
              icon: _isGettingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 19),
              label: Text(
                _isGettingLocation ? 'Mendeteksi Posisi GPS...' : 'Set Lokasi Terkini (GPS)',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, letterSpacing: 0.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                shadowColor: const Color(0xFFE91E63).withValues(alpha: 0.35),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Center(
            child: Text(
              'Otomatis isi Kecamatan, Alamat, dan kunci koordinat GPS laporan',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // ── Dropdown Kecamatan (Aman di semua ukuran layar) ─────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Kecamatan (Kab. Jember)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.selectedKecamatanNama != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Terpilih: Kec. ${widget.selectedKecamatanNama}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE91E63)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _loadingKec
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: Color(0xFFE91E63), strokeWidth: 2),
                  ),
                )
                : DropdownButtonFormField<int>(
                  initialValue: widget.selectedKecamatanId,
                  decoration: InputDecoration(
                    hintText: 'Pilih kecamatan lokasi',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE91E63)),
                    ),
                  ),
                  isExpanded: true,
                  items: _kecamatanList.map((kec) {
                    return DropdownMenuItem<int>(
                      value: kec['id'] as int,
                      child: Text(
                        'Kec. ${kec['nama']}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final kec = _kecamatanList.firstWhere((k) => k['id'] == val);
                    final nama = kec['nama'] as String;
                    widget.onKecamatanSelected(val, nama);

                    // Pindahkan peta ke pusat kecamatan tersebut jika ada dalam daftar
                    if (_jemberKecamatanCentroids.containsKey(nama)) {
                      final point = _jemberKecamatanCentroids[nama]!;
                      setState(() => _selectedPoint = point);
                      _mapController.move(point, 15.0);
                      widget.onCoordinateChanged?.call(point.latitude, point.longitude, 'Kec. $nama, Kab. Jember');
                    }
                  },
                ),

          const SizedBox(height: 20),

          // ── Alamat Lokasi (Aman di semua ukuran layar) ─────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Alamat Lokasi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_hasUserLocation && _detectedAddress != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _detectedAddress!,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_hasUserLocation)
                const Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Auto-isi aktif',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.alamatController,
            focusNode: _alamatFocusNode,
            maxLines: 2,
            onChanged: _onAlamatChanged,
            decoration: InputDecoration(
              hintText: 'Contoh: Jl. Kalimantan No. 37, Sumbersari',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _isSearchingAddress
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 19),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE91E63))),
            ),
          ),

          if (_addressSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                itemCount: _addressSuggestions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final suggestion = _addressSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, size: 18, color: Color(0xFFE91E63)),
                    title: Text(
                      suggestion.shortAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      suggestion.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    onTap: () => _selectAddressSuggestion(suggestion),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih hasil pencarian agar titik peta dan koordinat mengikuti alamat jalan.',
              style: TextStyle(fontSize: 10.8, color: Color(0xFF64748B)),
            ),
          ],

          const SizedBox(height: 16),

          // ── Detail / Patokan Lokasi ─────────────────────────────────────
          const Text(
            'Detail / Patokan Lokasi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.detailController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Contoh: Depan Masjid Al-Huda, dekat pertigaan',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE91E63))),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Tambahkan patokan agar petugas dinas mudah menemukan titik kerusakan di lapangan',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
