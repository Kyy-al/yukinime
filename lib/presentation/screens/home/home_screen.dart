import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../providers/anime_providers.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/continue_watching_card.dart';
import '../../widgets/custom_shimmer.dart';
import '../../widgets/error_view.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestAnimeProvider);
    final recommendedAsync = ref.watch(recommendedAnimeProvider);
    final moviesAsync = ref.watch(moviesAnimeProvider);
    final watchHistory = ref.watch(watchHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(latestAnimeProvider);
          ref.invalidate(recommendedAnimeProvider);
          ref.invalidate(moviesAnimeProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Floating Sleek App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              elevation: 0,
              backgroundColor: AppColors.background.withOpacity(0.85),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'YUKINIME',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.push('/search'),
                  tooltip: 'Cari Anime',
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Top Hero Banner Carousel
            SliverToBoxAdapter(
              child: recommendedAsync.when(
                data: (items) => HeroBannerCarousel(items: items),
                loading: () => const CustomShimmer(
                  width: double.infinity,
                  height: 380,
                  borderRadius: 0,
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),

            // Continue Watching Shelf (if history exists)
            if (watchHistory.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Lanjutkan Menonton',
                  subtitle: 'Tonton kembali dari menit terakhir',
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 185,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: watchHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = watchHistory[index];
                      return ContinueWatchingCard(
                        entry: item,
                        onRemove: () {
                          ref
                              .read(watchHistoryProvider.notifier)
                              .removeEntry(item.animeUrl);
                        },
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // Latest Episodes ("Update Terkini")
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Episode Terbaru',
                subtitle: 'Rilis hari ini & episode terhangat',
              ),
            ),
            SliverToBoxAdapter(
              child: latestAsync.when(
                data: (items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 220,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final anime = items[index];
                        return AnimeCard(
                          urlId: anime.url,
                          title: anime.judul,
                          cover: anime.cover,
                          badgeText: anime.lastch.isNotEmpty ? anime.lastch : null,
                          subtitle: anime.lastup.isNotEmpty ? anime.lastup : null,
                          width: 130,
                        );
                      },
                    ),
                  );
                },
                loading: () => const ShimmerHorizontalList(height: 220),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(latestAnimeProvider),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Anime Movies Section
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Film Anime',
                subtitle: 'Movie layar lebar kualitas terbaik',
              ),
            ),
            SliverToBoxAdapter(
              child: moviesAsync.when(
                data: (items) {
                  if (items.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 220,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final anime = items[index];
                        return AnimeCard(
                          urlId: anime.url,
                          title: anime.judul,
                          cover: anime.cover,
                          score: anime.score,
                          subtitle: anime.studio != 'N/A' ? anime.studio : null,
                          width: 130,
                        );
                      },
                    ),
                  );
                },
                loading: () => const ShimmerHorizontalList(height: 220),
                error: (err, _) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Recommended Anime ("Rekomendasi Populer") Grid
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Rekomendasi Populer',
                subtitle: 'Anime pilihan rating tinggi',
              ),
            ),
            recommendedAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final anime = items[index];
                        return AnimeCard(
                          urlId: anime.url,
                          title: anime.judul,
                          cover: anime.cover,
                          score: anime.score,
                          subtitle: anime.genre.isNotEmpty ? anime.genre.first : null,
                          width: double.infinity,
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: ShimmerGrid(itemCount: 6),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: ErrorView(
                  message: err.toString(),
                  onRetry: () => ref.refresh(recommendedAnimeProvider),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}
