import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../providers/anime_providers.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/custom_shimmer.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: false,
              style: AppTypography.bodyMedium,
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.search,
              onChanged: (val) {
                ref.read(searchProvider.notifier).onQueryChanged(val);
              },
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  ref.read(searchProvider.notifier).search(val);
                }
              },
              decoration: InputDecoration(
                hintText: 'Cari anime, movie, judul...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: AppColors.textSecondary,
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          // If searching or loading
          if (searchState.isLoading) {
            return const Padding(
              padding: EdgeInsets.only(top: 16),
              child: ShimmerGrid(itemCount: 9),
            );
          }

          // If error
          if (searchState.error != null) {
            return ErrorView(
              message: searchState.error!,
              onRetry: () {
                if (_controller.text.isNotEmpty) {
                  ref.read(searchProvider.notifier).search(_controller.text);
                }
              },
            );
          }

          // If results exist
          if (searchState.result != null) {
            final results = searchState.result!.results;

            if (results.isEmpty) {
              return EmptyView(
                title: 'Tidak Ada Hasil',
                message:
                    'Tidak menemukan anime untuk "${searchState.query}". Coba kata kunci lain.',
                icon: Icons.search_off_rounded,
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Ditemukan ${searchState.result!.total} hasil untuk "${searchState.query}"',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 14,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final anime = results[index];
                        return AnimeCard(
                          urlId: anime.url,
                          title: anime.judul,
                          cover: anime.cover,
                          score: anime.score,
                          subtitle: anime.genre.isNotEmpty ? anime.genre.first : null,
                          width: double.infinity,
                        );
                      },
                      childCount: results.length,
                    ),
                  ),
                ),
              ],
            );
          }

          // Default state: show search history & popular tags
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (searchHistory.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Pencarian',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(searchHistoryProvider.notifier).clearAll();
                        },
                        child: Text(
                          'Hapus Semua',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: searchHistory.map((query) {
                      return InputChip(
                        label: Text(query),
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        deleteIconColor: AppColors.textTertiary,
                        onDeleted: () {
                          ref
                              .read(searchHistoryProvider.notifier)
                              .remove(query);
                        },
                        onPressed: () {
                          _controller.text = query;
                          ref.read(searchProvider.notifier).search(query);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Popular suggestions
                Text(
                  'Pencarian Populer',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Naruto',
                    'One Piece',
                    'Jujutsu Kaisen',
                    'Demon Slayer',
                    'Bleach',
                    'Attack on Titan',
                    'Solo Leveling',
                    'Black Clover',
                    'Spy x Family',
                  ].map((tag) {
                    return ActionChip(
                      label: Text(tag),
                      labelStyle: AppTypography.bodySmall.copyWith(
                        color: AppColors.accent,
                      ),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.border.withOpacity(0.8)),
                      avatar: const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.accent,
                        size: 14,
                      ),
                      onPressed: () {
                        _controller.text = tag;
                        ref.read(searchProvider.notifier).search(tag);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
