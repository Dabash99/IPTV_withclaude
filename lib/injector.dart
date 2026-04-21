import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/dio_helper.dart';
import 'data/datasources/favorites_datasource.dart';
import 'data/datasources/iptv_local_datasource.dart';
import 'data/datasources/iptv_remote_datasource.dart';
import 'data/datasources/watch_history_datasource.dart';
import 'data/repositories/iptv_repository_impl.dart';
import 'domain/repositories/iptv_repository.dart';
import 'domain/usecases/usecases.dart';

class AppInjector {
  AppInjector._();
  static late final AppInjector I;

  late final DioHelper dioHelper;
  late final FlutterSecureStorage secureStorage;
  late final SharedPreferences sharedPreferences;
  late final IptvRemoteDataSource remoteDataSource;
  late final IptvLocalDataSource localDataSource;
  late final FavoritesDataSource favoritesDataSource;
  late final WatchHistoryDataSource watchHistoryDataSource;
  late final IptvRepository repository;

  late final LoginUseCase loginUseCase;
  late final GetSavedCredentialsUseCase getSavedCredentialsUseCase;
  late final LogoutUseCase logoutUseCase;
  late final GetLiveCategoriesUseCase getLiveCategoriesUseCase;
  late final GetLiveStreamsUseCase getLiveStreamsUseCase;
  late final GetShortEpgUseCase getShortEpgUseCase;
  late final GetVodCategoriesUseCase getVodCategoriesUseCase;
  late final GetMoviesUseCase getMoviesUseCase;
  late final GetSeriesCategoriesUseCase getSeriesCategoriesUseCase;
  late final GetSeriesUseCase getSeriesUseCase;
  late final GetSeriesInfoUseCase getSeriesInfoUseCase;

  static Future<void> init() async {
    final injector = AppInjector._();

    injector.dioHelper = DioHelper();
    injector.secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    injector.sharedPreferences = await SharedPreferences.getInstance();

    injector.remoteDataSource = IptvRemoteDataSourceImpl(injector.dioHelper);
    injector.localDataSource = IptvLocalDataSourceImpl(injector.secureStorage);
    injector.favoritesDataSource = FavoritesDataSource(injector.sharedPreferences);
    injector.watchHistoryDataSource = WatchHistoryDataSource(injector.sharedPreferences);

    injector.repository = IptvRepositoryImpl(
      remoteDataSource: injector.remoteDataSource,
      localDataSource: injector.localDataSource,
    );

    injector.loginUseCase = LoginUseCase(injector.repository);
    injector.getSavedCredentialsUseCase = GetSavedCredentialsUseCase(injector.repository);
    injector.logoutUseCase = LogoutUseCase(injector.repository);
    injector.getLiveCategoriesUseCase = GetLiveCategoriesUseCase(injector.repository);
    injector.getLiveStreamsUseCase = GetLiveStreamsUseCase(injector.repository);
    injector.getShortEpgUseCase = GetShortEpgUseCase(injector.repository);
    injector.getVodCategoriesUseCase = GetVodCategoriesUseCase(injector.repository);
    injector.getMoviesUseCase = GetMoviesUseCase(injector.repository);
    injector.getSeriesCategoriesUseCase = GetSeriesCategoriesUseCase(injector.repository);
    injector.getSeriesUseCase = GetSeriesUseCase(injector.repository);
    injector.getSeriesInfoUseCase = GetSeriesInfoUseCase(injector.repository);

    I = injector;
  }
}
