import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/api_client.dart';
import 'package:infrast/core/theme/app_decor.dart';
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
  Map<String, dynamic> _stats = const {};
  bool _isLoading = true;
  bool _isSynced = false;
  DateTime? _lastSync;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── LOGIC: Mengambil data user & statistik pelaksana dari Admin/API ─────
  Future<void> _loadProfile() async {
    final cachedUser = await AuthService.getUser();
    if (mounted && cachedUser != null) {
      setState(() {
        _user = cachedUser;
        _roleData = cachedUser['role_data'] as Map<String, dynamic>?;
      });
    }

    final results = await Future.wait([
      ApiClient.get('/user'),
      TugasService.fetchStats(),
    ]);

    if (!mounted) return;

    final userRes = results[0];
    final statsRes = results[1];

    Map<String, dynamic>? freshUser = _user;
    Map<String, dynamic>? freshRoleData = _roleData;
    bool synced = false;

    if (userRes['success'] == true && userRes['data'] is Map) {
      final payload = Map<String, dynamic>.from(userRes['data'] as Map);
      if (payload['user'] is Map) {
        freshUser = Map<String, dynamic>.from(payload['user'] as Map);
      }
      if (payload['role_data'] is Map) {
        freshRoleData = Map<String, dynamic>.from(payload['role_data'] as Map);
      }
      synced = true;
    }

    Map<String, dynamic> freshStats = _stats;
    if (statsRes['success'] == true && statsRes['data'] is Map) {
      final raw = statsRes['data'] as Map;
      final inner = raw['data'] is Map ? raw['data'] as Map : raw;
      freshStats = Map<String, dynamic>.from(inner);
      synced = true;
    }

    setState(() {
      _user = freshUser;
      _roleData = freshRoleData;
      _stats = freshStats;
      _isSynced = synced;
      if (synced) _lastSync = DateTime.now();
      _isLoading = false;
    });
  }

  String _cleanText(dynamic value, {String fallback = '-'}) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') {
      return fallback;
    }
    return text;
  }

  String _formatIdPetugas() {
    final rawId = _roleData?['id'] ?? _user?['id'];
    if (rawId == null) return '-';
    final idStr = rawId.toString().trim();
    if (idStr.isEmpty || idStr == 'null') return '-';
    return '#PK-${idStr.padLeft(4, '0')}';
  }

  String _formatWilayahTugas() {
    final wilayahKoordinasi =
        _cleanText(_roleData?['wilayah_koordinasi'], fallback: '');
    if (wilayahKoordinasi.isNotEmpty) return wilayahKoordinasi;

    final kecamatanNama =
        _cleanText(_roleData?['kecamatan']?['nama'], fallback: '');
    if (kecamatanNama.isNotEmpty) return 'Kec. $kecamatanNama';

    return 'Kabupaten Jember';
  }

  String _formatBulanDinas() {
    final rawDate = _roleData?['created_at']?.toString();
    if (rawDate == null || rawDate.isEmpty) return '0';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return '0';
    final months =
        ((DateTime.now().year - parsed.year) * 12) +
        (DateTime.now().month - parsed.month);
    return (months < 1 ? 1 : months).toString();
  }

  String _formatTerdaftarSejak() {
    final rawDate = _roleData?['created_at']?.toString();
    if (rawDate == null || rawDate.isEmpty) return '-';
    final parsed = DateTime.tryParse(rawDate)?.toLocal();
    if (parsed == null) return '-';
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${parsed.day} ${bulan[parsed.month - 1]} ${parsed.year}';
  }

  String _formatSyncTime() {
    if (_lastSync == null) return 'Sinkronisasi: Data tersimpan lokal';
    final hh = _lastSync!.hour.toString().padLeft(2, '0');
    final mm = _lastSync!.minute.toString().padLeft(2, '0');
    return 'Sinkronisasi: Hari ini $hh:$mm';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ── LOGIC: Pusat Bantuan Modal ──────────────────────────────────────────
  void _showPusatBantuan() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pusat Bantuan & Kontak Operasional',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hubungi admin operasional jika terdapat kendala penugasan, data akun, atau sinkronisasi lapangan.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            _buildHelpContactItem(
              icon: Icons.support_agent_rounded,
              title: 'Posko Operasional JEKI (24 Jam)',
              subtitle: '(0331) 485-210 • Siaga Darurat Infrastruktur',
            ),
            const SizedBox(height: 12),
            _buildHelpContactItem(
              icon: Icons.chat_outlined,
              title: 'WhatsApp Admin Lapangan',
              subtitle: '+62 811-3500-992',
            ),
            const SizedBox(height: 12),
            _buildHelpContactItem(
              icon: Icons.email_outlined,
              title: 'Email Bantuan Teknis',
              subtitle: 'operasional@jeki.go.id',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LOGIC: Logout (Disalin utuh dari Home) ─────────────────────────────
  void _handleLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun Petugas Pelaksana?',
        ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _cleanText(
      _user?['name'] ?? _roleData?['nama'],
      fallback: 'Petugas Lapangan',
    );
    final keahlian = _cleanText(
      _roleData?['keahlian'],
      fallback: 'Pelaksana Lapangan',
    );
    final idPelaksana = _formatIdPetugas();
    final fotoUrl = _cleanText(_user?['foto_profil_url'], fallback: '');

    final email = _cleanText(_roleData?['email'] ?? _user?['email']);
    final nip = _cleanText(
      _roleData?['nik_nip'] ??
          _roleData?['nip'] ??
          _roleData?['nik'] ??
          _user?['nik_nip'] ??
          _user?['nip'],
    );
    final jabatan = _cleanText(
      _roleData?['peran_koordinator'],
      fallback: 'Petugas Pelaksana Lapangan',
    );
    final keterangan = _cleanText(_roleData?['keterangan_pegawai']);
    final wilayahTugas = _formatWilayahTugas();
    final terdaftarSejak = _formatTerdaftarSejak();

    final totalTugas = _toInt(_stats['total']);
    final bulanDinas = _formatBulanDinas();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  children: [
                    // 1. Header Profil Full-Width Pink + Bar Statistik Putih di dalam Header
                    _buildFullWidthHeader(
                      name: name,
                      idPelaksana: idPelaksana,
                      keahlian: keahlian,
                      fotoUrl: fotoUrl,
                      totalTugas: totalTugas.toString(),
                      bulanDinas: bulanDinas,
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        children: [
                          // 2. Informasi Data Petugas Terdaftar di Admin (1 Card bersih)
                          Container(
                            decoration: AppDecor.card(radius: 18),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.person_outline_rounded,
                                  iconColor: AppColors.primary,
                                  iconBgColor: AppColors.accentPink,
                                  label: 'Nama Lengkap',
                                  value: name,
                                ),
                                _buildDivider(),
                                _buildInfoRow(
                                  icon: Icons.credit_card_outlined,
                                  iconColor: const Color(0xFF6366F1),
                                  iconBgColor: const Color(0xFFEEF2FF),
                                  label: 'NIP',
                                  value: nip,
                                ),
                                _buildDivider(),
                                _buildInfoRow(
                                  icon: Icons.email_outlined,
                                  iconColor: const Color(0xFF0EA5E9),
                                  iconBgColor: const Color(0xFFE0F2FE),
                                  label: 'Email Akun',
                                  value: email,
                                ),
                                _buildDivider(),
                                _buildInfoRow(
                                  icon: Icons.engineering_outlined,
                                  iconColor: AppColors.statusCompleted,
                                  iconBgColor: AppColors.statusCompletedBg,
                                  label: 'Bidang Keahlian',
                                  value: keahlian,
                                ),
                                _buildDivider(),
                                _buildInfoRow(
                                  icon: Icons.work_outline_rounded,
                                  iconColor: AppColors.statusProcessing,
                                  iconBgColor: AppColors.statusProcessingBg,
                                  label: 'Peran / Jabatan',
                                  value: jabatan,
                                ),
                                _buildDivider(),
                                _buildInfoRow(
                                  icon: Icons.badge_outlined,
                                  iconColor: const Color(0xFF8B5CF6),
                                  iconBgColor: const Color(0xFFF3E8FF),
                                  label: 'Keterangan',
                                  value: keterangan,
                                ),
                                _buildDivider(),
                                _buildInfoRow(
                                  icon: Icons.location_on_outlined,
                                  iconColor: AppColors.statusVerification,
                                  iconBgColor: AppColors.statusVerificationBg,
                                  label: 'Wilayah Tugas',
                                  value: wilayahTugas,
                                ),
                                _buildDivider(),
                                _buildInfoRow(
                                  icon: Icons.calendar_today_outlined,
                                  iconColor: const Color(0xFF14B8A6),
                                  iconBgColor: const Color(0xFFCCFBF1),
                                  label: 'Terdaftar Sejak',
                                  value: terdaftarSejak,
                                ),
                                _buildDivider(),
                                _buildInfoRow(
                                  icon: Icons.support_agent_rounded,
                                  iconColor: const Color(0xFF7C3AED),
                                  iconBgColor: const Color(0xFFF3E8FF),
                                  titlePrimary: 'Pusat Bantuan',
                                  subtitleSecondary:
                                      'SOP & Kontak Operasional 24 Jam',
                                  onTap: _showPusatBantuan,
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Informasi Perangkat
                          _buildDeviceInfoCard(),
                          const SizedBox(height: 16),

                          // 4. Tombol Logout
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout_rounded, size: 19),
                              label: const Text(
                                'Keluar Akun Petugas',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFCE8E6),
                                foregroundColor: AppColors.error,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 5. Footer Info
                          const Text(
                            'Sistem Pengendalian Lapangan v2.4.0 • Sandi Petugas Terenkripsi',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Header Profil Pink Full-Width + Statistik ───────────────────────────
  Widget _buildFullWidthHeader({
    required String name,
    required String idPelaksana,
    required String keahlian,
    required String fotoUrl,
    required String totalTugas,
    required String bulanDinas,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 20, 16, 18),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Avatar dengan badge centang hijau
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage:
                      fotoUrl.isNotEmpty ? NetworkImage(fotoUrl) : null,
                  child: fotoUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'P',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.statusCompleted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nama Petugas
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Badge ID Petugas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'ID Petugas: $idPelaksana',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bidang Pekerjaan
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bolt_rounded,
                size: 15,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  keahlian,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Card Putih Statistik Aktivitas Petugas (Total Tugas & Bulan Dinas)
          _buildStatsBar(
            totalTugas: totalTugas,
            bulanDinas: bulanDinas,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar({
    required String totalTugas,
    required String bulanDinas,
  }) {
    final stats = [
      (
        value: totalTugas,
        label: 'Total Tugas',
        highlight: true,
      ),
      (
        value: bulanDinas,
        label: 'Bulan Dinas',
        highlight: false,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(stats.length * 2 - 1, (index) {
            if (index.isOdd) {
              return VerticalDivider(
                width: 1,
                thickness: 1,
                indent: 4,
                endIndent: 4,
                color: AppColors.border.withValues(alpha: 0.6),
              );
            }
            final item = stats[index ~/ 2];
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: item.highlight
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.border,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    String? label,
    String? value,
    String? titlePrimary,
    String? subtitleSecondary,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: titlePrimary != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titlePrimary,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitleSecondary != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitleSecondary,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label ?? '',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      child: content,
    );
  }

  Widget _buildDeviceInfoCard() {
    final statusLabel = _isSynced ? 'Tersinkron' : 'Lokal';
    final statusColor =
        _isSynced ? AppColors.statusCompleted : AppColors.statusProcessing;
    final statusBg =
        _isSynced ? AppColors.statusCompletedBg : AppColors.statusProcessingBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecor.card(radius: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.devices_rounded,
              size: 19,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perangkat Pelaksana JEKI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatSyncTime(),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
