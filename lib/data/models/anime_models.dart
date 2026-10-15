/// Data models for YUKINIME Anime Streaming Application
library;

class AnimeLatest {
  final int id;
  final String url;
  final String judul;
  final String cover;
  final String lastch;
  final String lastup;

  const AnimeLatest({
    required this.id,
    required this.url,
    required this.judul,
    required this.cover,
    required this.lastch,
    required this.lastup,
  });

  factory AnimeLatest.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['animeId'] ?? json['url'] ?? '').toString();
    final cleanUrl = rawUrl.replaceAll(RegExp(r'/+$'), '').split('/').last;
    final epNum = json['episodes'];
    final lastchStr = epNum != null ? 'Ep $epNum' : (json['lastch'] ?? '').toString();
    final lastupStr = (json['latestReleaseDate'] ?? json['releaseDay'] ?? json['lastup'] ?? '').toString();

    return AnimeLatest(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? cleanUrl.hashCode,
      url: cleanUrl,
      judul: (json['title'] ?? json['judul'] ?? '').toString(),
      cover: (json['poster'] ?? json['cover'] ?? '').toString(),
      lastch: lastchStr,
      lastup: lastupStr,
    );
  }
}

class AnimeRecommended {
  final String id;
  final String url;
  final String judul;
  final String cover;
  final List<String> genre;
  final String sinopsis;
  final String studio;
  final String score;
  final String status;
  final String rilis;
  final int totalEpisode;

  const AnimeRecommended({
    required this.id,
    required this.url,
    required this.judul,
    required this.cover,
    required this.genre,
    required this.sinopsis,
    required this.studio,
    required this.score,
    required this.status,
    required this.rilis,
    required this.totalEpisode,
  });

  factory AnimeRecommended.fromJson(Map<String, dynamic> json) {
    final rawUrl = (json['animeId'] ?? json['url'] ?? json['id'] ?? '').toString();
    final cleanUrl = rawUrl.replaceAll(RegExp(r'/+$'), '').split('/').last;

    // Genres parsing (supports List of Maps or List of Strings)
    final List<String> genres = [];
    if (json['genreList'] is List) {
      for (final g in json['genreList']) {
        if (g is Map && g['title'] != null) {
          genres.add(g['title'].toString());
        } else if (g != null) {
          genres.add(g.toString());
        }
      }
    } else if (json['genre'] is List) {
      for (final g in json['genre']) {
        if (g != null) genres.add(g.toString());
      }
    }

    // Synopsis parsing
    String synopsisText = '';
    if (json['synopsis'] is Map && json['synopsis']['paragraphs'] is List) {
      synopsisText = (json['synopsis']['paragraphs'] as List).join('\n\n');
    } else if (json['sinopsis'] != null) {
      synopsisText = json['sinopsis'].toString();
    }

    final eps = json['episodes'] ?? json['total_episode'];
    final totalEps = eps is int ? eps : int.tryParse('$eps') ?? 0;

    return AnimeRecommended(
      id: cleanUrl,
      url: cleanUrl,
      judul: (json['title'] ?? json['judul'] ?? '').toString(),
      cover: (json['poster'] ?? json['cover'] ?? '').toString(),
      genre: genres,
      sinopsis: synopsisText,
      studio: (json['studios'] ?? json['studio'] ?? 'Otakudesu').toString(),
      score: (json['score'] ?? '0').toString(),
      status: (json['status'] ?? 'Completed').toString(),
      rilis: (json['latestReleaseDate'] ?? json['lastReleaseDate'] ?? json['aired'] ?? json['rilis'] ?? '').toString(),
      totalEpisode: totalEps,
    );
  }
}

class AnimeDetail {
  final int id;
  final String seriesId;
  final String cover;
  final String judul;
  final String type;
  final String status;
  final String rating;
  final String published;
  final String author; // Studio
  final List<String> genre;
  final String sinopsis;
  final List<Chapter> chapters;

  const AnimeDetail({
    required this.id,
    required this.seriesId,
    required this.cover,
    required this.judul,
    required this.type,
    required this.status,
    required this.rating,
    required this.published,
    required this.author,
    required this.genre,
    required this.sinopsis,
    required this.chapters,
  });

  /// Returns chapters in ascending order (episode 1 first)
  List<Chapter> get sortedChapters {
    final sorted = List<Chapter>.from(chapters);
    sorted.sort((a, b) {
      final aNum = a.episodeNumber;
      final bNum = b.episodeNumber;
      return aNum.compareTo(bNum);
    });
    return sorted;
  }

  int get totalEpisodes => chapters.length;

  factory AnimeDetail.fromJson(Map<String, dynamic> json, {String slug = ''}) {
    final title = (json['title'] ?? json['judul'] ?? '').toString();
    final poster = (json['poster'] ?? json['cover'] ?? '').toString();
    final type = (json['type'] ?? 'TV').toString();
    final status = (json['status'] ?? 'Ongoing').toString();
    final score = (json['score'] ?? json['rating'] ?? '0').toString();
    final aired = (json['aired'] ?? json['published'] ?? '').toString();
    final studios = (json['studios'] ?? json['author'] ?? 'Otakudesu').toString();

    // Genres
    final List<String> genres = [];
    if (json['genreList'] is List) {
      for (final g in json['genreList']) {
        if (g is Map && g['title'] != null) {
          genres.add(g['title'].toString());
        } else if (g != null) {
          genres.add(g.toString());
        }
      }
    } else if (json['genre'] is List) {
      for (final g in json['genre']) {
        if (g != null) genres.add(g.toString());
      }
    }

    // Synopsis
    String synopsisText = '';
    if (json['synopsis'] is Map && json['synopsis']['paragraphs'] is List) {
      synopsisText = (json['synopsis']['paragraphs'] as List).join('\n\n');
    } else if (json['sinopsis'] != null) {
      synopsisText = json['sinopsis'].toString();
    }

    // Chapters / Episodes
    final chaptersList = <Chapter>[];
    final rawEpisodes = json['episodeList'] ?? json['chapter'];
    if (rawEpisodes is List) {
      for (final ep in rawEpisodes) {
        if (ep is Map<String, dynamic>) {
          chaptersList.add(Chapter.fromJson(ep));
        }
      }
    }

    return AnimeDetail(
      id: json['id'] is int ? json['id'] : slug.hashCode,
      seriesId: slug.isNotEmpty ? slug : (json['series_id'] ?? json['animeId'] ?? '').toString(),
      cover: poster,
      judul: title,
      type: type,
      status: status,
      rating: score,
      published: aired,
      author: studios,
      genre: genres,
      sinopsis: synopsisText,
      chapters: chaptersList,
    );
  }
}

class Chapter {
  final int id;
  final String ch;
  final String url; // chapterUrlId / episode slug for video
  final String date;
  final int views;
  final String? customTitle;

  const Chapter({
    required this.id,
    required this.ch,
    required this.url,
    required this.date,
    required this.views,
    this.customTitle,
  });

  /// Extract the episode number from the ch string
  int get episodeNumber {
    final match = RegExp(r'(\d+)').firstMatch(ch);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Clean display title
  String get displayTitle {
    if (customTitle != null && customTitle!.isNotEmpty) {
      final match = RegExp(r'Episode\s+(\d+)', caseSensitive: false).firstMatch(customTitle!);
      if (match != null) {
        return 'Episode ${match.group(1)}';
      }
    }
    return ch.isNotEmpty ? 'Episode $ch' : (customTitle ?? 'Episode');
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final epId = (json['episodeId'] ?? json['url'] ?? '').toString().replaceAll(RegExp(r'/+$'), '').split('/').last;
    final eps = json['eps'] ?? json['ch'] ?? '';
    final title = (json['title'] ?? '').toString();

    return Chapter(
      id: json['id'] is int ? json['id'] : epId.hashCode,
      ch: eps.toString(),
      url: epId,
      date: (json['date'] ?? '').toString(),
      views: json['views'] is int ? json['views'] : int.tryParse('${json['views']}') ?? 0,
      customTitle: title,
    );
  }
}

class VideoStream {
  final int episodeId;
  final List<String> availableResolutions;
  final List<StreamSource> sources;
  final String defaultUrl;

  const VideoStream({
    required this.episodeId,
    required this.availableResolutions,
    required this.sources,
    this.defaultUrl = '',
  });

  /// Get the best quality source
  StreamSource? get bestQuality {
    if (sources.isEmpty) return null;
    final hd720 = sources.where((s) => s.reso == '720p' && s.link.isNotEmpty).firstOrNull;
    if (hd720 != null) return hd720;
    final sd480 = sources.where((s) => s.reso == '480p' && s.link.isNotEmpty).firstOrNull;
    if (sd480 != null) return sd480;
    final auto = sources.where((s) => s.link.isNotEmpty).firstOrNull;
    return auto ?? sources.first;
  }

  StreamSource? getByResolution(String reso) {
    return sources.where((s) => s.reso == reso && s.link.isNotEmpty).firstOrNull;
  }

  factory VideoStream.fromJson(Map<String, dynamic> json) {
    final defaultStreamingUrl = (json['defaultStreamingUrl'] ?? '').toString();
    final sources = <StreamSource>[];
    final resos = <String>[];

    if (defaultStreamingUrl.isNotEmpty) {
      sources.add(StreamSource(
        reso: 'Default',
        link: defaultStreamingUrl,
        id: 0,
      ));
      resos.add('Default');
    }

    final serverMap = json['server'] as Map<String, dynamic>?;
    final qualities = serverMap?['qualities'] as List? ?? [];
    for (final q in qualities) {
      if (q is Map<String, dynamic>) {
        final title = (q['title'] ?? '').toString().trim();
        if (title.isNotEmpty && !resos.contains(title)) {
          resos.add(title);
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

    // Fallback if older Sansekai format
    if (sources.isEmpty && json['stream'] is List) {
      for (final s in json['stream'] as List) {
        if (s is Map<String, dynamic>) {
          sources.add(StreamSource.fromJson(s));
        }
      }
    }

    return VideoStream(
      episodeId: json['episode_id'] ?? 0,
      availableResolutions: resos.isNotEmpty ? resos : ['Default'],
      sources: sources,
      defaultUrl: defaultStreamingUrl,
    );
  }
}

class StreamSource {
  final String reso;
  final String link;
  final int id;
  final String? serverId;
  final String? serverName;

  const StreamSource({
    required this.reso,
    required this.link,
    required this.id,
    this.serverId,
    this.serverName,
  });

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    return StreamSource(
      reso: (json['reso'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      serverId: json['serverId']?.toString(),
      serverName: json['serverName']?.toString(),
    );
  }
}

class SearchResult {
  final int total;
  final List<AnimeRecommended> results;
  final SearchPagination pagination;

  const SearchResult({
    required this.total,
    required this.results,
    required this.pagination,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final List<AnimeRecommended> list = [];
    final rawData = json['data'];

    if (rawData is Map<String, dynamic> && rawData['animeList'] is List) {
      for (final item in rawData['animeList'] as List) {
        if (item is Map<String, dynamic>) {
          list.add(AnimeRecommended.fromJson(item));
        }
      }
    } else if (rawData is List) {
      final firstData = rawData.isNotEmpty ? rawData.first : json;
      if (firstData is Map<String, dynamic> && firstData['result'] is List) {
        for (final item in firstData['result'] as List) {
          if (item is Map<String, dynamic>) {
            list.add(AnimeRecommended.fromJson(item));
          }
        }
      }
    }

    return SearchResult(
      total: list.length,
      results: list,
      pagination: const SearchPagination(page: 1, totalPages: 1, hasNext: false),
    );
  }
}

class SearchPagination {
  final int page;
  final int totalPages;
  final bool hasNext;

  const SearchPagination({
    required this.page,
    required this.totalPages,
    required this.hasNext,
  });

  factory SearchPagination.fromJson(Map<String, dynamic> json) {
    return SearchPagination(
      page: json['page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      hasNext: json['has_next'] ?? false,
    );
  }
}
