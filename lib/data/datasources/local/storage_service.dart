import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/local_models.dart';

class StorageService {
  static StorageService? _instance;
  late Box<String> _favoritesBox;
  late Box<String> _watchlistBox;
  late Box<String> _historyBox;
  late Box<dynamic> _settingsBox;
  late Box<String> _searchHistoryBox;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  static Future<void> init() async {
    await Hive.initFlutter();
    final service = StorageService.instance;
    service._favoritesBox = await Hive.openBox<String>(AppConstants.favoritesBox);
    service._watchlistBox = await Hive.openBox<String>(AppConstants.watchlistBox);
    service._historyBox = await Hive.openBox<String>(AppConstants.historyBox);
    service._settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);
    service._searchHistoryBox =
        await Hive.openBox<String>(AppConstants.searchHistoryBox);
  }

  // --- Watch History ---
  List<WatchHistoryEntry> getWatchHistory() {
    final list = _historyBox.values.map((e) => WatchHistoryEntry.fromJson(e)).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  WatchHistoryEntry? getHistoryForAnime(String animeUrl) {
    final raw = _historyBox.get(animeUrl);
    if (raw == null) return null;
    return WatchHistoryEntry.fromJson(raw);
  }

  Future<void> saveWatchHistory(WatchHistoryEntry entry) async {
    await _historyBox.put(entry.animeUrl, entry.toJson());
  }

  Future<void> removeWatchHistory(String animeUrl) async {
    await _historyBox.delete(animeUrl);
  }

  Future<void> clearWatchHistory() async {
    await _historyBox.clear();
  }

  // --- Favorites ---
  List<AnimeBookmarkEntry> getFavorites() {
    final list = _favoritesBox.values.map((e) => AnimeBookmarkEntry.fromJson(e)).toList();
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  bool isFavorite(String animeUrl) {
    return _favoritesBox.containsKey(animeUrl);
  }

  Future<void> toggleFavorite(AnimeBookmarkEntry entry) async {
    if (isFavorite(entry.animeUrl)) {
      await _favoritesBox.delete(entry.animeUrl);
    } else {
      await _favoritesBox.put(entry.animeUrl, entry.toJson());
    }
  }

  Future<void> removeFavorite(String animeUrl) async {
    await _favoritesBox.delete(animeUrl);
  }

  // --- Watchlist ---
  List<AnimeBookmarkEntry> getWatchlist() {
    final list = _watchlistBox.values.map((e) => AnimeBookmarkEntry.fromJson(e)).toList();
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  bool isWatchlist(String animeUrl) {
    return _watchlistBox.containsKey(animeUrl);
  }

  Future<void> toggleWatchlist(AnimeBookmarkEntry entry) async {
    if (isWatchlist(entry.animeUrl)) {
      await _watchlistBox.delete(entry.animeUrl);
    } else {
      await _watchlistBox.put(entry.animeUrl, entry.toJson());
    }
  }

  Future<void> removeWatchlist(String animeUrl) async {
    await _watchlistBox.delete(animeUrl);
  }

  // --- Search History ---
  List<String> getSearchHistory() {
    return _searchHistoryBox.values.toList().reversed.toList();
  }

  Future<void> addSearchQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    
    // Remove if already exists so we don't have duplicates
    final keyToDelete = _searchHistoryBox.keys.firstWhere(
      (k) => _searchHistoryBox.get(k) == trimmed,
      orElse: () => null,
    );
    if (keyToDelete != null) {
      await _searchHistoryBox.delete(keyToDelete);
    }

    // Limit to max items
    if (_searchHistoryBox.length >= AppConstants.maxSearchHistory) {
      await _searchHistoryBox.deleteAt(0);
    }
    await _searchHistoryBox.add(trimmed);
  }

  Future<void> removeSearchQuery(String query) async {
    final keyToDelete = _searchHistoryBox.keys.firstWhere(
      (k) => _searchHistoryBox.get(k) == query,
      orElse: () => null,
    );
    if (keyToDelete != null) {
      await _searchHistoryBox.delete(keyToDelete);
    }
  }

  Future<void> clearSearchHistory() async {
    await _searchHistoryBox.clear();
  }

  // --- Settings ---
  bool get autoplayNext =>
      _settingsBox.get(AppConstants.autoplayKey, defaultValue: true) as bool;

  Future<void> setAutoplayNext(bool value) async {
    await _settingsBox.put(AppConstants.autoplayKey, value);
  }

  String get defaultQuality =>
      _settingsBox.get(AppConstants.defaultQualityKey, defaultValue: '720p') as String;

  Future<void> setDefaultQuality(String quality) async {
    await _settingsBox.put(AppConstants.defaultQualityKey, quality);
  }
}
