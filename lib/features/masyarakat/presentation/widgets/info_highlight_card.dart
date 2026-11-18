import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// Kartu penjelas yang tampilannya sama dengan kartu "Notifikasi Aktif" di
/// halaman Pengaturan Notifikasi: latar gradient primary, sudut 20, ikon di
/// dalam tile putih transparan, judul tebal putih, dan isi teks putih lembut.
///
/// Dipakai bersama oleh halaman Keamanan, Panduan Melapor, dan Hubungi Kami
/// supaya tidak ada lagi perbedaan warna/border antar halaman.
class InfoHighlightCard extends StatelessWidget {
  const InfoHighlightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;

  /// Satu entri per baris isi. Bila hanya satu entri, entri itu ditampilkan
  /// sebagai paragraf biasa tanpa bullet.
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final isParagraph = lines.length == 1;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (isParagraph)
                  Text(
                    lines.first,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  )
                else
                  ...lines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\u2022',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
