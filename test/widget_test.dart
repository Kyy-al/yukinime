import 'package:flutter_test/flutter_test.dart';
import 'package:YUKINIME/core/constants/app_constants.dart';
import 'package:YUKINIME/data/models/anime_models.dart';

void main() {
  group('YUKINIME Core Tests', () {
    test('AppConstants values are correct', () {
      expect(AppConstants.appName, 'YUKINIME');
      expect(AppConstants.baseUrl, 'https://www.sankavollerei.web.id');
      expect(AppConstants.seekDuration, 5);
      expect(AppConstants.completionThreshold, 0.92);
    });

    test('AnimeLatest model serialization test', () {
      final json = {
        'id': 101,
        'url': 'naruto-shippuden',
        'judul': 'Naruto Shippuden',
        'cover': 'https://example.com/naruto.jpg',
        'lastch': 'Ep 500',
        'lastup': '1 hari lalu',
      };

      final anime = AnimeLatest.fromJson(json);
      expect(anime.id, 101);
      expect(anime.url, 'naruto-shippuden');
      expect(anime.judul, 'Naruto Shippuden');
      expect(anime.lastch, 'Ep 500');
    });

    test('Chapter sorting in AnimeDetail model', () {
      final json = {
        'id': 1,
        'series_id': 'bleach',
        'cover': 'https://example.com/bleach.jpg',
        'judul': 'Bleach',
        'type': 'TV',
        'status': 'Completed',
        'rating': '8.5',
        'published': '2004',
        'author': 'Pierrot',
        'genre': ['Action', 'Supernatural'],
        'sinopsis': 'Story of Ichigo Kurosaki.',
        'chapter': [
          {'id': 102, 'ch': '2', 'url': 'bleach-ep-2', 'date': '2024', 'views': 100},
          {'id': 101, 'ch': '1', 'url': 'bleach-ep-1', 'date': '2024', 'views': 200},
          {'id': 103, 'ch': '3', 'url': 'bleach-ep-3', 'date': '2024', 'views': 150},
        ],
      };

      final detail = AnimeDetail.fromJson(json);
      expect(detail.totalEpisodes, 3);
      final sorted = detail.sortedChapters;
      expect(sorted[0].ch, '1');
      expect(sorted[1].ch, '2');
      expect(sorted[2].ch, '3');
    });
  });
}
