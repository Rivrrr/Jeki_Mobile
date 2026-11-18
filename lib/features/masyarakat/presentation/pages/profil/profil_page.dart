import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/storage_service.dart';
import 'package:infrast/features/auth/data/auth_service.dart';
import 'package:infrast/features/auth/presentation/screens/login_screen.dart';
import 'package:infrast/features/masyarakat/data/laporan_service.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/security_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/privacy_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/help_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/terms_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/profil/suggestion_page.dart';


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
    await Future.wait([
      _loadUser(),
      _loadStats(),
    ]);
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
      final raw = result['data'] is Map && (result['data'] as Map).containsKey('data') 
          ? result['data']['data'] 
          : result['data'];
      final reports = (raw is List) ? List<Map<String, dynamic>>.from(raw) : <Map<String, dynamic>>[];
      
      int total = reports.length;
      int done = reports.where((r) => r['status'] == 'selesai' || r['status'] == 'dikonfirmasi').length;
      int process = total - done;
      
      if (mounted) {
        setState(() => _stats = {'total': total, 'process': process, 'done': done});
      }
    }
  }

  void _showEditProfileDialog() {
    final currentName = _userData?['name']?.toString() ?? '';
    final currentPhone = _userData?['no_hp']?.toString() ?? '';
    final currentAddress = _userData?['address']?.toString() ?? '';
    final currentGender = _userData?['gender']?.toString() ?? 'Laki-laki';
    final currentBirthDate = _userData?['birth_date']?.toString() ?? '';

    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final addressController = TextEditingController(text: currentAddress);
    
    String selectedGender = currentGender;
    DateTime? selectedDate = currentBirthDate.isNotEmpty 
        ? DateTime.tryParse(currentBirthDate) 
        : null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Informasi Pribadi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Nama Lengkap
                    _buildLabel('Nama Lengkap'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap Anda',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nomor HP
                    _buildLabel('Nomor HP'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Contoh: 08123456789',
                        prefixIcon: const Icon(Icons.phone_android),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Alamat
                    _buildLabel('Alamat Lengkap'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Masukkan alamat tempat tinggal',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Jenis Kelamin
                    _buildLabel('Jenis Kelamin'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                        DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedGender = val!),
                    ),
                    const SizedBox(height: 16),

                    // Tanggal Lahir
                    _buildLabel('Tanggal Lahir'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              selectedDate == null 
                                  ? 'Pilih Tanggal Lahir' 
                                  : DateFormat('dd MMMM yyyy').format(selectedDate!),
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final newName = nameController.text.trim();
                                if (newName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nama tidak boleh kosong')),
                                  );
                                  return;
                                }

                                setDialogState(() => isSaving = true);
                                
                                final res = await AuthService.updateProfile(
                                  name: newName,
                                  phone: phoneController.text.trim(),
                                  address: addressController.text.trim(),
                                  gender: selectedGender,
                                  birthDate: selectedDate != null 
                                      ? DateFormat('yyyy-MM-dd').format(selectedDate!) 
                                      : null,
                                );
                                
                                if (!ctx.mounted) return;

                                Navigator.pop(ctx);
                                if (res['success'] == true) {
                                  await _loadAllData();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? 'Informasi pribadi berhasil diperbarui'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? 'Gagal memperbarui data'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                                setDialogState(() => isSaving = false);
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
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
            child: const Text('Keluar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName  = _userData?['name']  ?? _userData?['email']?.toString().split('@')[0] ?? 'Pengguna';
    final userEmail = _userData?['email'] ?? 'Email tidak ditemukan';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(userName, userEmail),
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsSection(),
                          const SizedBox(height: 32),
                          _buildMenuSection(
                            'Akun & Pengaturan', 
                            [
                              _buildMenuItem(
                                icon: Icons.person_outline, 
                                title: 'Edit Profil', 
                                subtitle: 'Ubah nama dan informasi pribadi', 
                                onTap: _showEditProfileDialog
                              ),
                              _buildMenuItem(
                                icon: Icons.lock_outline, 
                                title: 'Keamanan', 
                                subtitle: 'Ubah kata sandi dan verifikasi', 
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityPage()))
                              ),
                              _buildMenuItem(
                                icon: Icons.privacy_tip_outlined, 
                                title: 'Privasi', 
                                subtitle: 'Kelola data dan privasi akun', 
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPage()))
                              ),
                            ]
                          ),
                          const SizedBox(height: 24),
                          _buildMenuSection(
                            'Bantuan & Dukungan', 
                            [
                              _buildMenuItem(
                                icon: Icons.help_outline, 
                                title: 'Pusat Bantuan', 
                                subtitle: 'Panduan penggunaan aplikasi', 
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()))
                              ),
                              _buildMenuItem(
                                icon: Icons.description_outlined, 
                                title: 'Syarat & Ketentuan', 
                                subtitle: 'Aturan penggunaan layanan', 
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage()))
                              ),
                              _buildMenuItem(
                                icon: Icons.message_outlined, 
                                title: 'Kirim Saran', 
                                subtitle: 'Bantu kami menjadi lebih baik', 
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuggestionPage()))
                              ),
                            ]
                          ),
                          const SizedBox(height: 40),
                          _buildLogoutButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 40,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Total', _stats['total']!, Icons.assignment_outlined)),
          Expanded(child: _buildStatItem('Proses', _stats['process']!, Icons.sync_alt_outlined)),
          Expanded(child: _buildStatItem('Selesai', _stats['done']!, Icons.check_circle_outline)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              fontSize: 15,
              fontWeight: FontWeight.bold,
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
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text(
          'Keluar dari Akun',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
