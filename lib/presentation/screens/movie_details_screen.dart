import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
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
            expandedHeight: 340.h,
            pinned: true,
            leading: Padding(
              padding: EdgeInsets.all(8.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: SDGAIcon(
                    SDGAIconsStroke.arrowRight02,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (ctx, _) {
                  final cubit = ctx.read<FavoritesCubit>();
                  final isFav = cubit.isFavorite(movie.streamId, FavoriteType.movie);
                  return Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: SDGAIcon(
                          isFav
                              ? SDGAIconsBulk.favourite
                              : SDGAIconsStroke.favourite,
                          color: isFav ? AppColors.error : Colors.white,
                          size: 22.sp,
                        ),
                        onPressed: () => cubit.toggle(FavoriteItem(
                          id: movie.streamId,
                          name: movie.name,
                          image: movie.streamIcon,
                          type: FavoriteType.movie,
                          extension: movie.containerExtension,
                        )),
                      ),
                    ),
                  );
                },
              ),
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
                          Colors.black.withOpacity(0.4),
                          Colors.transparent,
                          AppColors.background.withOpacity(0.8),
                          AppColors.background,
                        ],
                        stops: const [0.0, 0.3, 0.8, 1.0],
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
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Meta chips
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 6.h,
                    children: [
                      if (movie.rating > 0)
                        _MetaChip(
                          icon: SDGAIconsBulk.star,
                          iconColor: AppColors.warning,
                          label: movie.rating.toStringAsFixed(1),
                        ),
                      if (movie.releaseDate?.isNotEmpty == true)
                        _MetaChip(
                          icon: SDGAIconsStroke.calendar03,
                          label: movie.releaseDate!,
                        ),
                      if (movie.durationSecs != null && movie.durationSecs! > 0)
                        _MetaChip(
                          icon: SDGAIconsStroke.clock01,
                          label: '${(movie.durationSecs! / 60).round()} دقيقة',
                        ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Play button with glow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: AppColors.primaryGlow,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SDGAIcon(
                              SDGAIconsBulk.play,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'تشغيل الفيلم',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),

                  if (movie.genre?.isNotEmpty == true)
                    _Section(
                      icon: SDGAIconsStroke.tag01,
                      title: 'النوع',
                      content: movie.genre!,
                    ),
                  if (movie.director?.isNotEmpty == true)
                    _Section(
                      icon: SDGAIconsStroke.userEdit01,
                      title: 'المخرج',
                      content: movie.director!,
                    ),
                  if (movie.cast?.isNotEmpty == true)
                    _Section(
                      icon: SDGAIconsStroke.userGroup,
                      title: 'البطولة',
                      content: movie.cast!,
                    ),
                  if (movie.plot?.isNotEmpty == true)
                    _Section(
                      icon: SDGAIconsStroke.bookOpen01,
                      title: 'القصة',
                      content: movie.plot!,
                      multiline: true,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final SDGAIconData icon;
  final Color? iconColor;
  final String label;
  const _MetaChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SDGAIcon(icon, size: 14.sp, color: iconColor ?? AppColors.textSecondary),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final SDGAIconData icon;
  final String title;
  final String content;
  final bool multiline;

  const _Section({
    required this.icon,
    required this.title,
    required this.content,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SDGAIcon(icon, color: AppColors.accent, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(right: 24.w),
            child: Text(
              content,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.sp,
                height: multiline ? 1.7 : 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
