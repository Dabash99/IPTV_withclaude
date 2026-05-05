import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/constants/app_colors.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await AppInjector.init();
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
              fontFamily: 'Cairo',
            ),
            home: const SplashScreen(),
          ),
        ),
      ),
    );
  }
}
