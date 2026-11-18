import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/masyarakat/presentation/widgets/info_highlight_card.dart';

/// Halaman panduan langkah demi langkah untuk membuat laporan kerusakan
/// infrastruktur melalui aplikasi.
///
/// Konten disusun mengikuti alur nyata di aplikasi: pilih kategori, ambil foto,
/// tandai lokasi, tentukan prioritas, lalu kirim dan pantau statusnya.
class PanduanMelaporPage extends StatelessWidget {
  const PanduanMelaporPage({super.key});

  static const List<_PanduanStep> _steps = [
    _PanduanStep(
      icon: Icons.add_location_alt_outlined,
      title: 'Mulai Laporan Baru',
      description:
          'Buka halaman utama lalu tekan tombol buat laporan. Pastikan Anda sudah masuk '
          'dengan akun masyarakat agar laporan tercatat atas nama Anda.',
    ),
    _PanduanStep(
      icon: Icons.category_outlined,
      title: 'Pilih Kategori Kerusakan',
      description:
          'Tentukan kategori yang paling sesuai: jalan berlubang, jembatan rusak, '
          'saluran drainase, penerangan jalan, trotoar, atau tebing dan tanggul longsor.',
    ),
    _PanduanStep(
      icon: Icons.photo_camera_outlined,
      title: 'Ambil Foto Kondisi',
      description:
          'Foto kondisi kerusakan secara jelas dari beberapa sudut bila memungkinkan. '
          'Foto yang terang dan dekat dengan objek mempercepat verifikasi petugas.',
    ),
    _PanduanStep(
      icon: Icons.map_outlined,
      title: 'Tandai Lokasi',
      description:
          'Aktifkan GPS lalu geser peta agar pin tepat pada titik kerusakan. '
          'Sertakan patokan seperti nama jalan atau bangunan terdekat pada kolom alamat.',
    ),
    _PanduanStep(
      icon: Icons.edit_note_outlined,
      title: 'Tulis Judul & Deskripsi',
      description:
          'Tulis judul singkat dan deskripsi yang menjelaskan ukuran, dampak, dan '
          'sejak kapan kerusakan terjadi. Hindari kata-kata yang menyinggung pihak lain.',
    ),
    _PanduanStep(
      icon: Icons.send_outlined,
      title: 'Kirim & Pantau Status',
      description:
          'Setelah laporan dikirim, pantau perkembangan pada menu Riwayat Laporan. '
          'Anda akan menerima notifikasi setiap kali status laporan berubah.',
    ),
  ];

  static const List<String> _tips = [
    'Pastikan lokasi laporan berada di wilayah layanan yang didukung.',
    'Satu laporan untuk satu titik kerusakan agar penanganan lebih tepat.',
    'Gunakan foto asli, bukan tangkapan layar atau foto dari internet.',
    'Jangan mengirim data pribadi orang lain tanpa izin.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Panduan Melapor',
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
                    'Langkah Melapor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._steps.asMap().entries.map(
                    (entry) => _buildStep(entry.key + 1, entry.value),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tips Agar Laporan Cepat Ditindaklanjuti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTipsCard(),
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
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Laporkan Kerusakan Infrastruktur\ndalam 6 Langkah',
            style: TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Panduan singkat agar laporan Anda mudah diverifikasi dan segera ditangani petugas lapangan.',
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

  Widget _buildStep(int number, _PanduanStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                number.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          step.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: AppColors.textSecondary,
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

  Widget _buildTipsCard() {
    return InfoHighlightCard(
      icon: Icons.menu_book_outlined,
      title: 'Catatan Penting',
      lines: _tips,
    );
  }
}

class _PanduanStep {
  final IconData icon;
  final String title;
  final String description;

  const _PanduanStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
