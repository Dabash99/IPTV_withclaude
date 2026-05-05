import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart'; // for arrowRight02 back button
import '../../core/constants/app_colors.dart';
import '../../data/datasources/watch_history_datasource.dart';
import '../cubits/movies_cubit.dart';
import '../cubits/series_cubit.dart';
import '../cubits/watch_history_cubit.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<WatchHistoryCubit, WatchHistoryState>(
            builder: (context, historyState) {
              final items = historyState.items;
              final moviesState = context.read<MoviesCubit>().state;
              final seriesState = context.read<SeriesCubit>().state;
              final stats = _compute(items, moviesState, seriesState);

              return CustomScrollView(
                slivers: [
                  // Top bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40.w, height: 40.w,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Center(child: SDGAIcon(SDGAIconsStroke.arrowRight02, color: Colors.white, size: 18.sp)),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Text('stats.title'.tr(), style: TextStyle(color: AppColors.textPrimary, fontSize: 20.sp, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),

                  // Hero stat cards row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Expanded(child: _StatCard(
                            iconData: Icons.access_time,
                            label: 'stats.this_month'.tr(),
                            value: _formatHours(stats.monthlyMinutes),
                            color: AppColors.primary,
                          )),
                          SizedBox(width: 12.w),
                          Expanded(child: _StatCard(
                            iconData: Icons.play_circle_outline,
                            label: 'stats.all_time'.tr(),
                            value: _formatHours(stats.totalMinutes),
                            color: const Color(0xFF00F2FF),
                          )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h).asSliver,

                  // Breakdown row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Expanded(child: _StatCard(
                            iconData: Icons.video_library_outlined,
                            label: 'stats.series'.tr(),
                            value: '${stats.seriesCount}',
                            color: const Color(0xFF7B61FF),
                          )),
                          SizedBox(width: 12.w),
                          Expanded(child: _StatCard(
                            iconData: Icons.movie_outlined,
                            label: 'stats.movies'.tr(),
                            value: '${stats.moviesCount}',
                            color: AppColors.success,
                          )),
                          SizedBox(width: 12.w),
                          Expanded(child: _StatCard(
                            iconData: Icons.local_fire_department_outlined,
                            label: 'stats.streak'.tr(),
                            value: '${stats.streakDays}d',
                            color: AppColors.live,
                          )),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h).asSliver,

                  // Top genre
                  if (stats.topGenre != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.cardLight],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48.w, height: 48.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text('🎭', style: TextStyle(fontSize: 22.sp))),
                              ),
                              SizedBox(width: 14.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('stats.top_genre'.tr(), style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                                  SizedBox(height: 4.h),
                                  Text(stats.topGenre!, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 20.h).asSliver,

                  // Recently watched list
                  if (items.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                        child: _SectionHeader(prefix: 'stats.recent_prefix'.tr(), suffix: 'stats.recent_suffix'.tr()),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _HistoryTile(item: items[i]),
                        childCount: items.take(10).length,
                      ),
                    ),
                  ],
                  SizedBox(height: 100.h).asSliver,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  _Stats _compute(List<WatchHistoryItem> items, MoviesState moviesState, SeriesState seriesState) {
    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month);

    int totalSecs = 0;
    int monthlySecs = 0;
    int moviesCount = 0;
    int seriesCount = 0;

    for (final item in items) {
      final secs = item.progressSeconds ?? 0;
      totalSecs += secs;
      if (item.lastWatched.isAfter(firstOfMonth)) monthlySecs += secs;
      if (item.type == 'movie') moviesCount++;
      if (item.type == 'series') seriesCount++;
    }

    // Streak: consecutive days with activity
    final daysSeen = items.map((i) => DateTime(i.lastWatched.year, i.lastWatched.month, i.lastWatched.day)).toSet();
    int streak = 0;
    var day = DateTime(now.year, now.month, now.day);
    while (daysSeen.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    // Top genre: match history to movies/series
    final genreCount = <String, int>{};
    if (moviesState is MoviesLoaded) {
      final movieMap = {for (final m in moviesState.movies) m.streamId: m};
      for (final item in items.where((i) => i.type == 'movie')) {
        final movie = movieMap[item.id];
        if (movie?.genre?.isNotEmpty == true) {
          for (final g in movie!.genre!.split(',')) {
            final t = g.trim();
            if (t.isNotEmpty) genreCount[t] = (genreCount[t] ?? 0) + 1;
          }
        }
      }
    }
    if (seriesState is SeriesLoaded) {
      final seriesMap = {for (final s in seriesState.seriesList) s.seriesId: s};
      for (final item in items.where((i) => i.type == 'series')) {
        final series = seriesMap[item.id];
        if (series?.genre.isNotEmpty == true) {
          for (final g in series!.genre.split(',')) {
            final t = g.trim();
            if (t.isNotEmpty) genreCount[t] = (genreCount[t] ?? 0) + 1;
          }
        }
      }
    }

    String? topGenre;
    if (genreCount.isNotEmpty) {
      topGenre = genreCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    return _Stats(
      totalMinutes: totalSecs ~/ 60,
      monthlyMinutes: monthlySecs ~/ 60,
      moviesCount: moviesCount,
      seriesCount: seriesCount,
      streakDays: streak,
      topGenre: topGenre,
    );
  }

  static String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}

class _Stats {
  final int totalMinutes;
  final int monthlyMinutes;
  final int moviesCount;
  final int seriesCount;
  final int streakDays;
  final String? topGenre;

  const _Stats({
    required this.totalMinutes,
    required this.monthlyMinutes,
    required this.moviesCount,
    required this.seriesCount,
    required this.streakDays,
    required this.topGenre,
  });
}

// ── Widgets ────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData iconData;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.iconData, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.w, height: 34.w,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(child: Icon(iconData, color: color, size: 16.sp)),
          ),
          SizedBox(height: 10.h),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w800, height: 1)),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String prefix;
  final String suffix;
  const _SectionHeader({required this.prefix, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 15.sp, letterSpacing: 1, fontFamily: GoogleFonts.ibmPlexSansArabic().fontFamily),
        children: [
          TextSpan(text: '$prefix ', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w300)),
          TextSpan(text: suffix, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final WatchHistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: item.image.isEmpty
                  ? Container(width: 52.w, height: 52.w, color: AppColors.cardLight)
                  : CachedNetworkImage(
                imageUrl: item.image,
                width: 52.w, height: 52.w, fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(width: 52.w, height: 52.w, color: AppColors.cardLight),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4.h),
                  if (item.progress > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.r),
                      child: LinearProgressIndicator(
                        value: item.progress,
                        minHeight: 3.h,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                item.type == 'movie' ? 'stats.type_movie'.tr() : 'stats.type_series'.tr(),
                style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Widget {
  SliverToBoxAdapter get asSliver => SliverToBoxAdapter(child: this);
}
