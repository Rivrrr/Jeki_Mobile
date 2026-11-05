import 'package:flutter/material.dart';
import 'package:infrast/core/utils/foto_helper.dart';

class StepFoto extends StatelessWidget {
  final List<PhotoItem> photos; // list of PhotoItem (in-memory bytes dengan watermark)
  final VoidCallback onAddPhoto;
  final Function(int) onRemovePhoto;
  final TextEditingController deskripsiController;
  final double? latitude;
  final double? longitude;
  final String? coordinateLabel;

  const StepFoto({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.deskripsiController,
    this.latitude,
    this.longitude,
    this.coordinateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMinPhotoMet = photos.length >= 3;
    final int remainingPhotos = 3 - photos.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
              children: [
                TextSpan(text: 'Wajib mengambil '),
                TextSpan(
                  text: 'minimal 3 foto',
                  style: TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' bukti kerusakan langsung dengan kamera di lokasi (Watermark otomatis GPS & WIB).'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GPS Status Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location, color: Color(0xFF16A34A), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Watermark Otomatis Aktif — GPS & Waktu WIB',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        latitude != null && longitude != null
                            ? '📍 Terkunci: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)} (${coordinateLabel ?? "Kab. Jember"})'
                            : 'Koordinat GPS dan waktu WIB otomatis terstempel permanen pada setiap foto.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Direct Camera Capture Button (Hanya Kamera Langsung, Galeri Ditiadakan)
          if (photos.length < 5)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isMinPhotoMet
                      ? const Color(0xFF16A34A).withOpacity(0.3)
                      : const Color(0xFFE91E63).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onAddPhoto,
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isMinPhotoMet
                                  ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
                                  : [const Color(0xFFE91E63), const Color(0xFFFF4081)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isMinPhotoMet ? const Color(0xFF16A34A) : const Color(0xFFE91E63))
                                    .withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          photos.isEmpty
                              ? 'Buka Kamera & Ambil Foto 1'
                              : 'Buka Kamera (Foto ke-${photos.length + 1})',
                          style: TextStyle(
                            color: isMinPhotoMet ? const Color(0xFF16A34A) : const Color(0xFFE91E63),
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMinPhotoMet ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isMinPhotoMet ? const Color(0xFFBBF7D0) : const Color(0xFFFECDD3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isMinPhotoMet ? Icons.check_circle_rounded : Icons.photo_camera_rounded,
                          color: isMinPhotoMet ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isMinPhotoMet
                                ? 'Syarat minimal 3 foto terpenuhi (${photos.length}/5 foto)'
                                : 'Wajib memfoto langsung di lokasi (Kurang $remainingPhotos foto lagi)',
                            style: TextStyle(
                              color: isMinPhotoMet ? const Color(0xFF15803D) : const Color(0xFFBE123C),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Foto wajib diambil langsung menggunakan kamera di lokasi. Pilihan dari galeri tidak diperbolehkan demi keaslian laporan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

          if (photos.isNotEmpty) ...[
            const SizedBox(height: 20),

            // Photos List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Foto Bukti Lapangan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMinPhotoMet ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMinPhotoMet ? const Color(0xFFBBF7D0) : const Color(0xFFFECDD3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMinPhotoMet ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 13,
                        color: isMinPhotoMet ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMinPhotoMet
                            ? '${photos.length}/5 (Min. 3 Terpenuhi ✓)'
                            : '${photos.length}/3 Foto (Kurang $remainingPhotos lagi)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isMinPhotoMet ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Photo thumbnails dengan preview watermark
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < photos.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                photos[i].bytes,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Center(
                                  child: Icon(Icons.broken_image, color: Color(0xFFCBD5E1)),
                                ),
                              ),
                            ),
                          ),
                          // Tombol Hapus Foto
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onRemovePhoto(i),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                          // Badge Watermark Terpasang
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, color: Colors.white, size: 9),
                                  SizedBox(width: 2),
                                  Text(
                                    'WIB ✓',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Label Foto dan Koordinat
                          Positioned(
                            bottom: 6,
                            left: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Foto ${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (latitude != null && longitude != null)
                                    Text(
                                      '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF86EFAC),
                                        fontSize: 8,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Add more placeholder button jika belum mencapai 5 foto
                  if (photos.length < 5)
                    GestureDetector(
                      onTap: onAddPhoto,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, color: Color(0xFFE91E63), size: 28),
                            const SizedBox(height: 4),
                            Text(
                              'Foto ke-${photos.length + 1}',
                              style: const TextStyle(
                                color: Color(0xFFE91E63),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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

          // ── Deskripsi Kondisi (Digabungkan ke Slide 3) ──────────────
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFE2E8F0), height: 1),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Deskripsi Kondisi Kerusakan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: deskripsiController,
                builder: (context, value, child) {
                  return Text(
                    '${value.text.length}/500',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: deskripsiController,
            maxLines: 4,
            maxLength: 500,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              hintText: 'Jelaskan kondisi kerusakan yang Anda temukan secara rinci (misal: kedalaman lubang, dampaknya bagi pengendara, dll)...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE91E63)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Ketentuan Validasi Lapangan Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gavel_rounded, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Ketentuan Validasi Lapangan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Wajib mengambil minimal 3 foto bukti kerusakan langsung di lokasi kejadian. Pilihan dari galeri tidak diperbolehkan. Sistem otomatis menyematkan koordinat lokasi dan waktu WIB di foto.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB45309),
                          height: 1.4,
                        ),
                      ),
                    ],
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
