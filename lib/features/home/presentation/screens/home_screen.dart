import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/storage_service.dart';
import 'package:infrast/features/auth/data/auth_service.dart';
import 'package:infrast/features/home/data/laporan_service.dart';
import 'package:infrast/features/home/presentation/widgets/home_widgets.dart';
import 'package:infrast/features/laporan/presentation/screens/create_laporan_screen.dart';
import 'package:infrast/presentation/pages/laporan/detail/laporan_detail_page.dart';
import 'package:infrast/presentation/pages/laporan/list/my_laporan_page.dart';
import 'package:infrast/presentation/pages/notifikasi/notifikasi_page.dart';
import 'package:infrast/presentation/pages/peta/peta_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _myReports = [];
  List<Map<String, dynamic>> _nearbyReports = [];
  bool _loadingReports = true;
  int _countTotal = 0;
  int _countDiproses = 0;
  int _countSelesai = 0;
  int _notifCount = 0;
  String? _userName;

  // Lokasi pengguna untuk filter laporan terdekat
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadUserLocation();
    _loadReports();
  }

  Future<void> _loadUser() async {
    final local = await StorageService.getUser();
    if (mounted && local != null) {
      setState(() {
        _userName = local['name'] as String? ?? (local['email'] as String?)?.split('@')[0];
      });
    }
    try {
      final synced = await AuthService.syncUser();
      if (mounted && synced != null) {
        setState(() {
          _userName = synced['name'] as String? ?? (synced['email'] as String?)?.split('@')[0];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
        _filterNearby();
      }
    } catch (_) {}
  }

  Future<void> _loadReports() async {
    setState(() => _loadingReports = true);
    // Refresh user profile asynchronously
    _loadUser();
    // Load laporan saya + semua laporan untuk peta/sekitar secara paralel
    final results = await Future.wait([
      LaporanService.fetchMyLaporan(),
      LaporanService.fetchAllLaporan(),
    ]);

    if (!mounted) return;

    // Laporan milik saya
    if (results[0]['success'] == true) {
      final list = List<Map<String, dynamic>>.from(results[0]['data'] ?? []);
      int total = list.length;
      int diproses = list.where((r) {
        final s = (r['status'] as String? ?? '').toLowerCase();
        return ['ditinjau', 'ditugaskan', 'dikerjakan'].contains(s);
      }).length;
      int selesai = list.where((r) {
        final s = (r['status'] as String? ?? '').toLowerCase();
        return ['selesai', 'dikonfirmasi'].contains(s);
      }).length;

      // Hitung notif: laporan dengan update dalam 3 hari terakhir
      int notif = list.where((r) {
        final riwayat = r['riwayat'] as List? ?? [];
        if (riwayat.isEmpty) return false;
        try {
          final last = riwayat.last as Map;
          final tanggal = last['tanggal'] ?? last['created_at'];
          if (tanggal == null) return false;
          return DateTime.now().difference(DateTime.parse(tanggal.toString())).inDays <= 3;
        } catch (_) {
          return false;
        }
      }).length;

      setState(() {
        _myReports = list;
        _countTotal = total;
        _countDiproses = diproses;
        _countSelesai = selesai;
        _notifCount = notif;
        _loadingReports = false;
      });
    } else {
      setState(() => _loadingReports = false);
    }

    // Laporan di sekitar (semua laporan berkoordinat)
    if (results[1]['success'] == true) {
      final allLaporan = List<Map<String, dynamic>>.from(results[1]['data'] ?? []);
      setState(() {
        // Simpan semua dahulu, filter akan dilakukan setelah lokasi tersedia
        _nearbyReports = allLaporan;
      });
      _filterNearby();
    }
  }

  /// Filter laporan terdekat dari posisi user (radius 5 km, max 5 laporan)
  void _filterNearby() {
    if (_userLat == null || _userLng == null || _nearbyReports.isEmpty) return;

    final withDist = _nearbyReports
        .where((l) => l['latitude'] != null && l['longitude'] != null)
        .map((l) {
          final lat = _parseDouble(l['latitude']) ?? 0.0;
          final lng = _parseDouble(l['longitude']) ?? 0.0;
          final dist = _haversineKm(_userLat!, _userLng!, lat, lng);
          return {...l, '_distance_km': dist};
        })
        .where((l) => (l['_distance_km'] as double) <= 5.0)
        .toList()
      ..sort((a, b) => (a['_distance_km'] as double).compareTo(b['_distance_km'] as double));

    if (mounted) {
      setState(() {
        _nearbyReports = withDist.take(5).toList();
      });
    }
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * math.pi / 180;

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  void _openCreateLaporan() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreateLaporanScreen()))
        .then((_) => _loadReports());
  }

  void _openMyLaporan() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MyLaporanPage()))
        .then((_) => _loadReports());
  }

  void _openPeta() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PetaPage()));
  }

  void _openNotifikasi() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NotifikasiPage()))
        .then((_) => _loadReports());
  }

  void _openDetail(int id) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => LaporanDetailPage(laporanId: id)))
        .then((_) => _loadReports());
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReports,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header + tombol notifikasi fungsional
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    HomeHeader(
                      onNotifTap: _openNotifikasi,
                      notifCount: _notifCount,
                      userName: _userName,
                    ),
                    const Positioned(
                      bottom: -24,
                      left: 0,
                      right: 0,
                      child: FloatingSearchBar(),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // 2. KPI Cards — data real
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      KPICard(
                        icon: Icons.description_outlined,
                        iconColor: AppColors.primary,
                        bgColor: AppColors.accentPink,
                        count: _loadingReports ? '-' : _countTotal.toString(),
                        label: 'Laporan Saya',
                      ),
                      const SizedBox(width: 12),
                      KPICard(
                        icon: Icons.settings_outlined,
                        iconColor: Colors.orange,
                        bgColor: const Color(0xFFFFF3E0),
                        count: _loadingReports ? '-' : _countDiproses.toString(),
                        label: 'Diproses',
                      ),
                      const SizedBox(width: 12),
                      KPICard(
                        icon: Icons.check_circle_outline,
                        iconColor: Colors.green,
                        bgColor: const Color(0xFFE8F5E9),
                        count: _loadingReports ? '-' : _countSelesai.toString(),
                        label: 'Selesai',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3. Aksi Cepat
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      QuickActionItem(
                        icon: Icons.camera_alt_rounded,
                        label: 'Lapor\nSekarang',
                        isPrimary: true,
                        onTap: _openCreateLaporan,
                      ),
                      QuickActionItem(
                        icon: Icons.file_copy_outlined,
                        label: 'Laporan\nSaya',
                        onTap: _openMyLaporan,
                      ),
                      QuickActionItem(
                        icon: Icons.map_outlined,
                        label: 'Peta\nLokasi',
                        onTap: _openPeta,
                      ),
                      QuickActionItem(
                        icon: Icons.notifications_outlined,
                        label: 'Riwayat\nUpdate',
                        onTap: _openNotifikasi,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 4. Laporan Terbaru Saya — data real
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laporan Terbaru Saya',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 4),
                              Text('Update real-time',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          TextButton(
                            onPressed: _openMyLaporan,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Lihat Semua >',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loadingReports)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        )
                      else if (_myReports.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(color: AppColors.accentPink, shape: BoxShape.circle),
                                child: const Icon(Icons.note_add_outlined, color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(height: 12),
                              const Text('Belum Ada Laporan',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              const Text(
                                'Laporkan fasilitas umum atau jalan rusak di sekitar Anda untuk ditangani segera.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openCreateLaporan,
                                icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                                label: const Text('Buat Laporan Sekarang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._myReports.take(3).map((r) {
                          final fotos = r['foto'] as List?;
                          final String? imgUrl = (fotos != null && fotos.isNotEmpty)
                              ? fotos.first['url'] as String?
                              : null;
                          return RecentReportTile(
                            title: r['judul'] ?? 'Laporan Tanpa Judul',
                            location: r['lokasi'] ?? r['kecamatan']?['nama'] ?? 'Kab. Jember',
                            date: _formatDate(r['created_at'] as String?),
                            status: r['status_label'] ?? r['status'] ?? 'Baru',
                            imageUrl: imgUrl,
                            onTap: () => _openDetail(r['id'] as int),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Laporan di Sekitar — data real dari backend
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Laporan di Sekitar',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(
                                  _userLat != null ? 'Radius 5 km dari lokasi Anda' : 'Aktifkan GPS untuk filter lokasi',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: _openPeta,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Lihat Peta >',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 170,
                        child: _nearbyReports.isEmpty
                            ? ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width - 48,
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.location_searching_rounded, color: AppColors.textMuted, size: 32),
                                          const SizedBox(height: 8),
                                          Text(
                                            _userLat == null
                                                ? 'Izinkan akses lokasi untuk\nmelihat laporan di sekitar Anda'
                                                : 'Tidak ada laporan dalam\nradius 5 km dari lokasi Anda',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _nearbyReports.length,
                                itemBuilder: (_, i) {
                                  final l = _nearbyReports[i];
                                  final foto = l['foto'] as List?;
                                  final imgUrl = (foto != null && foto.isNotEmpty) ? foto.first['url'] as String? : null;
                                  final distKm = l['_distance_km'] as double?;
                                  return NearbyReportCard(
                                    title: l['judul'] ?? '-',
                                    distance: distKm != null ? _formatDistance(distKm) : '-',
                                    status: l['status_label'] ?? l['status'] ?? 'Baru',
                                    imageUrl: imgUrl,
                                    onTap: () => _openDetail(l['id'] as int),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 6. Contribution Banner — data real
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ContributionBanner(totalSelesai: _countSelesai),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

