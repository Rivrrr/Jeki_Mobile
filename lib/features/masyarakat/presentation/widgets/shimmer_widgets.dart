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

class LaporanDetailSkeleton extends StatelessWidget {
  const LaporanDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerWidget(height: 60, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          const ShimmerWidget(height: 24),
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                ShimmerWidget(width: 160, height: 160, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 10),
                ShimmerWidget(width: 160, height: 160, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
              children: List.generate(5, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ShimmerWidget(width: 18, height: 18, shapeBorder: const CircleBorder()),
                    const SizedBox(width: 8),
                    ShimmerWidget(width: 70, height: 12),
                    const SizedBox(width: 8),
                    ShimmerWidget(width: 100, height: 12),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}
