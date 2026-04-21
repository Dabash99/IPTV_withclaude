import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/constants/app_colors.dart';
import 'domain/repositories/iptv_repository.dart';
import 'injector.dart';
import 'presentation/cubits/auth_cubit.dart';
import 'presentation/cubits/favorites_cubit.dart';
import 'presentation/cubits/live_cubit.dart';
import 'presentation/cubits/movies_cubit.dart';
import 'presentation/cubits/series_cubit.dart';
import 'presentation/cubits/watch_history_cubit.dart';
import 'presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInjector.init();
  runApp(const MyApp());
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
      builder: (_, __) => MultiRepositoryProvider(
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
          ],
          child: MaterialApp(
            title: 'ABC IPTV Player',
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
