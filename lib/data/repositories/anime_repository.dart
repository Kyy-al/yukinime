import '../datasources/remote/anime_remote_data_source.dart';
import '../models/anime_models.dart';

class AnimeRepository {
  final AnimeRemoteDataSource _remoteDataSource;

  AnimeRepository({AnimeRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? AnimeRemoteDataSourceImpl();

  Future<List<AnimeLatest>> getLatestAnime() => _remoteDataSource.getLatestAnime();

  Future<List<AnimeRecommended>> getRecommendedAnime({int page = 1}) =>
      _remoteDataSource.getRecommendedAnime(page: page);

  Future<List<AnimeRecommended>> getMovies() => _remoteDataSource.getMovies();

  Future<SearchResult> searchAnime(String query) =>
      _remoteDataSource.searchAnime(query);

  Future<AnimeDetail> getAnimeDetail(String urlId) =>
      _remoteDataSource.getAnimeDetail(urlId);

  Future<VideoStream> getVideoStream(String chapterUrlId, {String? reso}) =>
      _remoteDataSource.getVideoStream(chapterUrlId, reso: reso);

  Future<String> getServerUrl(String serverId) =>
      _remoteDataSource.getServerUrl(serverId);
}
