import 'package:flutter/material.dart';
import 'package:infrast/features/auth/data/auth_service.dart';
import 'package:infrast/features/auth/presentation/screens/login_screen.dart';
import 'package:infrast/features/pelaksana/data/tugas_service.dart';
import 'package:infrast/features/pelaksana/presentation/screens/tugas_list_screen.dart';
import 'package:infrast/features/pelaksana/presentation/screens/tugas_detail_screen.dart';
import 'package:infrast/presentation/widgets/dialogs/user_friendly_dialog.dart';

class PelaksanaHomePage extends StatefulWidget {
  const PelaksanaHomePage({super.key});

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    final name      = _user?['name'] ?? 'Petugas Lapangan';
    final email     = _user?['email'] ?? '-';
    final keahlian  = _roleData?['keahlian'] ?? 'Spesialis Infrastruktur';
    final kecamatan = _roleData?['kecamatan']?['nama'] ?? 'Kabupaten Jember';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text(
          'JEKI — Pelaksana',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan Server',
            icon: const Icon(Icons.dns_rounded),
            onPressed: () => UserFriendlyDialog.showServerConfigModal(context, onSaved: _loadProfile),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Profil ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(email,
                                  style: const TextStyle(
                                      fontSize: 12.5, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _badge(Icons.handyman_rounded, keahlian,
                            const Color(0xFF60A5FA), const Color(0xFF2563EB)),
                        _badge(Icons.location_on_rounded, 'Kec. $kecamatan',
                            Colors.white, Colors.white.withValues(alpha: 0.1)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Status Koneksi ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (_isServerConnected
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626))
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_isServerConnected
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626))
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isServerConnected
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isServerConnected
                              ? 'Server Backend Terhubung (Live)'
                              : 'Server Terputus: php artisan serve mungkin mati',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isServerConnected
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Statistik Tugas ───────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Status Penugasan Lapangan',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _statCard('Baru', '${_stats['ditugaskan'] ?? 0}',
                        const Color(0xFF2563EB), Icons.assignment_outlined),
                    const SizedBox(width: 12),
                    _statCard('Dikerjakan', '${_stats['dikerjakan'] ?? 0}',
                        const Color(0xFFD97706), Icons.engineering_outlined),
                    const SizedBox(width: 12),
                    _statCard('Selesai', '${_stats['selesai'] ?? 0}',
                        const Color(0xFF16A34A), Icons.task_alt_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Penugasan Terkini ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Penugasan Terkini',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (_) => const TugasListScreen()))
                          .then((_) => _loadProfile()),
                      child: const Text('Lihat Semua >',
                          style: TextStyle(
                              color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _recentTugas.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: Text(
                            'Belum ada tugas aktif.\nTarik ke bawah untuk refresh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      )
                    : Column(
                        children: _recentTugas.map((t) {
                          final laporan = t['laporan'] as Map? ?? {};
                          final status  = laporan['status'] as String? ?? 'ditugaskan';
                          final (color, bg) = _statusColorPair(status);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(laporan['nomor'] ?? '-',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2563EB))),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: bg, borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        laporan['status_label'] ?? status,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: color),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(laporan['judul'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                if (t['catatan'] != null &&
                                    (t['catatan'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(t['catatan'],
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFF64748B)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                const Divider(height: 20),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(laporan['kecamatan'] ?? '-',
                                          style: const TextStyle(
                                              fontSize: 12, color: Color(0xFF64748B))),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (_) => TugasDetailScreen(
                                                  tugasId: t['id'] as int)))
                                          .then((_) => _loadProfile()),
                                      icon: const Icon(Icons.arrow_forward, size: 14),
                                      label: const Text('Kerjakan',
                                          style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: iconColor)),
        ],
      ),
    );
  }

  Widget _statCard(String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(count,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  (Color, Color) _statusColorPair(String status) {
    return switch (status) {
      'ditugaskan'                     => (const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      'dikerjakan'                     => (const Color(0xFFD97706), const Color(0xFFFFFBEB)),
      'menunggu_konfirmasi_admin'      => (const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
      'menunggu_konfirmasi_masyarakat' => (const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
      'selesai'                        => (const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      'dikonfirmasi'                   => (const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      _                                => (const Color(0xFF94A3B8), const Color(0xFFF8FAFC)),
    };
  }
}
