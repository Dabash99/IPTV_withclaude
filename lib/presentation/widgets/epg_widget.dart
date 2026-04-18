import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/stream_entities.dart';

class EpgBottomSheet extends StatelessWidget {
  final String channelName;
  final List<EpgProgramme> programmes;

  const EpgBottomSheet({
    super.key,
    required this.channelName,
    required this.programmes,
  });

  static void show(
      BuildContext context, {
        required String channelName,
        required List<EpgProgramme> programmes,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => EpgBottomSheet(
        channelName: channelName,
        programmes: programmes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      constraints: BoxConstraints(maxHeight: 0.7.sh),
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.event_note, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'برنامج $channelName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (programmes.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Center(
                child: Text(
                  'مفيش معلومات EPG متاحة',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: programmes.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (_, i) {
                  final p = programmes[i];
                  final isLive = now.isAfter(p.start) && now.isBefore(p.end);
                  return _ProgrammeTile(programme: p, isLive: isLive);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgrammeTile extends StatelessWidget {
  final EpgProgramme programme;
  final bool isLive;
  const _ProgrammeTile({required this.programme, required this.isLive});

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isLive ? AppColors.primary.withOpacity(0.12) : AppColors.card,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isLive ? AppColors.primary : AppColors.divider,
          width: isLive ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isLive ? AppColors.error : AppColors.cardLight,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              isLive ? 'الآن' : _formatTime(programme.start),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  programme.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_formatTime(programme.start)} - ${_formatTime(programme.end)}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
                ),
                if (programme.description.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    programme.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
