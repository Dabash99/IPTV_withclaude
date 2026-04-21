import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/watch_history_datasource.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../cubits/movies_cubit.dart';
import '../cubits/series_cubit.dart';
import '../cubits/watch_history_cubit.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_logo.dart';
import '../widgets/poster_backdrop.dart';
import 'home_screen.dart';
import 'movie_details_screen.dart';
import 'series_screen.dart';
import 'video_player_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = 'new'; // 'new' | 'recently'
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<MoviesCubit>().state is MoviesInitial) {
        context.read<MoviesCubit>().loadData();
      }
      if (context.read<SeriesCubit>().state is SeriesInitial) {
        context.read<SeriesCubit>().loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: AppDrawer(
        onNavigate: (index) =>
            HomeTabController.of(context)?.switchTab(index),
      ),
      body: Stack(
        children: [
          // Subtle poster backdrop in top area
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340.h,
            child: BlocBuilder<MoviesCubit, MoviesState>(
              builder: (_, state) {
                final posters = state is MoviesLoaded
                    ? state.movies
                    .where((m) => m.streamIcon.isNotEmpty)
                    .take(9)
                    .map((m) => m.streamIcon)
                    .toList()
                    : <String>[];
                return PosterBackdrop(
                  posters: posters,
                  blurSigma: 30,
                  overlayOpacity: 0.7,
                );
              },
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App bar with logo + actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    child: Row(
                      children: [
                        _RoundIconButton(
                          icon: SDGAIconsStroke.menu02,
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        SizedBox(width: 12.w),
                        const AppLogoHorizontal(),
                        const Spacer(),
                        _RoundIconButton(
                          icon: SDGAIconsStroke.settings02,
                          onTap: () =>
                              HomeTabController.of(context)?.switchTab(5),
                        ),
                        SizedBox(width: 8.w),
                        _RoundIconButton(
                          icon: SDGAIconsStroke.search02,
                          onTap: () {
                            // Jump to movies tab (which has search)
                            HomeTabController.of(context)?.switchTab(2);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Keep Watching section
                SliverToBoxAdapter(
                  child: BlocBuilder<WatchHistoryCubit, WatchHistoryState>(
                    builder: (context, historyState) {
                      if (historyState.items.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            prefix: 'KEEP',
                            suffix: 'WATCHING',
                          ),
                          SizedBox(height: 14.h),
                          SizedBox(
                            height: 220.h,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              itemCount: historyState.items.length,
                              separatorBuilder: (_, __) => SizedBox(width: 12.w),
                              itemBuilder: (_, i) {
                                final item = historyState.items[i];
                                return _KeepWatchingCard(
                                  item: item,
                                  onTap: () => _playHistoryItem(context, item),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 28.h),
                        ],
                      );
                    },
                  ),
                ),

                // New Movies section
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SectionTitle(prefix: 'NEW', suffix: 'MOVIES'),
                            _FilterToggle(
                              selected: _filter,
                              onChanged: (v) => setState(() => _filter = v),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      BlocBuilder<MoviesCubit, MoviesState>(
                        builder: (context, state) {
                          if (state is MoviesLoading || state is MoviesInitial) {
                            return _buildShimmerRow();
                          }
                          if (state is MoviesLoaded) {
                            final movies = state.movies.take(20).toList();
                            if (_filter == 'recently') {
                              movies.sort((a, b) => b.streamId.compareTo(a.streamId));
                            }
                            if (movies.isEmpty) {
                              return Padding(
                                padding: EdgeInsets.all(32.w),
                                child: Center(
                                  child: Text(
                                    'No movies available',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return SizedBox(
                              height: 210.h,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemCount: movies.length,
                                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                                itemBuilder: (_, i) => _PosterThumb(
                                  name: movies[i].name,
                                  image: movies[i].streamIcon,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailsScreen(movie: movies[i]),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      SizedBox(height: 28.h),
                    ],
                  ),
                ),

                // New Series section
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _SectionTitle(prefix: 'NEW', suffix: 'SERIES'),
                      ),
                      SizedBox(height: 14.h),
                      BlocBuilder<SeriesCubit, SeriesState>(
                        builder: (context, state) {
                          if (state is SeriesLoaded) {
                            final list = state.seriesList.take(20).toList();
                            if (list.isEmpty) return const SizedBox.shrink();
                            return SizedBox(
                              height: 210.h,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemCount: list.length,
                                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                                itemBuilder: (_, i) => _PosterThumb(
                                  name: list[i].name,
                                  image: list[i].cover,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SeriesDetailsScreen(series: list[i]),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          if (state is SeriesLoading || state is SeriesInitial) {
                            return _buildShimmerRow();
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerRow() {
    return SizedBox(
      height: 210.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: 5,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.cardLight,
          highlightColor: AppColors.surface,
          child: Container(
            width: 130.w,
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
        ),
      ),
    );
  }

  void _playHistoryItem(BuildContext context, WatchHistoryItem item) {
    final repo = context.read<IptvRepository>();
    final url = item.type == 'movie' && item.extension != null
        ? repo.buildMovieStreamUrl(item.id, item.extension!)
        : repo.buildSeriesStreamUrl(item.id, item.extension ?? 'mp4');
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
}

// ============ Section Title ============
class _SectionTitle extends StatelessWidget {
  final String prefix;
  final String suffix;
  const _SectionTitle({required this.prefix, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 15.sp,
            letterSpacing: 1,
            fontFamily: 'Cairo',
          ),
          children: [
            TextSpan(
              text: '$prefix ',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w300,
              ),
            ),
            TextSpan(
              text: suffix,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Round Icon Button ============
class _RoundIconButton extends StatelessWidget {
  final SDGAIconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Center(
          child: SDGAIcon(icon, color: Colors.white, size: 18.sp),
        ),
      ),
    );
  }
}

// ============ Filter Toggle (New / Recently) ============
class _FilterToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill('New', 'new'),
          _pill('Recently', 'recently'),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    final isActive = selected == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cardLight : Colors.transparent,
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textMuted,
            fontSize: 11.sp,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============ Keep Watching Card ============
class _KeepWatchingCard extends StatelessWidget {
  final WatchHistoryItem item;
  final VoidCallback onTap;

  const _KeepWatchingCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: item.image.isEmpty
                            ? Container(color: AppColors.cardLight)
                            : CachedNetworkImage(
                          imageUrl: item.image,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.cardLight),
                        ),
                      ),
                    ),
                  ),
                  // Play overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: SDGAIcon(
                            SDGAIconsBulk.play,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Progress bar
                  if (item.progress > 0)
                    Positioned(
                      left: 8.w,
                      right: 8.w,
                      bottom: 8.h,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2.r),
                        child: LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 3.h,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Poster Thumbnail ============
class _PosterThumb extends StatelessWidget {
  final String name;
  final String image;
  final VoidCallback onTap;

  const _PosterThumb({
    required this.name,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 125.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: image.isEmpty
                      ? Container(color: AppColors.cardLight)
                      : CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.cardLight),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.cardLight),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
