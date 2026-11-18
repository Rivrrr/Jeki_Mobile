import 'package:flutter/material.dart';
import 'package:infrast/core/constants/api_constants.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/storage_service.dart';
import 'package:infrast/features/auth/data/auth_service.dart';
import 'package:infrast/features/auth/presentation/screens/login_screen.dart';
import 'package:infrast/features/masyarakat/data/laporan_service.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/edit_profile_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/security_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/notification_settings_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/panduan_melapor_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/hubungi_kami_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Map<String, dynamic>? _userData;
  Map<String, int> _stats = {'total': 0, 'process': 0, 'done': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    await Future.wait([_loadUser(), _loadStats()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadUser() async {
    final localUser = await StorageService.getUser();
    if (mounted && localUser != null) {
      setState(() => _userData = localUser);
    }
    try {
      final syncedUser = await AuthService.syncUser();
      if (mounted && syncedUser != null) {
        setState(() => _userData = syncedUser);
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    final result = await LaporanService.fetchMyLaporan();
    if (result['success'] == true) {
      final raw =
          result['data'] is Map && (result['data'] as Map).containsKey('data')
          ? result['data']['data']
          : result['data'];
      final reports = (raw is List)
          ? List<Map<String, dynamic>>.from(raw)
          : <Map<String, dynamic>>[];

      int total = reports.length;
      int done = reports
          .where(
            (r) => r['status'] == 'selesai' || r['status'] == 'dikonfirmasi',
          )
          .length;
      int process = total - done;

      if (mounted) {
        setState(
          () => _stats = {'total': total, 'process': process, 'done': done},
        );
      }
    }
  }

  /// Bentuk URL foto profil absolut dari data user.
  ///
  /// Server mengirim `foto_profil_url` absolut, tetapi bila hanya path relatif
  /// (`profil/xxx.jpg`) URL digabung dengan base aktif agar tetap termuat
  /// walau `APP_URL` backend berubah.
  String? _resolvePhotoUrl(Map<String, dynamic>? user) {
    if (user == null) return null;
    final full = user['foto_profil_url']?.toString();
    if (full != null && full.startsWith('http')) return full;
    final path = user['foto_profil']?.toString() ?? '';
    if (path.isEmpty) return null;
    final base = ApiConstants.baseUrl;
    return '$base/media/${path.startsWith('/') ? path.substring(1) : path}';
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    if (updated == true) {
      await _loadAllData();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        _userData?['name'] ??
        _userData?['email']?.toString().split('@')[0] ??
        'Pengguna';
    final userEmail = _userData?['email'] ?? 'Email tidak ditemukan';
    final userPhone = _userData?['no_hp']?.toString() ?? '';
    final userPhoto = _resolvePhotoUrl(_userData);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(
                      userName.toString(),
                      userEmail.toString(),
                      userPhone,
                      userPhoto,
                    ),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 24,
                            bottom: 120,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatsSection(),
                              const SizedBox(height: 28),
                              _buildMenuSection('Akun', [
                                _buildMenuItem(
                                  icon: Icons.person_outline,
                                  title: 'Edit Profil',
                                  subtitle: 'Ubah nama, kontak, dan informasi pribadi',
                                  onTap: _openEditProfile,
                                ),
                                _buildMenuItem(
                                  icon: Icons.lock_outline,
                                  title: 'Keamanan',
                                  subtitle: 'Ubah kata sandi akun Anda',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SecurityPage(),
                                    ),
                                  ),
                                ),
                                _buildMenuItem(
                                  icon: Icons.notifications_none_rounded,
                                  title: 'Notifikasi',
                                  subtitle:
                                      'Izin akses, bunyi, dan jenis notifikasi',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationSettingsPage(),
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 24),
                              _buildMenuSection('Bantuan', [
                                _buildMenuItem(
                                  icon: Icons.menu_book_outlined,
                                  title: 'Panduan Melapor',
                                  subtitle: 'Langkah membuat laporan yang baik',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PanduanMelaporPage(),
                                    ),
                                  ),
                                ),
                                _buildMenuItem(
                                  icon: Icons.support_agent_outlined,
                                  title: 'Hubungi Kami',
                                  subtitle: 'Kanal bantuan resmi pengaduan',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HubungiKamiPage(),
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 32),
                              _buildLogoutButton(),
                              const SizedBox(height: 18),
                              Center(
                                child: Text(
                                  'Jeki · Versi 1.0.0',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textMuted.withValues(
                                      alpha: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Header profil.
  ///
  /// Tinggi tidak dipatok: konten di dalam [IntrinsicHeight]-style Column dengan
  /// padding bawah 28 px, sehingga nama/email/No HP tidak pernah tertimpa
  /// container dekorasi dan aman di layar kecil maupun saat teks dibesarkan.
  Widget _buildHeader(
    String name,
    String email,
    String phone,
    String? photoUrl,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topInset = MediaQuery.of(context).padding.top;

    // Skala avatar mengikuti lebar layar (bukan hardcode) agar pas di semua device.
    final avatarRadius = (screenWidth * 0.115).clamp(34.0, 52.0).toDouble();
    final nameSize = screenWidth < 360 ? 18.0 : 20.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            // Tekstur statis berlapis — dibatasi ke area latar saja lewat
            // Positioned.fill + ClipRect, jadi tidak menimpa konten teks.
            Positioned.fill(
              child: ClipRect(
                child: Stack(
                  children: [
                    Positioned(
                      top: -60,
                      right: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 40,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Konten: mengalir normal (bukan Positioned bertinggi tetap)
            // sehingga tinggi header selalu = tinggi kontennya. Column dibuat
            // stretch agar tiap baris mengisi lebar header penuh, jadi teks
            // center-nya tepat di sumbu tengah layar (bukan center dari kolom
            // sempit yang bisa bergeser karena avatar/pill lebih lebar).
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, topInset + 24, 16, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _buildHeaderAvatar(name, photoUrl, avatarRadius),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: nameSize,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      // No HP dibatasi lebar maksimum & di-center, tidak lagi
                      // melebar/tumpang tindih dengan nama atau email.
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone_android,
                                size: 13,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar(String name, String? photoUrl, double radius) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final fallback = Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );

    Widget inner;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      inner = Image.network(
        photoUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      );
    } else {
      inner = fallback;
    }

    return Container(
      width: radius * 2 + 8,
      height: radius * 2 + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(child: SizedBox.expand(child: inner)),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              _stats['total']!,
              Icons.assignment_outlined,
              AppColors.primary,
            ),
          ),
          _buildStatDivider(),
          Expanded(
            child: _buildStatItem(
              'Proses',
              _stats['process']!,
              Icons.sync_alt_outlined,
              AppColors.statusProcessing,
            ),
          ),
          _buildStatDivider(),
          Expanded(
            child: _buildStatItem(
              'Selesai',
              _stats['done']!,
              Icons.check_circle_outline,
              AppColors.statusCompleted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border.withValues(alpha: 0.7),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                items[i],
                if (i != items.length - 1)
                  const Divider(
                    height: 1,
                    indent: 64,
                    endIndent: 16,
                    color: AppColors.border,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            color: AppColors.error,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
