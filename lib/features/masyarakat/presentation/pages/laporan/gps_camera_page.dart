import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:infrast/core/utils/foto_helper.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GPSCameraScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialLocationLabel;
  final String? initialAlamatJalan;

  const GPSCameraScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialLocationLabel,
    this.initialAlamatJalan,
  });

  @override
  State<GPSCameraScreen> createState() => _GPSCameraScreenState();
}

class _GPSCameraScreenState extends State<GPSCameraScreen> {
  CameraController? _controller;
  Position? _currentPosition;
  String _displayAddress = 'Mencari lokasi...';
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startLocationUpdates();
    _startClock();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _cameraError = 'Kamera tidak ditemukan pada perangkat ini.');
        }
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        setState(() {
          _cameraError =
              'Gagal membuka kamera. Pastikan izin kamera diizinkan, lalu coba lagi.\n$e';
        });
      }
    }
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _startLocationUpdates() async {
    // Set initial value
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = Position(
        latitude: widget.initialLat!,
        longitude: widget.initialLng!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _displayAddress = widget.initialAlamatJalan ?? widget.initialLocationLabel ?? 'Kabupaten Jember';
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
        }
      });
    } catch (e) {
      debugPrint('Location stream error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      // Gunakan data GPS terbaru untuk watermark
      final lat = _currentPosition?.latitude ?? widget.initialLat ?? 0.0;
      final lng = _currentPosition?.longitude ?? widget.initialLng ?? 0.0;
      final label = widget.initialLocationLabel ?? 'Kabupaten Jember';
      final alamat = _displayAddress;

      final watermarkedBytes = await FotoHelper.embedWatermark(
        imageBytes: bytes,
        latitude: lat,
        longitude: lng,
        locationLabel: label,
        alamatJalan: alamat,
      );

      if (mounted) {
        Navigator.pop(context, PhotoItem(
          name: 'gps_cam_${DateTime.now().millisecondsSinceEpoch}.png',
          bytes: watermarkedBytes,
          latitude: lat,
          longitude: lng,
          locationLabel: label,
          timestamp: DateTime.now().toUtc().add(const Duration(hours: 7)),
        ));
      }
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 64),
                const SizedBox(height: 16),
                Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _cameraError = null);
                    _initializeCamera();
                  },
                  child: const Text('Coba Lagi'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nowWib = _currentTime.toUtc().add(const Duration(hours: 7));
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(nowWib);
    final formattedTime = DateFormat('HH:mm:ss').format(nowWib);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),

          // 2. GPS Overlay (Bottom)
          Positioned(
            bottom: 110,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map Snippet
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 110,
                      height: 110,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            _currentPosition?.latitude ?? widget.initialLat ?? 0.0,
                            _currentPosition?.longitude ?? widget.initialLng ?? 0.0,
                          ),
                          initialZoom: 16,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.jeki.infrast',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  _currentPosition?.latitude ?? widget.initialLat ?? 0.0,
                                  _currentPosition?.longitude ?? widget.initialLng ?? 0.0,
                                ),
                                child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Information Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.initialLocationLabel ?? 'Kabupaten Jember'} 🇮🇩',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _displayAddress,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lat ${_currentPosition?.latitude.toStringAsFixed(6)}° Long ${_currentPosition?.longitude.toStringAsFixed(6)}°',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$formattedDate $formattedTime WIB GMT +07:00',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Note : Captured by JEKI Infrastruktur',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Capture Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: _isCapturing ? Colors.grey : Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Back Button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
