import 'package:dartz/dartz.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/entities/user_credentials.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../datasources/iptv_local_datasource.dart';
import '../datasources/iptv_remote_datasource.dart';

class IptvRepositoryImpl implements IptvRepository {
  final IptvRemoteDataSource remoteDataSource;
  final IptvLocalDataSource localDataSource;

  UserCredentials? _cachedCredentials;

  IptvRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<UserCredentials> _getCreds() async {
    if (_cachedCredentials != null) return _cachedCredentials!;
    final local = await localDataSource.getCredentials();
    if (local == null) throw AuthException('يجب تسجيل الدخول أولاً');
    _cachedCredentials = local;
    return local;
  }

  Future<Either<Failure, T>> _safeCall<T>(Future<T> Function() call) async {
    try {
      return Right(await call());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, UserCredentials>> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    return _safeCall(() async {
      final credentials = await remoteDataSource.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );
      await localDataSource.saveCredentials(credentials);
      _cachedCredentials = credentials;
      return credentials;
    });
  }

  @override
  Future<Either<Failure, UserCredentials?>> getSavedCredentials() async {
    return _safeCall(() async {
      final creds = await localDataSource.getCredentials();
      if (creds != null) _cachedCredentials = creds;
      return creds;
    });
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    return _safeCall(() async {
      await localDataSource.clearCredentials();
      _cachedCredentials = null;
      return unit;
    });
  }

  @override
  Future<Either<Failure, List<Category>>> getLiveCategories() async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getLiveCategories(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
      );
    });
  }

  @override
  Future<Either<Failure, List<LiveStream>>> getLiveStreams({String? categoryId}) async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getLiveStreams(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
        categoryId: categoryId,
      );
    });
  }

  @override
  Future<Either<Failure, List<EpgProgramme>>> getShortEpg(int streamId) async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getShortEpg(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
        streamId: streamId,
      );
    });
  }

  @override
  Future<Either<Failure, List<Category>>> getVodCategories() async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getVodCategories(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
      );
    });
  }

  @override
  Future<Either<Failure, List<Movie>>> getMovies({String? categoryId}) async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getMovies(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
        categoryId: categoryId,
      );
    });
  }

  @override
  Future<Either<Failure, Movie>> getMovieInfo(int movieId) async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getMovieInfo(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
        movieId: movieId,
      );
    });
  }

  @override
  Future<Either<Failure, List<Category>>> getSeriesCategories() async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getSeriesCategories(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
      );
    });
  }

  @override
  Future<Either<Failure, List<Series>>> getSeries({String? categoryId}) async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getSeries(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
        categoryId: categoryId,
      );
    });
  }

  @override
  Future<Either<Failure, Map<int, List<Episode>>>> getSeriesInfo(int seriesId) async {
    return _safeCall(() async {
      final creds = await _getCreds();
      return await remoteDataSource.getSeriesInfo(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
        seriesId: seriesId,
      );
    });
  }

  @override
  String buildLiveStreamUrl(int streamId) {
    final creds = _cachedCredentials!;
    return ApiEndpoints.liveStreamUrl(
      creds.serverUrl,
      creds.username,
      creds.password,
      streamId,
    );
  }

  @override
  String buildMovieStreamUrl(int streamId, String ext) {
    final creds = _cachedCredentials!;
    return ApiEndpoints.movieStreamUrl(
      creds.serverUrl,
      creds.username,
      creds.password,
      streamId,
      ext,
    );
  }

  @override
  String buildSeriesStreamUrl(int streamId, String ext) {
    final creds = _cachedCredentials!;
    return ApiEndpoints.seriesStreamUrl(
      creds.serverUrl,
      creds.username,
      creds.password,
      streamId,
      ext,
    );
  }
}
