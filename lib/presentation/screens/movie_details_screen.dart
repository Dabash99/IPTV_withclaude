import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/favorites_datasource.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../cubits/favorites_cubit.dart';
import 'video_player_screen.dart';

class MovieDetailsScreen extends StatelessWidget {
  final Movie movie;
  const MovieDetailsScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            expandedHeight: 320.h,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (ctx, _) {
                  final cubit = ctx.read<FavoritesCubit>();
                  final isFav = cubit.isFavorite(movie.streamId, FavoriteType.movie);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? AppColors.error : Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: () => cubit.toggle(FavoriteItem(
                      id: movie.streamId,
                      name: movie.name,
                      image: movie.streamIcon,
                      type: FavoriteType.movie,
                      extension: movie.containerExtension,
                    )),
                  );
                },
              ),
              SizedBox(width: 8.w),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  movie.streamIcon.isEmpty
                      ? Container(color: AppColors.cardLight)
                      : CachedNetworkImage(
                    imageUrl: movie.streamIcon,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: AppColors.cardLight),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withOpacity(0.7),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 6.h,
                    children: [
                      if (movie.rating > 0)
                        _Chip(
                          icon: Icons.star,
                          iconColor: AppColors.warning,
                          label: movie.rating.toStringAsFixed(1),
                        ),
                      if (movie.releaseDate?.isNotEmpty == true)
                        _Chip(icon: Icons.calendar_today, label: movie.releaseDate!),
                      if (movie.durationSecs != null && movie.durationSecs! > 0)
                        _Chip(
                          icon: Icons.schedule,
                          label: '${(movie.durationSecs! / 60).round()} دقيقة',
                        ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Play button
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.play_arrow_rounded, size: 26.sp),
                      label: Text(
                        'تشغيل',
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final repo = context.read<IptvRepository>();
                        final url = repo.buildMovieStreamUrl(
                          movie.streamId,
                          movie.containerExtension,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                              url: url,
                              title: movie.name,
                              isLive: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24.h),

                  if (movie.genre?.isNotEmpty == true)
                    _Section(title: 'النوع', content: movie.genre!),
                  if (movie.director?.isNotEmpty == true)
                    _Section(title: 'المخرج', content: movie.director!),
                  if (movie.cast?.isNotEmpty == true)
                    _Section(title: 'البطولة', content: movie.cast!),
                  if (movie.plot?.isNotEmpty == true)
                    _Section(title: 'القصة', content: movie.plot!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  const _Chip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: iconColor ?? AppColors.textSecondary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            content,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
