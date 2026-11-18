import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/notification_service.dart';
import 'package:infrast/core/services/notification_settings_service.dart';

/// Halaman pengaturan notifikasi masyarakat.
///
/// Terdiri dari tiga bagian:
/// 1. Izin akses notifikasi (status sistem + tombol minta izin / buka pengaturan)
/// 2. Preferensi notifikasi (master switch, bunyi, getaran)
/// 3. Jenis notifikasi yang diterima
///
/// Semua preferensi disimpan lokal lewat [NotificationSettingsService].
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _loading = true;
  bool _permissionGranted = false;

  bool _enabled = true;
  bool _sound = true;
  bool _vibration = true;
  bool _laporanUpdate = true;
  bool _pengumuman = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await NotificationSettingsService.getAll();
    final permission = await NotificationService.getPermissionStatus();
    if (!mounted) return;
    setState(() {
      _enabled = settings[NotificationSettingsService.keyEnabled] ?? true;
      _sound = settings[NotificationSettingsService.keySound] ?? true;
      _vibration = settings[NotificationSettingsService.keyVibration] ?? true;
      _laporanUpdate =
          settings[NotificationSettingsService.keyLaporanUpdate] ?? true;
      _pengumuman = settings[NotificationSettingsService.keyPengumuman] ?? true;
      _permissionGranted = permission;
      _loading = false;
    });
    // Status izin bisa berubah di luar aplikasi (mis. dari pengaturan Android),
    // jadi perbarui saat halaman kembali difokuskan.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final latest = await NotificationService.getPermissionStatus();
      if (mounted && latest != _permissionGranted) {
        setState(() => _permissionGranted = latest);
      }
    });
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.requestPermission();
    if (!mounted) return;
    setState(() => _permissionGranted = granted);
    _showSnack(
      granted ? 'Izin notifikasi berhasil diberikan' : 'Izin notifikasi belum diberikan. Anda dapat mengaktifkannya di pengaturan perangkat.',
      isError: !granted,
    );
  }

  Future<void> _updatePreference(Future<void> Function() save) async {
    await save();
    if (!mounted) return;
    _showSnack('Preferensi notifikasi disimpan');
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPermissionCard(),
                  const SizedBox(height: 24),
                  _sectionTitle('Preferensi Notifikasi'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Aktifkan Notifikasi',
                      subtitle: 'Terima semua pemberitahuan dari aplikasi',
                      value: _enabled,
                      onChanged: (value) async {
                        setState(() => _enabled = value);
                        await _updatePreference(
                          () => NotificationSettingsService.setEnabled(value),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Bunyi Notifikasi',
                      subtitle: 'Mainkan suara saat notifikasi masuk',
                      value: _enabled && _sound,
                      onChanged: _enabled
                          ? (value) async {
                              setState(() => _sound = value);
                              await _updatePreference(
                                () =>
                                    NotificationSettingsService.setSound(value),
                              );
                            }
                          : null,
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchTile(
                      icon: Icons.vibration,
                      title: 'Getaran',
                      subtitle: 'Getarkan perangkat saat notifikasi masuk',
                      value: _enabled && _vibration,
                      onChanged: _enabled
                          ? (value) async {
                              setState(() => _vibration = value);
                              await _updatePreference(
                                () => NotificationSettingsService.setVibration(
                                  value,
                                ),
                              );
                            }
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _sectionTitle('Jenis Notifikasi'),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'Update Status Laporan',
                      subtitle: 'Info saat laporan diverifikasi, dikerjakan, atau selesai',
                      value: _enabled && _laporanUpdate,
                      onChanged: _enabled
                          ? (value) async {
                              setState(() => _laporanUpdate = value);
                              await _updatePreference(
                                () =>
                                    NotificationSettingsService.setLaporanUpdate(
                                      value,
                                    ),
                              );
                            }
                          : null,
                    ),
                    const Divider(height: 1, indent: 60),
                    _buildSwitchTile(
                      icon: Icons.campaign_outlined,
                      title: 'Pengumuman',
                      subtitle: 'Informasi layanan dan pemberitahuan penting',
                      value: _enabled && _pengumuman,
                      onChanged: _enabled
                          ? (value) async {
                              setState(() => _pengumuman = value);
                              await _updatePreference(
                                () => NotificationSettingsService.setPengumuman(
                                  value,
                                ),
                              );
                            }
                          : null,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentPink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Notifikasi penting terkait keamanan akun tetap dikirim meskipun Anda mematikan notifikasi.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.textSecondary.withValues(
                                alpha: 1,
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

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _permissionGranted ? AppColors.primaryGradient : null,
        color: _permissionGranted ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _permissionGranted ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _permissionGranted
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.accentPink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _permissionGranted
                  ? Icons.notifications_active
                  : Icons.notifications_off_outlined,
              color: _permissionGranted ? Colors.white : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _permissionGranted
                      ? 'Notifikasi Aktif'
                      : 'Izin Notifikasi Belum Aktif',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _permissionGranted
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _permissionGranted
                      ? 'Anda akan menerima pemberitahuan status laporan.'
                      : 'Izinkan akses agar Anda tidak melewatkan update laporan.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: _permissionGranted
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                  ),
                ),
                if (!_permissionGranted) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _requestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Izinkan Akses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final disabled = onChanged == null;
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: disabled ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.primary.withValues(alpha: disabled ? 0.4 : 1),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: disabled ? AppColors.textMuted : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
