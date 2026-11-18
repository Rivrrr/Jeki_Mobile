import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pusat Bantuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              'Pertanyaan Umum (FAQ)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildFAQ('Bagaimana cara mengirim laporan?', 'Klik tombol buat laporan di halaman utama, isi formulir, unggah foto, dan kirim.'),
            _buildFAQ('Berapa lama laporan saya diproses?', 'Waktu pemrosesan tergantung pada kompleksitas laporan dan ketersediaan petugas di lapangan.'),
            _buildFAQ('Apakah laporan saya bersifat anonim?', 'Laporan Anda tercatat di sistem kami, namun identitas Anda hanya akan diketahui oleh petugas yang menangani laporan tersebut.'),
            _buildFAQ('Bagaimana jika saya ingin membatalkan laporan?', 'Saat ini pembatalan laporan harus dilakukan melalui admin pusat bantuan.'),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Masih butuh bantuan?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Implement WhatsApp or Email link
                },
                icon: const Icon(Icons.contact_support, color: AppColors.primary),
                label: const Text('Hubungi Admin via WhatsApp', style: TextStyle(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(answer, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.justify),
        ],
      ),
    );
  }
}
