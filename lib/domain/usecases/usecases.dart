import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/category.dart';
import '../entities/stream_entities.dart';
import '../entities/user_credentials.dart';
import '../repositories/iptv_repository.dart';

// Auth
class LoginUseCase {
  final IptvRepository repository;
  LoginUseCase(this.repository);

  Future<Either<Failure, UserCredentials>> call({
    required String serverUrl,
    required String username,
    required String password,
  }) =>
      repository.login(serverUrl: serverUrl, username: username, password: password);
}

class GetSavedCredentialsUseCase {
  final IptvRepository repository;
  GetSavedCredentialsUseCase(this.repository);

  Future<Either<Failure, UserCredentials?>> call() => repository.getSavedCredentials();
}

class LogoutUseCase {
  final IptvRepository repository;
  LogoutUseCase(this.repository);

  Future<Either<Failure, Unit>> call() => repository.logout();
}

// Live
class GetLiveCategoriesUseCase {
  final IptvRepository repository;
  GetLiveCategoriesUseCase(this.repository);

  Future<Either<Failure, List<Category>>> call() => repository.getLiveCategories();
}

class GetLiveStreamsUseCase {
  final IptvRepository repository;
  GetLiveStreamsUseCase(this.repository);

  Future<Either<Failure, List<LiveStream>>> call({String? categoryId}) =>
      repository.getLiveStreams(categoryId: categoryId);
}

class GetShortEpgUseCase {
  final IptvRepository repository;
  GetShortEpgUseCase(this.repository);

  Future<Either<Failure, List<EpgProgramme>>> call(int streamId) =>
      repository.getShortEpg(streamId);
}

// Movies
class GetVodCategoriesUseCase {
  final IptvRepository repository;
  GetVodCategoriesUseCase(this.repository);

  Future<Either<Failure, List<Category>>> call() => repository.getVodCategories();
}

class GetMoviesUseCase {
  final IptvRepository repository;
  GetMoviesUseCase(this.repository);

  Future<Either<Failure, List<Movie>>> call({String? categoryId}) =>
      repository.getMovies(categoryId: categoryId);
}

// Series
class GetSeriesCategoriesUseCase {
  final IptvRepository repository;
  GetSeriesCategoriesUseCase(this.repository);

  Future<Either<Failure, List<Category>>> call() => repository.getSeriesCategories();
}

class GetSeriesUseCase {
  final IptvRepository repository;
  GetSeriesUseCase(this.repository);

  Future<Either<Failure, List<Series>>> call({String? categoryId}) =>
      repository.getSeries(categoryId: categoryId);
}

class GetSeriesInfoUseCase {
  final IptvRepository repository;
  GetSeriesInfoUseCase(this.repository);

  Future<Either<Failure, Map<int, List<Episode>>>> call(int seriesId) =>
      repository.getSeriesInfo(seriesId);
}
