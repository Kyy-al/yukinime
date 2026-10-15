import 'dart:convert';

/// Local storage model for tracking watch history
class WatchHistoryEntry {
  final String animeUrl;
  final String animeTitle;
  final String cover;
  final String chapterUrl; // e.g. al-150506-1
  final String chapterTitle; // e.g. Episode 1
  final int episodeNumber;
  final int positionSeconds;
  final int totalSeconds;
  final DateTime updatedAt;

  const WatchHistoryEntry({
    required this.animeUrl,
    required this.animeTitle,
    required this.cover,
    required this.chapterUrl,
    required this.chapterTitle,
    required this.episodeNumber,
    required this.positionSeconds,
    required this.totalSeconds,
    required this.updatedAt,
  });

  double get progressPercentage {
    if (totalSeconds <= 0) return 0.0;
    return (positionSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  bool get isCompleted => progressPercentage >= 0.90;

  Map<String, dynamic> toMap() {
    return {
      'animeUrl': animeUrl,
      'animeTitle': animeTitle,
      'cover': cover,
      'chapterUrl': chapterUrl,
      'chapterTitle': chapterTitle,
      'episodeNumber': episodeNumber,
      'positionSeconds': positionSeconds,
      'totalSeconds': totalSeconds,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WatchHistoryEntry.fromMap(Map<String, dynamic> map) {
    return WatchHistoryEntry(
      animeUrl: map['animeUrl'] ?? '',
      animeTitle: map['animeTitle'] ?? '',
      cover: map['cover'] ?? '',
      chapterUrl: map['chapterUrl'] ?? '',
      chapterTitle: map['chapterTitle'] ?? '',
      episodeNumber: map['episodeNumber'] is int
          ? map['episodeNumber']
          : int.tryParse('${map['episodeNumber']}') ?? 1,
      positionSeconds: map['positionSeconds'] is int
          ? map['positionSeconds']
          : int.tryParse('${map['positionSeconds']}') ?? 0,
      totalSeconds: map['totalSeconds'] is int
          ? map['totalSeconds']
          : int.tryParse('${map['totalSeconds']}') ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory WatchHistoryEntry.fromJson(String source) =>
      WatchHistoryEntry.fromMap(jsonDecode(source));
}

/// Local storage model for Favorites and Watchlist
class AnimeBookmarkEntry {
  final String animeUrl;
  final String animeTitle;
  final String cover;
  final String score;
  final String type;
  final List<String> genres;
  final DateTime addedAt;

  const AnimeBookmarkEntry({
    required this.animeUrl,
    required this.animeTitle,
    required this.cover,
    required this.score,
    required this.type,
    required this.genres,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'animeUrl': animeUrl,
      'animeTitle': animeTitle,
      'cover': cover,
      'score': score,
      'type': type,
      'genres': genres,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory AnimeBookmarkEntry.fromMap(Map<String, dynamic> map) {
    return AnimeBookmarkEntry(
      animeUrl: map['animeUrl'] ?? '',
      animeTitle: map['animeTitle'] ?? '',
      cover: map['cover'] ?? '',
      score: map['score'] ?? '0',
      type: map['type'] ?? 'TV',
      genres: (map['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      addedAt: map['addedAt'] != null
          ? DateTime.tryParse(map['addedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AnimeBookmarkEntry.fromJson(String source) =>
      AnimeBookmarkEntry.fromMap(jsonDecode(source));
}
