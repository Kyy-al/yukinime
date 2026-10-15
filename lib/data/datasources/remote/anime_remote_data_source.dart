import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../models/anime_models.dart';

abstract class AnimeRemoteDataSource {
  Future<List<AnimeLatest>> getLatestAnime();
  Future<List<AnimeRecommended>> getRecommendedAnime({int page = 1});
  Future<List<AnimeRecommended>> getMovies();
  Future<SearchResult> searchAnime(String query);
  Future<AnimeDetail> getAnimeDetail(String urlId);
  Future<VideoStream> getVideoStream(String chapterUrlId, {String? reso});
  Future<String> getServerUrl(String serverId);
}

class AnimeRemoteDataSourceImpl implements AnimeRemoteDataSource {
  final ApiClient _apiClient;

  AnimeRemoteDataSourceImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<AnimeLatest>> getLatestAnime() async {
    try {
      final response = await _apiClient.get('/anime/home');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final ongoing = data['data']['ongoing'];
        if (ongoing is Map<String, dynamic> && ongoing['animeList'] is List) {
          return (ongoing['animeList'] as List)
              .map((e) => AnimeLatest.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      try {
        final res = await _apiClient.get(
          '/anime/ongoing-anime',
          queryParameters: {'page': 1},
        );
        final d = res.data;
        if (d is Map<String, dynamic> && d['data'] is Map<String, dynamic>) {
          final list = d['data']['animeList'];
          if (list is List) {
            return list
                .map((e) => AnimeLatest.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {}
    }
    return [];
  }

  @override
  Future<List<AnimeRecommended>> getRecommendedAnime({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        '/anime/ongoing-anime',
        queryParameters: {'page': page},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final list = data['data']['animeList'];
        if (list is List) {
          return list
              .map((e) => AnimeRecommended.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<AnimeRecommended>> getMovies() async {
    try {
      final response = await _apiClient.get(
        '/anime/complete-anime',
        queryParameters: {'page': 1},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        final list = data['data']['animeList'];
        if (list is List) {
          return list
              .map((e) => AnimeRecommended.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<SearchResult> searchAnime(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const SearchResult(
        total: 0,
        results: [],
        pagination: SearchPagination(page: 1, totalPages: 1, hasNext: false),
      );
    }
    final response = await _apiClient.get(
      '/anime/search/${Uri.encodeComponent(cleanQuery)}',
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SearchResult.fromJson(data);
    }
    return const SearchResult(
      total: 0,
      results: [],
      pagination: SearchPagination(page: 1, totalPages: 1, hasNext: false),
    );
  }

  @override
  Future<AnimeDetail> getAnimeDetail(String urlId) async {
    final cleanId = urlId.replaceAll(RegExp(r'/+$'), '').split('/').last;
    final response = await _apiClient.get('/anime/anime/$cleanId');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      final detailMap = data['data'] as Map<String, dynamic>;
      return AnimeDetail.fromJson(detailMap, slug: cleanId);
    }
    throw AppException('Detail anime tidak ditemukan.', type: ErrorType.parse);
  }

  @override
  Future<VideoStream> getVideoStream(String chapterUrlId, {String? reso}) async {
    final cleanSlug = chapterUrlId.replaceAll(RegExp(r'/+$'), '').split('/').last;
    final response = await _apiClient.get('/anime/episode/$cleanSlug');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      final epData = data['data'] as Map<String, dynamic>;

      final defaultEmbed = (epData['defaultStreamingUrl'] ?? '').toString();
      final serverMap = epData['server'] as Map<String, dynamic>?;
      final qualities = serverMap?['qualities'] as List? ?? [];

      final availableResos = <String>[];
      final sources = <StreamSource>[];

      for (final q in qualities) {
        if (q is Map<String, dynamic>) {
          final title = (q['title'] ?? '').toString().trim();
          if (title.isNotEmpty && !availableResos.contains(title)) {
            availableResos.add(title);
          }
          final serverList = q['serverList'] as List? ?? [];
          for (final s in serverList) {
            if (s is Map<String, dynamic>) {
              final sId = (s['serverId'] ?? '').toString();
              final sName = (s['title'] ?? '').toString().trim();
              if (sId.isNotEmpty) {
                sources.add(StreamSource(
                  reso: title,
                  link: '',
                  id: sId.hashCode,
                  serverId: sId,
                  serverName: sName,
                ));
              }
            }
          }
        }
      }

      // Determine target resolution to play
      String targetReso = reso ?? '720p';
      if (!availableResos.contains(targetReso)) {
        targetReso = availableResos.isNotEmpty ? availableResos.last : 'Default';
      }

      String targetUrl = '';

      // Try resolving servers for target resolution, prioritizing fast direct MP4 sources
      final matchSources = sources
          .where((s) => s.reso.toLowerCase() == targetReso.toLowerCase())
          .toList();

      matchSources.sort((a, b) {
        int score(StreamSource s) {
          final n = (s.serverName ?? '').toLowerCase();
          if (n.contains('od') || n.contains('cloud')) return 3;
          if (n.contains('arcg') || n.contains('archive')) return 2;
          if (n.contains('blog') || n.contains('stream')) return 1;
          return 0;
        }
        return score(b).compareTo(score(a));
      });

      for (final s in matchSources) {
        if (s.serverId != null && s.serverId!.isNotEmpty) {
          final serverUrl = await getServerUrl(s.serverId!);
          if (serverUrl.isNotEmpty) {
            final extracted = await _extractDirectMp4(serverUrl);
            if (extracted.isNotEmpty) {
              targetUrl = extracted;
              if (extracted.contains('.mp4')) break; // Successfully found direct mp4!
            }
          }
        }
      }

      // Fallback to defaultStreamingUrl if needed
      if ((targetUrl.isEmpty || !targetUrl.contains('.mp4')) && defaultEmbed.isNotEmpty) {
        final extractedDefault = await _extractDirectMp4(defaultEmbed);
        if (extractedDefault.contains('.mp4')) {
          targetUrl = extractedDefault;
        } else if (targetUrl.isEmpty) {
          targetUrl = extractedDefault;
        }
      }

      final finalPlayableUrl = targetUrl.isNotEmpty ? targetUrl : defaultEmbed;

      final resolvedSources = <StreamSource>[
        StreamSource(
          reso: targetReso,
          link: finalPlayableUrl,
          id: 0,
        ),
      ];

      return VideoStream(
        episodeId: 0,
        availableResolutions:
            availableResos.isNotEmpty ? availableResos : [targetReso],
        sources: resolvedSources,
        defaultUrl: finalPlayableUrl,
      );
    }
    throw AppException('Stream video tidak tersedia.', type: ErrorType.parse);
  }

  Future<String> _extractDirectMp4(String embedUrl) async {
    if (embedUrl.isEmpty) return '';
    if (embedUrl.toLowerCase().endsWith('.mp4')) return embedUrl;
    try {
      final dio = Dio();
      final res = await dio.get<String>(
        embedUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://otakudesu.blog/',
          },
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final body = res.data ?? '';

      // 1. const videoURL = "https://cdn.odcloud.net/...mp4"
      final match1 =
          RegExp(r'const\s+videoURL\s*=\s*["\x27]([^"\x27]+)["\x27]').firstMatch(body);
      if (match1 != null) return match1.group(1)!;

      // 2. file:"https://archive.org/...mp4"
      final match2 =
          RegExp(r'file\s*:\s*["\x27](https?://[^"\x27]+\.mp4)["\x27]').firstMatch(body);
      if (match2 != null) return match2.group(1)!;

      // 3. <source src="...mp4">
      final match3 = RegExp(
              r'<source\s+[^>]*src=["\x27](https?://[^"\x27]+\.mp4)["\x27]')
          .firstMatch(body);
      if (match3 != null) return match3.group(1)!;

      // 4. Any direct mp4 link in the page
      final match4 = RegExp(r'(https?://[^\s"<>]+\.mp4)').firstMatch(body);
      if (match4 != null) return match4.group(1)!;
    } catch (_) {}
    return embedUrl;
  }

  @override
  Future<String> getServerUrl(String serverId) async {
    try {
      final response = await _apiClient.get('/anime/server/$serverId');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return (data['data']['url'] ?? '').toString();
      }
    } catch (_) {}
    return '';
  }
}
