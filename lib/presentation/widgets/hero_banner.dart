import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../data/models/anime_models.dart';
import 'custom_shimmer.dart';

class HeroBannerCarousel extends StatefulWidget {
  final List<AnimeRecommended> items;

  const HeroBannerCarousel({super.key, required this.items});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final displayItems = widget.items.take(5).toList();

    return Column(
      children: [
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            itemCount: displayItems.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final anime = displayItems[index];
              final cleanId = anime.url.replaceAll(RegExp(r'/+$'), '');

              return GestureDetector(
                onTap: () => context.push('/detail', extra: cleanId),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Backdrop Image
                    CachedNetworkImage(
                      imageUrl: anime.cover,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      placeholder: (_, __) => const CustomShimmer(
                        width: double.infinity,
                        height: 380,
                        borderRadius: 0,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.movie, size: 64, color: AppColors.textTertiary),
                      ),
                    ),

                    // Cinematic Gradient Overlays
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.background.withOpacity(0.4),
                              AppColors.background.withOpacity(0.9),
                              AppColors.background,
                            ],
                            stops: const [0.0, 0.45, 0.8, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Top dark vignette for status bar readability
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 80,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Content at bottom
                    Positioned(
                      bottom: 24,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badges Row (Studio + Rating)
                          Row(
                            children: [
                              if (anime.studio.isNotEmpty && anime.studio != 'N/A') ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    anime.studio,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],

                              if (anime.score.isNotEmpty && anime.score != '0')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.warning,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        anime.score,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Anime Title
                          Text(
                            anime.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Genres
                          if (anime.genre.isNotEmpty)
                            Text(
                              anime.genre.take(3).join(' • '),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                          const SizedBox(height: 14),

                          // Action Button
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    context.push('/detail', extra: cleanId),
                                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                                label: const Text('Tonton Sekarang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 4,
                                  shadowColor: AppColors.primary.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    context.push('/detail', extra: cleanId),
                                icon: const Icon(Icons.info_outline_rounded, size: 18),
                                label: const Text('Detail'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(color: AppColors.border),
                                  backgroundColor: AppColors.surface.withOpacity(0.6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            displayItems.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              height: 4,
              width: _currentPage == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.textTertiary.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
