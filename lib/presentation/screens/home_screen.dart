import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/live_cubit.dart';
import '../cubits/movies_cubit.dart';
import '../cubits/series_cubit.dart';
import '../widgets/app_logo.dart';
import 'dashboard_screen.dart';
import 'favorites_screen.dart';
import 'live_tv_screen.dart';
import 'login_screen.dart';
import 'movies_screen.dart';
import 'series_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    LiveTvScreen(),
    MoviesScreen(),
    SeriesScreen(),
    FavoritesScreen(),
    _SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 1:
        if (context.read<LiveCubit>().state is LiveInitial) {
          context.read<LiveCubit>().loadData();
        }
        break;
      case 2:
        if (context.read<MoviesCubit>().state is MoviesInitial) {
          context.read<MoviesCubit>().loadData();
        }
        break;
      case 3:
        if (context.read<SeriesCubit>().state is SeriesInitial) {
          context.read<SeriesCubit>().loadData();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: SDGAIconsBulk.home03,
                  active: _currentIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _NavItem(
                  icon: SDGAIconsBulk.tv01,
                  active: _currentIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: SDGAIconsBulk.video01,
                  active: _currentIndex == 2,
                  onTap: () => _onTabTapped(2),
                ),
                _NavItem(
                  icon: SDGAIconsBulk.folderLibrary,
                  active: _currentIndex == 3,
                  onTap: () => _onTabTapped(3),
                ),
                _NavItem(
                  icon: SDGAIconsBulk.favourite,
                  active: _currentIndex == 4,
                  onTap: () => _onTabTapped(4),
                ),
                _NavItem(
                  icon: SDGAIconsBulk.settings02,
                  active: _currentIndex == 5,
                  onTap: () => _onTabTapped(5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final SDGAIconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: active
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Center(
          child: SDGAIcon(
            icon,
            color: active ? Colors.white : AppColors.textMuted,
            size: 20.sp,
          ),
        ),
      ),
    );
  }
}

// ============ Settings Screen ============
class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  bool _gridView = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final creds = state is AuthAuthenticated ? state.credentials : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 120.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: back + title + logout
                  Row(
                    children: [
                      Container(
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
                      SizedBox(width: 14.w),
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _confirmLogout(context),
                        child: Row(
                          children: [
                            SDGAIcon(
                              SDGAIconsStroke.logout03,
                              color: AppColors.error,
                              size: 18.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),

                  // View mode
                  Row(
                    children: [
                      Text(
                        'View List',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _ViewToggle(
                        grid: _gridView,
                        onChanged: (v) => setState(() => _gridView = v),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Profile card
                  _ProfileTile(
                    icon: SDGAIconsBulk.user,
                    label: 'Profile',
                    onTap: () {
                      if (creds != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _ProfileScreen(creds: creds),
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(height: 10.h),
                  _ProfileTile(
                    icon: SDGAIconsBulk.delete02,
                    label: 'Delete Recently Watched',
                    onTap: () {
                      // TODO: integrate WatchHistoryCubit.clear()
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Watch history cleared'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10.h),
                  _ProfileTile(
                    icon: SDGAIconsBulk.informationCircle,
                    label: 'About',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Text(
          'تسجيل الخروج',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'متأكد إنك عايز تسجل خروج؟',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                );
              }
            },
            child: Text(
              'خروج',
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

class _ViewToggle extends StatelessWidget {
  final bool grid;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.grid, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconBtn(SDGAIconsStroke.menu08, !grid, () => onChanged(false)),
          _iconBtn(SDGAIconsStroke.grid, grid, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _iconBtn(SDGAIconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: SDGAIcon(
          icon,
          color: active ? Colors.white : AppColors.textMuted,
          size: 16.sp,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final SDGAIconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(100.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SDGAIcon(icon, color: AppColors.textPrimary, size: 18.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SDGAIcon(
                SDGAIconsStroke.arrowLeft02,
                color: AppColors.textMuted,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ Profile Detail Screen (M3U style from reference) ============
class _ProfileScreen extends StatelessWidget {
  final dynamic creds;
  const _ProfileScreen({required this.creds});

  int _daysRemaining() {
    try {
      final ts = int.parse(creds.expDate ?? '0');
      final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return date.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysRemaining();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const Spacer(),
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    const AppLogo(size: 48),
                    SizedBox(height: 40.h),

                    // Link icon badge
                    Container(
                      width: 72.w,
                      height: 72.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SDGAIcon(
                          SDGAIconsBulk.link02,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // User info with days remaining
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  creds.username ?? '-',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  creds.serverUrl ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$days',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              Text(
                                'Days Remaining',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
