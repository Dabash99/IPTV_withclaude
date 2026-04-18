import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          )
              : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.divider,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13.sp,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class LiveStreamCard extends StatelessWidget {
  final String name;
  final String icon;
  final String? currentProgramme;
  final VoidCallback onTap;

  const LiveStreamCard({
    super.key,
    required this.name,
    required this.icon,
    this.currentProgramme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: 56.w,
                height: 56.w,
                color: AppColors.cardLight,
                child: icon.isEmpty
                    ? Icon(Icons.tv, color: AppColors.textMuted, size: 28.sp)
                    : CachedNetworkImage(
                  imageUrl: icon,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _shimmer(),
                  errorWidget: (_, __, ___) =>
                      Icon(Icons.tv, color: AppColors.textMuted, size: 28.sp),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          currentProgramme ?? 'مباشر',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill, color: AppColors.primary, size: 32.sp),
          ],
        ),
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: AppColors.cardLight,
    highlightColor: AppColors.card,
    child: Container(color: AppColors.cardLight),
  );
}

class PosterCard extends StatelessWidget {
  final String name;
  final String image;
  final double? rating;
  final VoidCallback onTap;

  const PosterCard({
    super.key,
    required this.name,
    required this.image,
    this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      color: AppColors.cardLight,
                      child: image.isEmpty
                          ? Icon(Icons.movie, color: AppColors.textMuted, size: 40.sp)
                          : CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: AppColors.cardLight,
                          highlightColor: AppColors.card,
                          child: Container(color: AppColors.cardLight),
                        ),
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.movie, color: AppColors.textMuted, size: 40.sp),
                      ),
                    ),
                  ),
                ),
                if (rating != null && rating! > 0)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: AppColors.warning, size: 12.sp),
                          SizedBox(width: 3.w),
                          Text(
                            rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'بحث...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14.sp),
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20.sp),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
