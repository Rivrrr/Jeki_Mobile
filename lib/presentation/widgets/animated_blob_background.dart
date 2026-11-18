import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated floating translucent blobs background widget matching the Figma design.
/// Creates a smooth, gentle floating orb effect that seamlessly loops.
class AnimatedBlobBackground extends StatefulWidget {
  final Widget? child;
  const AnimatedBlobBackground({super.key, this.child});

  @override
  State<AnimatedBlobBackground> createState() => _AnimatedBlobBackgroundState();
}

class _AnimatedBlobBackgroundState extends State<AnimatedBlobBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final t1 = progress * 2 * math.pi;
        final t2 = (progress + 0.33) * 2 * math.pi;
        final t3 = (progress + 0.66) * 2 * math.pi;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Blob 1: Top-Left Large Orb
            Positioned(
              top: -30 + math.sin(t1) * 14,
              left: -30 + math.cos(t1) * 12,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Blob 2: Top-Right Large Orb
            Positioned(
              top: -25 + math.cos(t2) * 16,
              right: -30 + math.sin(t2) * 14,
              child: IgnorePointer(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Blob 3: Center-Right Floating Bubble
            Positioned(
              top: 55 + math.sin(t3) * 12,
              right: 28 + math.cos(t3) * 10,
              child: IgnorePointer(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),

            // Blob 4: Center-Left Floating Bubble
            Positioned(
              top: 75 + math.cos(t1) * 10,
              left: 20 + math.sin(t1) * 12,
              child: IgnorePointer(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.13),
                  ),
                ),
              ),
            ),

            // Blob 5: Near Bottom Curve Bubble
            Positioned(
              bottom: 40 + math.sin(t2) * 9,
              right: 65 + math.cos(t2) * 10,
              child: IgnorePointer(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),

            // Blob 6: Subtle Accent Bubble
            Positioned(
              top: 32 + math.cos(t3) * 8,
              left: 110 + math.sin(t3) * 8,
              child: IgnorePointer(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),

            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}
