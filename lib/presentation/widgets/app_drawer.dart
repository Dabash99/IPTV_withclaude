import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../cubits/auth_cubit.dart';
import 'app_logo.dart';

/// Shared drawer used across main screens (Dashboard, Live, Movies, Series).
/// Shows the logo, the current user, and quick links to the main app sections.
class AppDrawer extends StatelessWidget {
  /// Called when a section is tapped. The parent shell (HomeScreen) switches
  /// the bottom nav tab. Pass null if the drawer is used from a non-shell screen.
  final ValueChanged<int>? onNavigate;

  const AppDrawer({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
              child: Row(
                children: [
                  const AppLogoHorizontal(),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: SDGAIcon(
                          SDGAIconsStroke.cancel01,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(height: 1, color: AppColors.border),
            ),
            SizedBox(height: 14.h),

            // User info card
            BlocBuilder<AuthCubit, AuthState>(
              builder: (ctx, state) {
                final creds = state is AuthAuthenticated ? state.credentials : null;
                if (creds == null) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SDGAIcon(
                              SDGAIconsBulk.user,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                creds.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                creds.status ?? 'Active',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),

            // Categories title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'CATEGORIES',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Nav items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                children: [
                  _DrawerItem(
                    icon: SDGAIconsBulk.home03,
                    label: 'Dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(0);
                    },
                  ),
                  _DrawerItem(
                    icon: SDGAIconsBulk.tv01,
                    label: 'Live TV',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(1);
                    },
                  ),
                  _DrawerItem(
                    icon: SDGAIconsBulk.video01,
                    label: 'Movies',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(2);
                    },
                  ),
                  _DrawerItem(
                    icon: SDGAIconsBulk.folderLibrary,
                    label: 'Series',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(3);
                    },
                  ),
                  _DrawerItem(
                    icon: SDGAIconsBulk.favourite,
                    label: 'Favorites',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(4);
                    },
                  ),
                  SizedBox(height: 14.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Container(height: 1, color: AppColors.border),
                  ),
                  SizedBox(height: 14.h),
                  _DrawerItem(
                    icon: SDGAIconsBulk.settings02,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      onNavigate?.call(5);
                    },
                  ),
                ],
              ),
            ),

            // Version
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final SDGAIconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Row(
            children: [
              SDGAIcon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 14.w),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              SDGAIcon(
                SDGAIconsStroke.arrowLeft01,
                color: AppColors.textMuted,
                size: 14.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
