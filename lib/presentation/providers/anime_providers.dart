import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/local/storage_service.dart';
import '../../data/datasources/remote/anime_remote_data_source.dart';
import '../../data/models/anime_models.dart';
import '../../data/models/local_models.dart';
import '../../data/repositories/anime_repository.dart';

// Repositories & Services
final animeRepositoryProvider = Provider<AnimeRepository>((ref) {
  return AnimeRepository(remoteDataSource: AnimeRemoteDataSourceImpl());
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

// Home Page Data Providers
final latestAnimeProvider = FutureProvider<List<AnimeLatest>>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getLatestAnime();
});

final recommendedAnimeProvider = FutureProvider<List<AnimeRecommended>>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getRecommendedAnime(page: 1);
});

final moviesAnimeProvider = FutureProvider<List<AnimeRecommended>>((ref) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getMovies();
});

// Anime Detail Provider
final animeDetailProvider =
    FutureProvider.autoDispose.family<AnimeDetail, String>((ref, urlId) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getAnimeDetail(urlId);
});

// Video Stream Provider
class StreamRequest {
  final String chapterUrlId;
  final String? reso;

  const StreamRequest({required this.chapterUrlId, this.reso});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreamRequest &&
          runtimeType == other.runtimeType &&
          chapterUrlId == other.chapterUrlId &&
          reso == other.reso;

  @override
  int get hashCode => chapterUrlId.hashCode ^ (reso?.hashCode ?? 0);
}

final videoStreamProvider =
    FutureProvider.autoDispose.family<VideoStream, StreamRequest>((ref, req) async {
  final repo = ref.watch(animeRepositoryProvider);
  return repo.getVideoStream(req.chapterUrlId, reso: req.reso);
});

// Search State & Provider
class SearchState {
  final String query;
  final bool isLoading;
  final SearchResult? result;
  final String? error;

  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.result,
    this.error,
  });

  SearchState copyWith({
    String? query,
    bool? isLoading,
    SearchResult? result,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final AnimeRepository _repository;
  final StorageService _storageService;
  Timer? _debounceTimer;

  SearchNotifier(this._repository, this._storageService)
      : super(const SearchState());

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => search(query),
    );
  }

  Future<void> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: cleanQuery, isLoading: true, error: null);

    try {
      final result = await _repository.searchAnime(cleanQuery);
      // Save query to search history
      await _storageService.addSearchQuery(cleanQuery);
      state = state.copyWith(
        isLoading: false,
        result: result,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>((ref) {
  final repo = ref.watch(animeRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);
  return SearchNotifier(repo, storage);
});

// Watch History Provider
class WatchHistoryNotifier extends StateNotifier<List<WatchHistoryEntry>> {
  final StorageService _storageService;

  WatchHistoryNotifier(this._storageService)
      : super(_storageService.getWatchHistory());

  Future<void> saveProgress({
    required String animeUrl,
    required String animeTitle,
    required String cover,
    required String chapterUrl,
    required String chapterTitle,
    required int episodeNumber,
    required int positionSeconds,
    required int totalSeconds,
  }) async {
    final entry = WatchHistoryEntry(
      animeUrl: animeUrl,
      animeTitle: animeTitle,
      cover: cover,
      chapterUrl: chapterUrl,
      chapterTitle: chapterTitle,
      episodeNumber: episodeNumber,
      positionSeconds: positionSeconds,
      totalSeconds: totalSeconds,
      updatedAt: DateTime.now(),
    );
    await _storageService.saveWatchHistory(entry);
    state = _storageService.getWatchHistory();
  }

  Future<void> removeEntry(String animeUrl) async {
    await _storageService.removeWatchHistory(animeUrl);
    state = _storageService.getWatchHistory();
  }

  Future<void> clearAll() async {
    await _storageService.clearWatchHistory();
    state = [];
  }
}

final watchHistoryProvider =
    StateNotifierProvider<WatchHistoryNotifier, List<WatchHistoryEntry>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WatchHistoryNotifier(storage);
});

// Favorites Provider
class FavoritesNotifier extends StateNotifier<List<AnimeBookmarkEntry>> {
  final StorageService _storageService;

  FavoritesNotifier(this._storageService)
      : super(_storageService.getFavorites());

  bool isFavorite(String animeUrl) => _storageService.isFavorite(animeUrl);

  Future<void> toggle(AnimeBookmarkEntry entry) async {
    await _storageService.toggleFavorite(entry);
    state = _storageService.getFavorites();
  }

  Future<void> remove(String animeUrl) async {
    await _storageService.removeFavorite(animeUrl);
    state = _storageService.getFavorites();
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<AnimeBookmarkEntry>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return FavoritesNotifier(storage);
});

// Watchlist Provider
class WatchlistNotifier extends StateNotifier<List<AnimeBookmarkEntry>> {
  final StorageService _storageService;

  WatchlistNotifier(this._storageService)
      : super(_storageService.getWatchlist());

  bool isWatchlist(String animeUrl) => _storageService.isWatchlist(animeUrl);

  Future<void> toggle(AnimeBookmarkEntry entry) async {
    await _storageService.toggleWatchlist(entry);
    state = _storageService.getWatchlist();
  }

  Future<void> remove(String animeUrl) async {
    await _storageService.removeWatchlist(animeUrl);
    state = _storageService.getWatchlist();
  }
}

final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, List<AnimeBookmarkEntry>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WatchlistNotifier(storage);
});

// Search History Provider
class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final StorageService _storageService;

  SearchHistoryNotifier(this._storageService)
      : super(_storageService.getSearchHistory());

  void refresh() {
    state = _storageService.getSearchHistory();
  }

  Future<void> remove(String query) async {
    await _storageService.removeSearchQuery(query);
    state = _storageService.getSearchHistory();
  }

  Future<void> clearAll() async {
    await _storageService.clearSearchHistory();
    state = [];
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SearchHistoryNotifier(storage);
});

// Settings State
class AppSettingsState {
  final bool autoplayNext;
  final String defaultQuality;

  const AppSettingsState({
    required this.autoplayNext,
    required this.defaultQuality,
  });
}

class SettingsNotifier extends StateNotifier<AppSettingsState> {
  final StorageService _storageService;

  SettingsNotifier(this._storageService)
      : super(AppSettingsState(
          autoplayNext: _storageService.autoplayNext,
          defaultQuality: _storageService.defaultQuality,
        ));

  Future<void> setAutoplayNext(bool value) async {
    await _storageService.setAutoplayNext(value);
    state = AppSettingsState(
      autoplayNext: value,
      defaultQuality: state.defaultQuality,
    );
  }

  Future<void> setDefaultQuality(String quality) async {
    await _storageService.setDefaultQuality(quality);
    state = AppSettingsState(
      autoplayNext: state.autoplayNext,
      defaultQuality: quality,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettingsState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});
