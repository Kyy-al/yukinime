import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../providers/anime_providers.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/continue_watching_card.dart';
import '../../widgets/empty_view.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);
    final favorites = ref.watch(favoritesProvider);
    final watchlist = ref.watch(watchlistProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSecondary,
          elevation: 0,
          title: Text(
            'Koleksi Saya',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTypography.labelLarge,
            tabs: [
              Tab(text: 'Riwayat (${history.length})'),
              Tab(text: 'Favorit (${favorites.length})'),
              Tab(text: 'Watchlist (${watchlist.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Riwayat Menonton
            _buildHistoryTab(context, ref, history),

            // Tab 2: Favorit
            _buildFavoritesTab(context, ref, favorites),

            // Tab 3: Watchlist
            _buildWatchlistTab(context, ref, watchlist),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> history,
  ) {
    if (history.isEmpty) {
      return const EmptyView(
        title: 'Belum Ada Riwayat',
        message: 'Anime yang kamu tonton akan tersimpan otomatis di sini.',
        icon: Icons.history_rounded,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terakhir Ditonton',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ref.read(watchHistoryProvider.notifier).clearAll();
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                label: Text(
                  'Hapus Semua',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = history[index];
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
      ],
    );
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> favorites,
  ) {
    if (favorites.isEmpty) {
      return const EmptyView(
        title: 'Belum Ada Favorit',
        message: 'Tekan tombol Favorit pada detail anime untuk menyimpannya di sini.',
        icon: Icons.favorite_border_rounded,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final item = favorites[index];
        return AnimeCard(
          urlId: item.animeUrl,
          title: item.animeTitle,
          cover: item.cover,
          score: item.score,
          subtitle: item.type,
          width: double.infinity,
        );
      },
    );
  }

  Widget _buildWatchlistTab(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> watchlist,
  ) {
    if (watchlist.isEmpty) {
      return const EmptyView(
        title: 'Watchlist Masih Kosong',
        message: 'Tandai anime yang ingin kamu tonton nanti untuk menyimpannya di sini.',
        icon: Icons.bookmark_border_rounded,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 14,
      ),
      itemCount: watchlist.length,
      itemBuilder: (context, index) {
        final item = watchlist[index];
        return AnimeCard(
          urlId: item.animeUrl,
          title: item.animeTitle,
          cover: item.cover,
          score: item.score,
          subtitle: item.type,
          width: double.infinity,
        );
      },
    );
  }
}
