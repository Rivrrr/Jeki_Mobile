import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/theme/app_decor.dart';
import 'package:infrast/features/auth/data/auth_service.dart';
import 'package:infrast/features/auth/presentation/screens/login_screen.dart';
import 'package:infrast/features/pelaksana/data/tugas_service.dart';
import 'package:infrast/features/pelaksana/presentation/screens/tugas_list_screen.dart';
import 'package:infrast/features/pelaksana/presentation/screens/tugas_detail_screen.dart';

class PelaksanaHomePage extends StatefulWidget {
  final VoidCallback? onOpenLaporan;

  const PelaksanaHomePage({
    super.key,
    this.onOpenLaporan,
  });

  @override
  State<PelaksanaHomePage> createState() => _PelaksanaHomePageState();
}

class _PelaksanaHomePageState extends State<PelaksanaHomePage> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _roleData;
  Map<String, dynamic> _stats = {'total': 0, 'ditugaskan': 0, 'dikerjakan': 0, 'selesai': 0};
  List<Map<String, dynamic>> _recentTugas = [];
  bool _isLoading = true;
  bool _isServerConnected = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── LOGIC: TIDAK DISENTUH ──────────────────────────────────────────────
  void _loadProfile() async {
    final user     = await AuthService.getUser();
    final health   = await AuthService.checkHealth();

    if (!mounted) return;
    setState(() {
      _user              = user;
      _roleData          = user?['role_data'] as Map<String, dynamic>?;
      _isServerConnected = health['success'] == true;
    });

    if (_isServerConnected) {
      final statsRes = await TugasService.fetchStats();
      final tugasRes = await TugasService.fetchTugas();
      if (!mounted) return;
      setState(() {
        if (statsRes['success'] == true) {
          final d = statsRes['data']?['data'] ?? statsRes['data'] ?? {};
          _stats = Map<String, dynamic>.from(d is Map ? d : {});
        }
        if (tugasRes['success'] == true) {
          final list = List<Map<String, dynamic>>.from(
              tugasRes['data']?['data'] ?? tugasRes['data'] ?? []);
          _recentTugas = list.take(3).toList();
        }
        _isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Petugas Pelaksana?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // ── BUILD (UI: Tanpa Scaffold) ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return ColoredBox(
      color: AppColors.background,
      child: _homeTab(),
    );
  }

  // ── TAB BERANDA (Visual 100% utuh) ─────────────────────────────────────
  Widget _homeTab() {
    final name      = _user?['name'] ?? 'Petugas Lapangan';
    final keahlian  = _roleData?['keahlian'] ?? 'Spesialis Infrastruktur';
    final kecamatan = _roleData?['kecamatan']?['nama'] ?? 'Kabupaten Jember';
    final topInset  = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _loadProfile(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('JEKI — Pelaksana',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85))),
                      ),
                      _connectionBanner(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withValues(alpha: 0.25),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Halo,',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: 0.85))),
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _badge(Icons.handyman_rounded, keahlian),
                            _badge(Icons.location_on_rounded, 'Kec. $kecamatan'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Status Penugasan Lapangan',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard('Baru', '${_stats['ditugaskan'] ?? 0}',
                          AppColors.primary, Icons.assignment_outlined),
                      const SizedBox(width: 12),
                      _statCard('Dikerjakan', '${_stats['dikerjakan'] ?? 0}',
                          AppColors.statusProcessing, Icons.engineering_outlined),
                      const SizedBox(width: 12),
                      _statCard('Selesai', '${_stats['selesai'] ?? 0}',
                          AppColors.statusCompleted, Icons.task_alt_outlined),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('Penugasan Terkini'),
                      TextButton(
                        onPressed: () => widget.onOpenLaporan?.call(),
                        child: const Text('Lihat Semua >',
                            style: TextStyle(
                                color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_recentTugas.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: AppDecor.card(),
                      child: const Text(
                        'Belum ada tugas aktif.\nTarik ke bawah untuk refresh.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    )
                  else
                    ..._recentTugas.map(_tugasCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget helper (Visual 100% utuh) ───────────────────────────────────
  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      );

  Widget _connectionBanner() {
    final color = _isServerConnected ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _isServerConnected ? 'Terhubung' : 'Tidak terhubung',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _statCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.card(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(count,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _tugasCard(Map<String, dynamic> t) {
    final laporan = t['laporan'] as Map? ?? {};
    final status  = laporan['status'] as String? ?? 'ditugaskan';
    final (color, bg) = _statusColorPair(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentPink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(laporan['nomor'] ?? '-',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  laporan['status_label'] ?? status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(laporan['judul'] ?? '',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          if (t['catatan'] != null && (t['catatan'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(t['catatan'],
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(laporan['kecamatan'] ?? '-',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => TugasDetailScreen(tugasId: t['id'] as int)))
                    .then((_) => _loadProfile()),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text('Kerjakan', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _statusColorPair(String status) {
    return switch (status) {
      'ditugaskan'                     => (AppColors.statusPending, AppColors.statusPendingBg),
      'dikerjakan'                     => (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'menunggu_konfirmasi_admin'      => (AppColors.statusVerification, AppColors.statusVerificationBg),
      'menunggu_konfirmasi_masyarakat' => (AppColors.statusVerification, AppColors.statusVerificationBg),
      'selesai'                        => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      'dikonfirmasi'                   => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      _                                => (AppColors.textMuted, AppColors.background),
    };
  }
}