import 'dart:convert';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'core/constants/api_endpoints.dart';
import 'core/constants/app_colors.dart';
import 'core/network/dio_helper.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/episode_tracker_datasource.dart';
import 'data/datasources/favorites_datasource.dart';
import 'data/datasources/iptv_remote_datasource.dart';
import 'domain/repositories/iptv_repository.dart';
import 'injector.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/downloads_cubit.dart';
import 'presentation/cubits/favorites_cubit.dart';
import 'presentation/cubits/live_cubit.dart';
import 'presentation/cubits/movies_cubit.dart';
import 'presentation/cubits/series_cubit.dart';
import 'presentation/cubits/watch_history_cubit.dart';
import 'presentation/screens/splash_screen.dart';

const _kEpisodeCheckTask = 'newEpisodeCheck';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != _kEpisodeCheckTask) return true;
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize notification channel first
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await FlutterLocalNotificationsPlugin()
          .initialize(const InitializationSettings(android: androidInit));
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            'new_episodes',
            'New Episodes',
            importance: Importance.high,
          ));

      // Read credentials from secure storage
      const storage = FlutterSecureStorage();
      final credJson = await storage.read(key: StorageKeys.userInfo);
      if (credJson == null) return true;

      final cred = jsonDecode(credJson) as Map<String, dynamic>;
      final serverUrl = cred['server_url'] as String? ?? '';
      final username = cred['username'] as String? ?? '';
      final password = cred['password'] as String? ?? '';
      if (serverUrl.isEmpty) return true;

      final prefs = await SharedPreferences.getInstance();
      final favDs = FavoritesDataSource(prefs);
      final trackerDs = EpisodeTrackerDataSource(prefs);
      final remote = IptvRemoteDataSourceImpl(DioHelper());

      final isArabic =
          ui.PlatformDispatcher.instance.locale.languageCode == 'ar';
      final seriesFavs = favDs.getByType(FavoriteType.series);

      for (final fav in seriesFavs) {
        try {
          final seasons = await remote.getSeriesInfo(
            serverUrl: serverUrl,
            username: username,
            password: password,
            seriesId: fav.id,
          );
          final total =
              seasons.values.fold(0, (sum, eps) => sum + eps.length);
          final known = trackerDs.getKnownCount(fav.id);

          if (known < 0) {
            // First sync — set baseline without notifying
            await trackerDs.setKnownCount(fav.id, total);
          } else if (total > known) {
            await NotificationService.showNewEpisode(
              notificationId: fav.id,
              seriesName: fav.name,
              newCount: total - known,
              isArabic: isArabic,
            );
            await trackerDs.setKnownCount(fav.id, total);
          }
          // Small delay between API calls to be polite to the server
          await Future.delayed(const Duration(milliseconds: 400));
        } catch (_) {
          // Skip this series on error; try the rest
        }
      }

      await trackerDs.prune(seriesFavs.map((f) => f.id).toSet());
    } catch (_) {}
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppInjector.init();

  await NotificationService.init();
  await NotificationService.requestPermission();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    _kEpisodeCheckTask,
    _kEpisodeCheckTask,
    frequency: const Duration(hours: 6),
    existingWorkPolicy: ExistingWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final inj = AppInjector.I;

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => MultiRepositoryProvider(
        providers: [
          RepositoryProvider<IptvRepository>.value(value: inj.repository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthCubit(
                loginUseCase: inj.loginUseCase,
                getSavedCredentialsUseCase: inj.getSavedCredentialsUseCase,
                logoutUseCase: inj.logoutUseCase,
              ),
            ),
            BlocProvider(
              create: (_) => LiveCubit(
                getCategoriesUseCase: inj.getLiveCategoriesUseCase,
                getStreamsUseCase: inj.getLiveStreamsUseCase,
                getEpgUseCase: inj.getShortEpgUseCase,
              ),
            ),
            BlocProvider(
              create: (_) => MoviesCubit(
                getCategoriesUseCase: inj.getVodCategoriesUseCase,
                getMoviesUseCase: inj.getMoviesUseCase,
              ),
            ),
            BlocProvider(
              create: (_) => SeriesCubit(
                getCategoriesUseCase: inj.getSeriesCategoriesUseCase,
                getSeriesUseCase: inj.getSeriesUseCase,
                getSeriesInfoUseCase: inj.getSeriesInfoUseCase,
              ),
            ),
            BlocProvider(
              create: (_) => FavoritesCubit(inj.favoritesDataSource),
            ),
            BlocProvider(
              create: (_) => WatchHistoryCubit(inj.watchHistoryDataSource),
            ),
            BlocProvider(
              create: (_) => DownloadsCubit(inj.downloadsDataSource),
            ),
          ],
          child: MaterialApp(
            title: 'Volex IPTV Player',
            debugShowCheckedModeBanner: false,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.accent,
                surface: AppColors.surface,
                error: AppColors.error,
              ),
              fontFamily: 'IBMPlexSansArabic',
            ),
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
