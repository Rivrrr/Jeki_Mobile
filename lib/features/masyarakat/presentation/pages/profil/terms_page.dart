import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Syarat & Ketentuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              'Ketentuan Penggunaan Layanan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildSection(
              '1. Penggunaan Akun',
              'Setiap pengguna wajib memberikan informasi yang benar dan akurat saat mendaftar. Penyalahgunaan akun dapat mengakibatkan pemblokiran akses.',
            ),
            _buildSection(
              '2. Pelaporan',
              'Laporan yang dikirimkan harus berdasarkan fakta yang sebenarnya. Pengiriman laporan palsu atau fitnah adalah pelanggaran hukum.',
            ),
            _buildSection(
              '3. Etika Komunikasi',
              'Pengguna diharapkan berkomunikasi dengan sopan kepada petugas dalam setiap interaksi yang terjadi melalui aplikasi.',
            ),
            _buildSection(
              '4. Batasan Tanggung Jawab',
              'Kami berupaya memberikan respon tercepat, namun kami tidak bertanggung jawab atas keterlambatan akibat kendala teknis atau kondisi darurat di lapangan.',
            ),
            _buildSection(
              '5. Perubahan Ketentuan',
              'Syarat dan ketentuan ini dapat berubah sewaktu-waktu sesuai dengan kebijakan pengelola layanan.',
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
