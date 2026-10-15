/// Core constants for the YUKINIME app
class AppConstants {
  AppConstants._();

  static const String appName = 'YUKINIME';
  static const String appVersion = '1.0.0';

  // API
  static const String baseUrl = 'https://www.sankavollerei.web.id';
  static const int apiTimeout = 15000; // ms

  // Storage keys
  static const String favoritesBox = 'favorites';
  static const String watchlistBox = 'watchlist';
  static const String historyBox = 'watch_history';
  static const String settingsBox = 'settings';
  static const String searchHistoryBox = 'search_history';

  // Settings keys
  static const String autoplayKey = 'autoplay_next';
  static const String defaultQualityKey = 'default_quality';

  // Player
  static const int seekDuration = 5; // seconds
  static const int controlsHideDelay = 4; // seconds
  static const int autoplayCountdown = 10; // seconds
  static const int progressSaveInterval = 10; // seconds
  static const double completionThreshold = 0.92; // 92% = completed

  // UI
  static const double posterAspectRatio = 2 / 3;
  static const double bannerAspectRatio = 16 / 9;
  static const int searchDebounceMs = 500;
  static const int maxSearchHistory = 20;
}
