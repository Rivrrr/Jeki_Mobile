import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kebijakan Privasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bagaimana Kami Mengelola Data Anda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Data yang Kami Kumpulkan',
              'Kami mengumpulkan informasi dasar seperti nama, email, nomor telepon, dan alamat untuk keperluan verifikasi laporan dan komunikasi resmi.',
            ),
            _buildSection(
              'Penggunaan Data',
              'Data Anda digunakan untuk memastikan laporan yang dikirimkan valid dan memudahkan petugas untuk menghubungi Anda jika diperlukan informasi tambahan.',
            ),
            _buildSection(
              'Keamanan Data',
              'Kami berkomitmen untuk menjaga kerahasiaan data Anda dan tidak akan membagikannya kepada pihak ketiga tanpa izin, kecuali untuk keperluan hukum.',
            ),
            _buildSection(
              'Hak Anda',
              'Anda berhak memperbarui informasi pribadi Anda melalui menu profil atau meminta penghapusan akun melalui pusat bantuan.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.justify),
        ],
      ),
    );
  }
}
