import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/favorites_datasource.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../cubits/favorites_cubit.dart';
import '../widgets/app_logo.dart';
import '../widgets/common_widgets.dart';
import 'video_player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                child: Row(
                  children: [
                    const AppLogoHorizontal(),
                    const Spacer(),
                    SDGAIcon(
                      SDGAIconsBulk.favourite,
                      color: AppColors.error,
                      size: 22.sp,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 15.sp, letterSpacing: 1, fontFamily: 'Cairo'),
                    children: [
                      TextSpan(
                        text: 'MY ',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextSpan(
                        text: 'FAVORITES',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: 'Channels'),
                    Tab(text: 'Movies'),
                    Tab(text: 'Series'),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Expanded(
                child: BlocBuilder<FavoritesCubit, FavoritesState>(
                  builder: (ctx, state) {
                    final live = state.items.where((f) => f.type == FavoriteType.live).toList();
                    final movies = state.items.where((f) => f.type == FavoriteType.movie).toList();
                    final series = state.items.where((f) => f.type == FavoriteType.series).toList();
                    return TabBarView(
                      children: [
                        _FavList(items: live),
                        _FavGrid(items: movies, type: FavoriteType.movie),
                        _FavGrid(items: series, type: FavoriteType.series),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavList extends StatelessWidget {
  final List<FavoriteItem> items;
  const _FavList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyStateWidget(
        icon: SDGAIconsBulk.favourite,
        message: 'No favorite channels yet',
        subtitle: 'Tap the heart icon next to any channel',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) {
        final item = items[i];
        return Row(
          children: [
            Expanded(
              child: LiveStreamCard(
                name: item.name,
                icon: item.image,
                onTap: () {
                  final repo = context.read<IptvRepository>();
                  final url = repo.buildLiveStreamUrl(item.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        url: url,
                        title: item.name,
                        isLive: true,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 4.w),
            IconButton(
              icon: SDGAIcon(
                SDGAIconsBulk.favourite,
                color: AppColors.error,
                size: 20.sp,
              ),
              onPressed: () => context.read<FavoritesCubit>().toggle(item),
            ),
          ],
        );
      },
    );
  }
}

class _FavGrid extends StatelessWidget {
  final List<FavoriteItem> items;
  final FavoriteType type;
  const _FavGrid({required this.items, required this.type});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: type == FavoriteType.movie
            ? SDGAIconsBulk.video01
            : SDGAIconsBulk.folderLibrary,
        message: type == FavoriteType.movie
            ? 'No favorite movies yet'
            : 'No favorite series yet',
        subtitle: 'Tap ❤️ on the details page',
      );
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 0.6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return PosterCard(
          name: item.name,
          image: item.image,
          onTap: () {
            if (type == FavoriteType.movie && item.extension != null) {
              final repo = context.read<IptvRepository>();
              final url = repo.buildMovieStreamUrl(item.id, item.extension!);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(
                    url: url,
                    title: item.name,
                    isLive: false,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
