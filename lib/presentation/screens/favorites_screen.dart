import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/favorites_datasource.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../cubits/favorites_cubit.dart';
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
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: Row(
                  children: [
                    Text(
                      'المفضلة',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'قنوات'),
                    Tab(text: 'أفلام'),
                    Tab(text: 'مسلسلات'),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<FavoritesCubit, FavoritesState>(
                  builder: (ctx, state) {
                    final live = state.items.where((f) => f.type == FavoriteType.live).toList();
                    final movies = state.items.where((f) => f.type == FavoriteType.movie).toList();
                    final series = state.items.where((f) => f.type == FavoriteType.series).toList();

                    return TabBarView(
                      children: [
                        _FavList(items: live, type: FavoriteType.live),
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
  final FavoriteType type;
  const _FavList({required this.items, required this.type});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyFav();
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, i) {
        final item = items[i];
        return LiveStreamCard(
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
    if (items.isEmpty) return const _EmptyFav();
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 14.h,
        childAspectRatio: 0.62,
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

class _EmptyFav extends StatelessWidget {
  const _EmptyFav();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, color: AppColors.textMuted, size: 56.sp),
          SizedBox(height: 12.h),
          Text(
            'مفيش حاجة في المفضلة لسه',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}
