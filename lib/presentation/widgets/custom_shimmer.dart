import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_colors.dart';

class CustomShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder? shapeBorder;

  const CustomShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shapeBorder,
  });

  const CustomShimmer.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 999,
        shapeBorder = const CircleBorder();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceElevated,
      child: Container(
        width: width,
        height: height,
        decoration: shapeBorder != null
            ? ShapeDecoration(
                color: AppColors.surface,
                shape: shapeBorder!,
              )
            : BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
      ),
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerGrid({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const CustomShimmer(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const CustomShimmer(width: double.infinity, height: 12, borderRadius: 4),
          const SizedBox(height: 4),
          const CustomShimmer(width: 50, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

class ShimmerHorizontalList extends StatelessWidget {
  final double height;

  const ShimmerHorizontalList({super.key, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const CustomShimmer(
                    width: 130,
                    height: double.infinity,
                    borderRadius: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const CustomShimmer(width: 110, height: 12, borderRadius: 4),
              const SizedBox(height: 4),
              const CustomShimmer(width: 60, height: 10, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
