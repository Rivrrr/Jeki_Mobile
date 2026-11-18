import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder? shapeBorder;

  const ShimmerWidget({
    super.key,
    this.width = double.infinity,
    this.height = 20.0,
    this.shapeBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: shapeBorder ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

/// Skeleton layar Detail Laporan.
///
/// Harus scrollable dan tidak memakai lebar tetap: sebelumnya `Column` polos
/// tanpa scroll + `Row` berisi dua kotak 160 px membuat overflow sesaat
/// (badge "OVERFLOWED") sebelum data asli datang, terutama di layar sempit.
class LaporanDetailSkeleton extends StatelessWidget {
  const LaporanDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Ukuran thumbnail mengikuti lebar layar agar dua kotak + gap selalu muat.
    final thumb = ((width - 32 - 10) / 2 - 24).clamp(96.0, 140.0).toDouble();

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerWidget(
              height: 60,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            const ShimmerWidget(height: 24),
            const SizedBox(height: 10),
            SizedBox(
              height: thumb,
              child: Row(
                children: [
                  ShimmerWidget(
                    width: thumb,
                    height: thumb,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ShimmerWidget(
                    width: thumb,
                    height: thumb,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const ShimmerWidget(height: 24),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: const [
                        ShimmerWidget(width: 18, height: 18, shapeBorder: CircleBorder()),
                        SizedBox(width: 8),
                        Flexible(child: ShimmerWidget(width: 70, height: 12)),
                        SizedBox(width: 8),
                        Flexible(child: ShimmerWidget(width: 100, height: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
