import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infrast/core/constants/api_constants.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/auth/data/auth_service.dart';
import 'package:infrast/features/auth/presentation/screens/login_screen.dart';
import 'package:infrast/features/pelaksana/data/tugas_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _roleData;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  final String _lastSyncTime = 'Hari ini 14:15';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── LOGIC: Mengambil data user & statistik petugas ─────────────────────
  Future<void> _loadProfile() async {
    final user = await AuthService.getUser();
    Map<String, dynamic> stats = {};

    try {
      final statsRes = await TugasService.fetchStats();
      if (statsRes['success'] == true) {
        final d = statsRes['data']?['data'] ?? statsRes['data'] ?? {};
        if (d is Map) {
          stats = Map<String, dynamic>.from(d);
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _user = user;
      _roleData = user?['role_data'] as Map<String, dynamic>?;
      _stats = stats;
      _isLoading = false;
    });
  }

  // ── URL Foto Profil ───────────────────────────────────────────────────
  String? _resolvePhotoUrl(Map<String, dynamic>? user) {
    if (user == null) return null;
    final full = user['foto_profil_url']?.toString();
    if (full != null && full.startsWith('http')) return full;
    final path = user['foto_profil']?.toString() ?? '';
    if (path.isEmpty) return null;
    final base = ApiConstants.baseUrl;
    return '$base/media/${path.startsWith('/') ? path.substring(1) : path}';
  }

  // ── LOGIC: Salin Teks ke Clipboard ────────────────────────────────────
  void _copyText(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E2432),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── LOGIC: Sinkronisasi Perangkat ─────────────────────────────────────
  void _syncDevice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Perangkat URC-04 berhasil disinkronkan',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E2432),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── MODAL: Pusat Bantuan & Kontak ─────────────────────────────────────
  void _showPusatBantuanModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Pusat Bantuan & Kontak URC',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E2432),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Operasional & Dukungan Teknis Lapangan 24 Jam',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF757F95),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                title: Text(
                  'Call Center Dinas PU (24 Jam)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2432),
                  ),
                ),
                subtitle: Text(
                  '(0331) 487-123 / Hotline Darurat URC',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757F95)),
                ),
                onTap: () {
                  _copyText('(0331) 487-123', 'Nomor Hotline disalin: (0331) 487-123');
                },
              ),
              const Divider(color: Color(0xFFF1F3F7)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFFFD3F92), size: 22),
                ),
                title: Text(
                  'SOP Penanganan Lapangan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2432),
                  ),
                ),
                subtitle: Text(
                  'Panduan verifikasi, dokumentasi, & keselamatan kerja',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757F95)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── LOGIC: Logout ─────────────────────────────────────────────────────
  void _handleLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Konfirmasi Keluar',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF1E2432),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Petugas Pelaksana?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
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
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: Avatar ────────────────────────────────────────────────────
  Widget _buildAvatarImage(String? photoUrl, String name) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(name),
      );
    }
    return Image.asset(
      'assets/images/sample_avatar_petugas.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(name),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'P';
    return Container(
      color: const Color(0xFFFDE8F2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFD3F92),
        ),
      ),
    );
  }

  // ── WIDGET: Statistik Column Item ─────────────────────────────────────
  Widget _buildStatItem(String label, String value, {bool isPink = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isPink ? const Color(0xFFFD3F92) : const Color(0xFF1E2432),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757F95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE5E7EB),
    );
  }

  // ── WIDGET: Baris Informasi Petugas ───────────────────────────────────
  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF757F95),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2432),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildListDivider() {
    return const Divider(
      height: 1,
      indent: 56,
      color: Color(0xFFF1F3F7),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FD),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final topInset = MediaQuery.of(context).padding.top;

    // Data Petugas
    final name = _user?['name']?.toString() ?? 'Budi Santoso';
    final rawId = _user?['id']?.toString() ?? '0002';
    final petugasId = _roleData?['kode_petugas']?.toString() ??
        _roleData?['id_petugas']?.toString() ??
        '#PK-${rawId.padLeft(4, '0')}';
    
    // Bidang pekerjaan
    final keahlian = _roleData?['keahlian']?.toString() ??
        _roleData?['bidang']?.toString() ??
        'Pengaspalan & Perbaikan Jalan';
    final posisi = _roleData?['posisi']?.toString() ?? 'Lapangan';

    // Statistik
    final totalSelesai = _stats['selesai']?.toString() ?? '139';
    final tepatWaktu = _stats['tepat_waktu']?.toString() ?? '99.2%';
    final bulanDinas = _roleData?['bulan_dinas']?.toString() ?? '18';

    // Informasi Data Petugas
    final noHp = _user?['phone']?.toString() ??
        _user?['no_hp']?.toString() ??
        '+62 812-3456-7890';
    final nip = _roleData?['nip']?.toString() ??
        _user?['nip']?.toString() ??
        '19890412 201403 1 002';
    final jabatan = _roleData?['jabatan']?.toString() ??
        _roleData?['posisi']?.toString() ??
        'Teknisi Lapangan URC';
    final kecNama = _roleData?['kecamatan']?['nama']?.toString();
    final wilayahTugas = kecNama != null && kecNama.isNotEmpty
        ? 'Kec. $kecNama'
        : (_roleData?['wilayah']?.toString() ?? 'Kabupaten Jember');
    final zonaTugas = _roleData?['zona']?.toString() ?? 'Zona A';

    final photoUrl = _resolvePhotoUrl(_user);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── 1. HEADER PROFIL (Background Pink Full Width, Edge-to-Edge) ──
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 36),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // Avatar Petugas dengan Ring Putih & Verified Badge Hijau
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: ClipOval(
                              child: _buildAvatarImage(photoUrl, name),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF22C55E),
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nama Petugas
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Pill ID Petugas
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.40),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'ID Petugas: $petugasId',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle Bidang Pekerjaan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$keahlian • $posisi',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 2. STATISTIK AKTIVITAS PETUGAS ───────────────────────
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildStatItem('Total Selesai', totalSelesai, isPink: false),
                      _buildStatDivider(),
                      _buildStatItem('Tepat Waktu', tepatWaktu, isPink: true),
                      _buildStatDivider(),
                      _buildStatItem('Bulan Dinas', bulanDinas, isPink: false),
                    ],
                  ),
                ),
              ),

              // ── 3. INFORMASI DATA PETUGAS (Nomor HP, NIP, Jabatan, Wilayah, Pusat Bantuan) ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 1. Nomor HP
                          _buildInfoRow(
                            icon: Icons.phone_rounded,
                            iconColor: const Color(0xFFFD3F92),
                            iconBg: const Color(0xFFFFF0F5),
                            label: 'Nomor HP',
                            value: noHp,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 18,
                              ),
                              splashRadius: 20,
                              onPressed: () => _copyText(noHp, 'Nomor HP disalin: $noHp'),
                            ),
                          ),
                          _buildListDivider(),

                          // 2. NIP
                          _buildInfoRow(
                            icon: Icons.badge_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                            label: 'NIP',
                            value: nip,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: Color(0xFF9CA3AF),
                                size: 18,
                              ),
                              splashRadius: 20,
                              onPressed: () => _copyText(nip, 'NIP disalin: $nip'),
                            ),
                          ),
                          _buildListDivider(),

                          // 3. Jabatan
                          _buildInfoRow(
                            icon: Icons.work_outline_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF5F3FF),
                            label: 'Jabatan',
                            value: jabatan,
                          ),
                          _buildListDivider(),

                          // 4. Wilayah Tugas
                          _buildInfoRow(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFECFDF5),
                            label: 'Wilayah Tugas',
                            value: wilayahTugas,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                zonaTugas,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7E22CE),
                                ),
                              ),
                            ),
                          ),
                          _buildListDivider(),

                          // 5. Pusat Bantuan
                          InkWell(
                            onTap: _showPusatBantuanModal,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(
                                      Icons.support_agent_rounded,
                                      color: Color(0xFFEA580C),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pusat Bantuan',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E2432),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          'SOP & Kontak Operasional 24 Jam',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11.5,
                                            color: const Color(0xFF757F95),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF9CA3AF),
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── STATUS PERANGKAT URC ──
                    InkWell(
                      onTap: _syncDevice,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3EFFC),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.devices_rounded,
                                color: Color(0xFF7C3AED),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Perangkat URC-04',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E2432),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'Sinkronisasi: $_lastSyncTime',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: const Color(0xFF757F95),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Tersinkron',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── TOMBOL: KELUAR AKUN PETUGAS ──
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleLogout,
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Keluar Akun Petugas',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── FOOTER: INFORMASI SISTEM ──
                    Text(
                      'Sistem Pengendalian Lapangan v2.4.0 • Sandi Petugas Terenkripsi',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9CA3AF),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
