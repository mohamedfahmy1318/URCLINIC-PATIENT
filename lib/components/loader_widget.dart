import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'shimmer_widget.dart';

class LoaderWidget extends StatelessWidget {
  final bool isBlurBackground;
  final Color? loaderColor;

  const LoaderWidget({super.key, this.loaderColor, this.isBlurBackground = false});

  @override
  Widget build(BuildContext context) {
    if (isBlurBackground) {
      return AbsorbPointer(
        child: Container(
          color: Colors.white.withValues(alpha: 0.85),
          child: const ShimmerLoader(),
        ),
      );
    }
    return const ShimmerLoader();
  }
}

class ThreeBounceLoadingWidget extends StatelessWidget {
  const ThreeBounceLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (_) => Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
