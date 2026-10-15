import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/models/anime_models.dart';
import '../../../data/models/local_models.dart';
import '../../providers/anime_providers.dart';
import '../../widgets/custom_shimmer.dart';
import '../../widgets/error_view.dart';

class AnimeDetailScreen extends ConsumerStatefulWidget {
  final String urlId;

  const AnimeDetailScreen({super.key, required this.urlId});

  @override
  ConsumerState<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends ConsumerState<AnimeDetailScreen> {
  bool _isSynopsisExpanded = false;
  bool _isAscendingOrder = true;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(animeDetailProvider(widget.urlId));
    final favorites = ref.watch(favoritesProvider);
    final watchlist = ref.watch(watchlistProvider);
    final watchHistory = ref.watch(watchHistoryProvider);

    final isFav = favorites.any((e) => e.animeUrl == widget.urlId);
    final isWatch = watchlist.any((e) => e.animeUrl == widget.urlId);

    // Find if user has watched any episode of this anime
    final historyEntry = watchHistory.where((e) => e.animeUrl == widget.urlId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        data: (detail) {
          final sortedChapters = _isAscendingOrder
              ? detail.sortedChapters
              : detail.sortedChapters.reversed.toList();

          return CustomScrollView(
            slivers: [
              // Collapsing Backdrop Header
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.background,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        Share.share(
                          'Tonton ${detail.judul} di YUKINIME!\nhttps://YUKINIME.app/anime/${widget.urlId}',
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: detail.cover,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        placeholder: (_, __) => const CustomShimmer(
                          width: double.infinity,
                          height: 320,
                          borderRadius: 0,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surface,
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                AppColors.background.withOpacity(0.85),
                                AppColors.background,
                              ],
                              stops: const [0.0, 0.35, 0.75, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Anime Info Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title & Rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              detail.judul,
                              style: AppTypography.headlineMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (detail.rating != '0' && detail.rating.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warning.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.warning,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    detail.rating,
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Meta Info (Type • Status • Studio • Year)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (detail.type.isNotEmpty) _buildMetaBadge(detail.type),
                          if (detail.status.isNotEmpty)
                            _buildMetaBadge(
                              detail.status,
                              color: detail.status.toLowerCase().contains('completed')
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          if (detail.author.isNotEmpty && detail.author != 'N/A')
                            _buildMetaBadge(detail.author),
                          if (detail.published.isNotEmpty)
                            _buildMetaBadge(detail.published),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Genres
                      if (detail.genre.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: detail.genre.map((g) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                g,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 20),

                      // Primary CTA Play Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (detail.chapters.isEmpty) return;

                            // If user has history, continue from that episode!
                            if (historyEntry != null) {
                              final ch = detail.chapters.firstWhere(
                                (c) => c.url == historyEntry.chapterUrl,
                                orElse: () => detail.sortedChapters.first,
                              );
                              _navigateToPlayer(
                                context,
                                detail,
                                ch,
                                startSeconds: historyEntry.positionSeconds,
                              );
                            } else {
                              // Start episode 1
                              _navigateToPlayer(
                                context,
                                detail,
                                detail.sortedChapters.first,
                              );
                            }
                          },
                          icon: Icon(
                            historyEntry != null
                                ? Icons.play_arrow_rounded
                                : Icons.play_circle_filled_rounded,
                            size: 26,
                          ),
                          label: Text(
                            historyEntry != null
                                ? 'Lanjutkan: ${historyEntry.chapterTitle}'
                                : 'Mulai Menonton (Ep 1)',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 4,
                            shadowColor: AppColors.primary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Bookmark Action Buttons (Favorite & Watchlist)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final entry = AnimeBookmarkEntry(
                                  animeUrl: widget.urlId,
                                  animeTitle: detail.judul,
                                  cover: detail.cover,
                                  score: detail.rating,
                                  type: detail.type,
                                  genres: detail.genre,
                                  addedAt: DateTime.now(),
                                );
                                ref.read(favoritesProvider.notifier).toggle(entry);
                              },
                              icon: Icon(
                                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isFav ? AppColors.error : AppColors.textSecondary,
                                size: 18,
                              ),
                              label: Text(
                                isFav ? 'Favorit' : 'Tambah Favorit',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isFav ? AppColors.error : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isFav ? AppColors.error : AppColors.border,
                                ),
                                backgroundColor: isFav
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final entry = AnimeBookmarkEntry(
                                  animeUrl: widget.urlId,
                                  animeTitle: detail.judul,
                                  cover: detail.cover,
                                  score: detail.rating,
                                  type: detail.type,
                                  genres: detail.genre,
                                  addedAt: DateTime.now(),
                                );
                                ref.read(watchlistProvider.notifier).toggle(entry);
                              },
                              icon: Icon(
                                isWatch
                                    ? Icons.bookmark_added_rounded
                                    : Icons.bookmark_add_outlined,
                                color: isWatch ? AppColors.accent : AppColors.textSecondary,
                                size: 18,
                              ),
                              label: Text(
                                isWatch ? 'Watchlist' : 'Ingin Nonton',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isWatch ? AppColors.accent : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isWatch ? AppColors.accent : AppColors.border,
                                ),
                                backgroundColor: isWatch
                                    ? AppColors.primary.withOpacity(0.12)
                                    : AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Synopsis Section
                      if (detail.sinopsis.isNotEmpty) ...[
                        Text(
                          'Sinopsis',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.sinopsis,
                          maxLines: _isSynopsisExpanded ? null : 3,
                          overflow: _isSynopsisExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSynopsisExpanded = !_isSynopsisExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              _isSynopsisExpanded ? 'Tutup' : 'Selengkapnya',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Episode List Header & Sort Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Daftar Episode',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${detail.totalEpisodes} Ep',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isAscendingOrder = !_isAscendingOrder;
                              });
                            },
                            icon: Icon(
                              _isAscendingOrder
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 16,
                              color: AppColors.accent,
                            ),
                            label: Text(
                              _isAscendingOrder ? 'Terlama' : 'Terbaru',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Episode Items
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chapter = sortedChapters[index];
                      final isCurrentlyWatched =
                          historyEntry?.chapterUrl == chapter.url;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isCurrentlyWatched
                              ? AppColors.primary.withOpacity(0.12)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrentlyWatched
                                ? AppColors.primary
                                : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              _navigateToPlayer(context, detail, chapter);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Play icon or badge
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isCurrentlyWatched
                                          ? AppColors.primary
                                          : AppColors.surfaceElevated,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCurrentlyWatched
                                          ? Icons.play_arrow_rounded
                                          : Icons.play_circle_outline_rounded,
                                      color: isCurrentlyWatched
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Chapter Name & Date
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          chapter.displayTitle,
                                          style: AppTypography.titleSmall.copyWith(
                                            fontWeight: isCurrentlyWatched
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: isCurrentlyWatched
                                                ? AppColors.accent
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        if (chapter.date.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            chapter.date,
                                            style: AppTypography.bodySmall.copyWith(
                                              fontSize: 11,
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Watched indicator or views
                                  if (isCurrentlyWatched)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Terakhir Ditonton',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (chapter.views > 0)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.visibility_outlined,
                                          size: 13,
                                          color: AppColors.textTertiary,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${chapter.views}',
                                          style: AppTypography.bodySmall.copyWith(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: sortedChapters.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
        loading: () => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomShimmer(width: double.infinity, height: 200, borderRadius: 12),
                SizedBox(height: 16),
                CustomShimmer(width: 200, height: 24, borderRadius: 6),
                SizedBox(height: 8),
                CustomShimmer(width: 140, height: 16, borderRadius: 4),
                SizedBox(height: 24),
                CustomShimmer(width: double.infinity, height: 48, borderRadius: 12),
              ],
            ),
          ),
        ),
        error: (err, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: ErrorView(
            message: err.toString(),
            onRetry: () => ref.refresh(animeDetailProvider(widget.urlId)),
          ),
        ),
      ),
    );
  }

  void _navigateToPlayer(
    BuildContext context,
    AnimeDetail detail,
    Chapter chapter, {
    int startSeconds = 0,
  }) {
    context.push(
      '/player',
      extra: {
        'chapterUrlId': chapter.url,
        'animeUrl': widget.urlId,
        'animeTitle': detail.judul,
        'cover': detail.cover,
        'chapterTitle': chapter.displayTitle,
        'episodeNumber': chapter.episodeNumber,
        'startPositionSeconds': startSeconds,
        'allChapters': detail.sortedChapters
            .map((c) => {
                  'url': c.url,
                  'title': c.displayTitle,
                  'episodeNumber': c.episodeNumber,
                })
            .toList(),
      },
    );
  }

  Widget _buildMetaBadge(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? AppColors.surfaceElevated).withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color ?? AppColors.border,
          width: 0.6,
        ),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: color ?? AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
