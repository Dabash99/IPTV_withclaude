import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/downloads_datasource.dart';
import '../cubits/downloads_cubit.dart';
import '../widgets/app_logo.dart';
import '../widgets/common_widgets.dart';
import 'video_player_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: SDGAIcon(
                          SDGAIconsStroke.arrowRight02,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  const AppLogoHorizontal(),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 15.sp, letterSpacing: 1, fontFamily: 'IBMPlexSansArabic'),
                      children: [
                        TextSpan(
                          text: '${'downloads.title_prefix'.tr()} ',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        TextSpan(
                          text: 'downloads.title_suffix'.tr(),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SDGAIcon(
                    SDGAIconsBulk.download04,
                    color: AppColors.primary,
                    size: 22.sp,
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Expanded(
              child: BlocBuilder<DownloadsCubit, DownloadsState>(
                builder: (context, state) {
                  if (state.items.isEmpty) {
                    return EmptyStateWidget(
                      icon: SDGAIconsBulk.download04,
                      message: 'downloads.empty'.tr(),
                      subtitle: 'downloads.empty_sub'.tr(),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) => _DownloadTile(item: state.items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadItem item;
  const _DownloadTile({required this.item});

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.status == DownloadStatus.completed;
    final isFailed = item.status == DownloadStatus.failed;
    final isDownloading = item.status == DownloadStatus.downloading;

    return GestureDetector(
      onTap: isCompleted && item.localPath != null
          ? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(
              url: item.localPath!,
              title: item.name,
              isLive: false,
            ),
          ),
        );
      }
          : null,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: SizedBox(
                width: 70.w,
                height: 70.w,
                child: item.image.isEmpty
                    ? Container(
                  color: AppColors.cardLight,
                  child: Center(
                    child: SDGAIcon(
                      SDGAIconsBulk.video01,
                      color: AppColors.textMuted,
                      size: 24.sp,
                    ),
                  ),
                )
                    : CachedNetworkImage(
                  imageUrl: item.image,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(color: AppColors.cardLight),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Info + Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Status row
                  Row(
                    children: [
                      _StatusBadge(status: item.status),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          isFailed
                              ? (item.errorMessage ?? 'Failed')
                              : isCompleted
                              ? _formatBytes(item.totalBytes)
                              : '${_formatBytes(item.downloadedBytes)} / ${_formatBytes(item.totalBytes)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                        ),
                      ),
                    ],
                  ),
                  if (isDownloading) ...[
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2.r),
                      child: LinearProgressIndicator(
                        value: item.progress > 0 ? item.progress : null,
                        minHeight: 4.h,
                        backgroundColor: AppColors.cardLight,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Action
            _ActionButton(item: item),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DownloadStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case DownloadStatus.completed:
        color = AppColors.success;
        label = 'downloads.status_done'.tr();
        break;
      case DownloadStatus.downloading:
        color = AppColors.primary;
        label = 'downloads.status_downloading'.tr();
        break;
      case DownloadStatus.failed:
        color = AppColors.error;
        label = 'downloads.status_failed'.tr();
        break;
      case DownloadStatus.paused:
        color = AppColors.warning;
        label = 'downloads.status_paused'.tr();
        break;
      case DownloadStatus.queued:
        color = AppColors.textMuted;
        label = 'downloads.status_queued'.tr();
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9.sp, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final DownloadItem item;
  const _ActionButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DownloadsCubit>();
    if (item.status == DownloadStatus.downloading) {
      return GestureDetector(
        onTap: () => cubit.cancel(item),
        child: Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SDGAIcon(
              SDGAIconsStroke.cancel01,
              color: AppColors.error,
              size: 16.sp,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _confirmDelete(context, cubit),
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SDGAIcon(
            SDGAIconsStroke.delete02,
            color: AppColors.textSecondary,
            size: 16.sp,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DownloadsCubit cubit) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Text(
          'downloads.delete_title'.tr(),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'downloads.delete_msg'.tr(namedArgs: {'name': item.name}),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            onPressed: () {
              cubit.remove(item);
              Navigator.pop(context);
            },
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
