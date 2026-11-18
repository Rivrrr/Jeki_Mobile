import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/masyarakat/presentation/widgets/info_highlight_card.dart';

/// Halaman bantuan kontak untuk masyarakat.
///
/// Menampilkan kanal resmi (WhatsApp, telepon, email) beserta jam layanan.
/// Nomor dan alamat dapat disesuaikan pada konstanta di bawah.
class HubungiKamiPage extends StatelessWidget {
  const HubungiKamiPage({super.key});

  // ─── Data kanal kontak ────────────────────────────────────────────────────
  static const String _whatsappDisplay = '+62 812-3456-7890';
  static const String _phoneDisplay = '(021) 1234-5678';
  static const String _email = 'pengaduan@jeki.go.id';
  static const String _address =
      'Jl. Contoh Raya No. 1, Kantor Dinas Pekerjaan Umum, Jakarta';
  static const String _operationalHours = 'Senin – Jumat, 08.00 – 16.00 WIB';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Hubungi Kami',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kanal Resmi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactTile(
                    context,
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFF25D366),
                    title: 'WhatsApp Pengaduan',
                    subtitle: _whatsappDisplay,
                    note: 'Balasan pada jam layanan',
                    copyValue: _whatsappDisplay,
                    onTap: () =>
                        _copy(context, _whatsappDisplay, 'Nomor WhatsApp'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactTile(
                    context,
                    icon: Icons.call_outlined,
                    iconColor: AppColors.primary,
                    title: 'Telepon Kantor',
                    subtitle: _phoneDisplay,
                    note: _operationalHours,
                    copyValue: _phoneDisplay,
                    onTap: () => _copy(context, _phoneDisplay, 'Nomor telepon'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactTile(
                    context,
                    icon: Icons.mail_outline,
                    iconColor: AppColors.statusVerification,
                    title: 'Email Pengaduan',
                    subtitle: _email,
                    note: 'Sertakan nomor laporan pada subjek',
                    copyValue: _email,
                    onTap: () => _copy(context, _email, 'Alamat email'),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Kunjungi Kantor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOfficeCard(context),
                  const SizedBox(height: 24),
                  _buildReminderCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ada pertanyaan atau kendala?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tim pengaduan siap membantu Anda melalui kanal resmi berikut.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String note,
    required String copyValue,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfficeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _address,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _operationalHours,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _copy(context, _address, 'Alamat kantor'),
              icon: const Icon(
                Icons.copy_all_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text(
                'Salin Alamat',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return InfoHighlightCard(
      icon: Icons.edit_note_rounded,
      title: 'Penting Diketahui',
      lines: const [
        'Untuk laporan kerusakan, gunakan fitur Buat Laporan di aplikasi agar '
            'laporan otomatis tercatat dan dapat dipantau statusnya.',
      ],
    );
  }

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin ke papan klip'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
