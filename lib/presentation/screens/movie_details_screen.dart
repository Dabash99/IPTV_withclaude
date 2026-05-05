import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/downloads_datasource.dart';
import '../../data/datasources/favorites_datasource.dart';
import '../../data/datasources/watch_history_datasource.dart';
import '../../domain/entities/stream_entities.dart';
import '../../domain/repositories/iptv_repository.dart';
import '../cubits/downloads_cubit.dart';
import '../cubits/favorites_cubit.dart';
import '../cubits/watch_history_cubit.dart';
import 'video_player_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;
  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  bool _plotExpanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.movie;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Blurred backdrop from poster
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: m.streamIcon.isEmpty
                  ? Container(color: AppColors.cardLight)
                  : CachedNetworkImage(
                imageUrl: m.streamIcon,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(color: AppColors.cardLight),
              ),
            ),
          ),
          // Vertical gradient wash
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.5),
                    AppColors.background.withValues(alpha: 0.9),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top nav
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                    child: Row(
                      children: [
                        _CircleBtn(
                          icon: SDGAIconsStroke.arrowRight02,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          'movies.detail_title'.tr(),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        BlocBuilder<DownloadsCubit, DownloadsState>(
                          builder: (ctx, _) {
                            final cubit = ctx.read<DownloadsCubit>();
                            final existing = cubit.findItem(m.streamId, 'movie');
                            return _DownloadButton(
                              item: existing,
                              isDownloadable: DownloadsDataSource.isDownloadable(
                                m.containerExtension,
                              ),
                              onStart: () {
                                final repo = ctx.read<IptvRepository>();
                                final url = repo.buildMovieStreamUrl(
                                  m.streamId,
                                  m.containerExtension,
                                );
                                cubit.startDownload(
                                  contentId: m.streamId,
                                  name: m.name,
                                  image: m.streamIcon,
                                  type: 'movie',
                                  url: url,
                                  extension: m.containerExtension,
                                );
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text('common.download_started'.tr()),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                );
                              },
                              onRemove: existing == null
                                  ? null
                                  : () => cubit.remove(existing),
                            );
                          },
                        ),
                        SizedBox(width: 8.w),
                        BlocBuilder<FavoritesCubit, FavoritesState>(
                          builder: (ctx, _) {
                            final cubit = ctx.read<FavoritesCubit>();
                            final isFav = cubit.isFavorite(m.streamId, FavoriteType.movie);
                            return _CircleBtn(
                              icon: isFav
                                  ? SDGAIconsBulk.favourite
                                  : SDGAIconsStroke.favourite,
                              color: isFav ? AppColors.error : Colors.white,
                              onTap: () => cubit.toggle(FavoriteItem(
                                id: m.streamId,
                                name: m.name,
                                image: m.streamIcon,
                                type: FavoriteType.movie,
                                extension: m.containerExtension,
                              )),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Poster + title + buttons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Poster
                        Container(
                          width: 120.w,
                          height: 170.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: m.streamIcon.isEmpty
                                ? Container(
                              color: AppColors.cardLight,
                              child: Center(
                                child: SDGAIcon(
                                  SDGAIconsBulk.video01,
                                  color: AppColors.textMuted,
                                  size: 32.sp,
                                ),
                              ),
                            )
                                : CachedNetworkImage(
                              imageUrl: m.streamIcon,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) =>
                                  Container(color: AppColors.cardLight),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Title + genre + duration + buttons
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              if (m.genre?.isNotEmpty == true)
                                Text(
                                  m.genre!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              SizedBox(height: 6.h),
                              if (m.durationSecs != null && m.durationSecs! > 0)
                                Text(
                                  '${(m.durationSecs! / 60).round()} min',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              SizedBox(height: 14.h),

                              // Play button (full width)
                              SizedBox(
                                width: double.infinity,
                                child: BlocBuilder<WatchHistoryCubit, WatchHistoryState>(
                                  builder: (ctx, historyState) {
                                    final existing = historyState.items.firstWhere(
                                          (h) => h.id == m.streamId && h.type == 'movie',
                                      orElse: () => _emptyHistoryItem(),
                                    );
                                    final hasResume = existing.id != 0 &&
                                        (existing.progressSeconds ?? 0) > 30;
                                    return _PlayButton(
                                      label: hasResume ? 'common.resume'.tr() : 'common.play'.tr(),
                                      onTap: () {
                                        final repo = ctx.read<IptvRepository>();
                                        // Try to play from local file if downloaded
                                        final downloadCubit = ctx.read<DownloadsCubit>();
                                        final downloaded =
                                        downloadCubit.findItem(m.streamId, 'movie');
                                        final url = (downloaded != null &&
                                            downloaded.status == DownloadStatus.completed &&
                                            downloaded.localPath != null)
                                            ? downloaded.localPath!
                                            : repo.buildMovieStreamUrl(
                                          m.streamId,
                                          m.containerExtension,
                                        );
                                        Navigator.push(
                                          ctx,
                                          MaterialPageRoute(
                                            builder: (_) => VideoPlayerScreen(
                                              url: url,
                                              title: m.name,
                                              isLive: false,
                                              contentId: m.streamId,
                                              contentType: 'movie',
                                              contentImage: m.streamIcon,
                                              contentExtension: m.containerExtension,
                                              resumeFromSeconds: hasResume
                                                  ? existing.progressSeconds
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),

                  // Metadata table (Release / Director / Rating)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        if (m.releaseDate?.isNotEmpty == true)
                          Expanded(
                            child: _MetaColumn(
                              label: 'common.release_date'.tr(),
                              value: m.releaseDate!,
                            ),
                          ),
                        if (m.director?.isNotEmpty == true)
                          Expanded(
                            child: _MetaColumn(
                              label: 'common.director'.tr(),
                              value: m.director!,
                            ),
                          ),
                        if (m.rating > 0)
                          Expanded(
                            child: _MetaColumn(
                              label: 'common.rating'.tr(),
                              value: '⭐ ${m.rating.toStringAsFixed(1)}',
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 28.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(height: 1, color: AppColors.border),
                  ),
                  SizedBox(height: 20.h),

                  // Cast chips
                  if (m.cast?.isNotEmpty == true) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'common.cast'.tr(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: m.cast!
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .take(8)
                            .map((name) => _CastChip(name: name))
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  // Plot
                  if (m.plot?.isNotEmpty == true) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        'common.plot'.tr(),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: GestureDetector(
                        onTap: () => setState(() => _plotExpanded = !_plotExpanded),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.sp,
                              height: 1.7,
                              fontFamily: 'IBMPlexSansArabic',
                            ),
                            children: [
                              TextSpan(
                                text: _plotExpanded
                                    ? m.plot!
                                    : (m.plot!.length > 180
                                    ? '${m.plot!.substring(0, 180)}… '
                                    : m.plot!),
                              ),
                              if (m.plot!.length > 180)
                                TextSpan(
                                  text: _plotExpanded ? 'common.show_less'.tr() : 'common.more'.tr(),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final SDGAIconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Center(
          child: SDGAIcon(icon, color: color, size: 18.sp),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _PlayButton({required this.onTap, this.label = 'Play'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SDGAIcon(SDGAIconsBulk.play, color: Colors.white, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper for the "no history" case
WatchHistoryItem _emptyHistoryItem() => WatchHistoryItem(
  id: 0,
  name: '',
  image: '',
  type: '',
  lastWatched: DateTime.fromMillisecondsSinceEpoch(0),
);

// Download button: shows different states (download / progress / done / unavailable)
class _DownloadButton extends StatelessWidget {
  final DownloadItem? item;
  final bool isDownloadable;
  final VoidCallback onStart;
  final VoidCallback? onRemove;

  const _DownloadButton({
    required this.item,
    required this.isDownloadable,
    required this.onStart,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDownloadable) {
      return Tooltip(
        message: 'common.no_hls_download'.tr(),
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: SDGAIcon(
              SDGAIconsStroke.download04,
              color: AppColors.textMuted,
              size: 18.sp,
            ),
          ),
        ),
      );
    }
    if (item == null) {
      return GestureDetector(
        onTap: onStart,
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: SDGAIcon(
              SDGAIconsBulk.download04,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
        ),
      );
    }
    if (item!.status == DownloadStatus.completed) {
      return GestureDetector(
        onTap: onRemove,
        child: Container(
          width: 40.w,
          height: 40.w,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: SDGAIcon(
              SDGAIconsBulk.tick02,
              color: AppColors.success,
              size: 18.sp,
            ),
          ),
        ),
      );
    }
    if (item!.status == DownloadStatus.downloading) {
      return Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 36.w,
              height: 36.w,
              child: CircularProgressIndicator(
                value: item!.progress > 0 ? item!.progress : null,
                strokeWidth: 2.5,
                color: AppColors.primary,
                backgroundColor: AppColors.cardLight,
              ),
            ),
            Text(
              (item!.progress * 100).toStringAsFixed(0),
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }
    // Failed or queued
    return GestureDetector(
      onTap: onStart,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: SDGAIcon(
            SDGAIconsStroke.reload,
            color: AppColors.error,
            size: 16.sp,
          ),
        ),
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetaColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CastChip extends StatelessWidget {
  final String name;
  const _CastChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
