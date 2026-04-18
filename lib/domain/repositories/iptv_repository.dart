import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user_credentials.dart';
import '../entities/category.dart';
import '../entities/stream_entities.dart';

abstract class IptvRepository {
  // Auth
  Future<Either<Failure, UserCredentials>> login({
    required String serverUrl,
    required String username,
    required String password,
  });
  Future<Either<Failure, UserCredentials?>> getSavedCredentials();
  Future<Either<Failure, Unit>> logout();

  // Live
  Future<Either<Failure, List<Category>>> getLiveCategories();
  Future<Either<Failure, List<LiveStream>>> getLiveStreams({String? categoryId});
  Future<Either<Failure, List<EpgProgramme>>> getShortEpg(int streamId);

  // Movies
  Future<Either<Failure, List<Category>>> getVodCategories();
  Future<Either<Failure, List<Movie>>> getMovies({String? categoryId});
  Future<Either<Failure, Movie>> getMovieInfo(int movieId);

  // Series
  Future<Either<Failure, List<Category>>> getSeriesCategories();
  Future<Either<Failure, List<Series>>> getSeries({String? categoryId});
  Future<Either<Failure, Map<int, List<Episode>>>> getSeriesInfo(int seriesId);

  // Stream URLs
  String buildLiveStreamUrl(int streamId);
  String buildMovieStreamUrl(int streamId, String ext);
  String buildSeriesStreamUrl(int streamId, String ext);
}
