import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infrast/core/constants/app_sizes.dart';

void main() {
  testWidgets('AppSizes scales dimensions responsively for mobile devices', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(360, 800)),
        child: Builder(
          builder: (context) {
            final width = AppSizes.responsiveWidth(context, 100);
            final height = AppSizes.responsiveHeight(context, 200);
            final padding = AppSizes.responsiveSpacing(context, 24);

            expect(width, closeTo(92.31, 0.01));
            expect(height, closeTo(189.57, 0.01));
            expect(padding, closeTo(22.15, 0.01));
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
