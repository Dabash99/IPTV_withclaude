import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/live_cubit.dart';
import '../cubits/movies_cubit.dart';
import '../cubits/series_cubit.dart';
import 'live_tv_screen.dart';
import 'login_screen.dart';
import 'movies_screen.dart';
import 'favorites_screen.dart';
import 'series_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    LiveTvScreen(),
    MoviesScreen(),
    SeriesScreen(),
    FavoritesScreen(),
    _SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Preload live data on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiveCubit>().loadData();
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    // Lazy load tab data
    switch (index) {
      case 0:
        if (context.read<LiveCubit>().state is LiveInitial) {
          context.read<LiveCubit>().loadData();
        }
        break;
      case 1:
        if (context.read<MoviesCubit>().state is MoviesInitial) {
          context.read<MoviesCubit>().loadData();
        }
        break;
      case 2:
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.live_tv_rounded,
                  label: 'مباشر',
                  active: _currentIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _NavItem(
                  icon: Icons.movie_rounded,
                  label: 'أفلام',
                  active: _currentIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: Icons.video_library_rounded,
                  label: 'مسلسلات',
                  active: _currentIndex == 2,
                  onTap: () => _onTabTapped(2),
                ),
                _NavItem(
                  icon: Icons.favorite_rounded,
                  label: 'المفضلة',
                  active: _currentIndex == 3,
                  onTap: () => _onTabTapped(3),
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'إعدادات',
                  active: _currentIndex == 4,
                  onTap: () => _onTabTapped(4),
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
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
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
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? AppColors.primary : AppColors.textMuted,
              size: 22.sp,
            ),
            if (active) ...[
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final creds = state is AuthAuthenticated ? state.credentials : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  Text(
                    'الإعدادات',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Profile card
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24.r,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Icon(Icons.person, color: Colors.white, size: 28.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    creds?.username ?? '-',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    creds?.status ?? 'Active',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (creds?.expDate != null) ...[
                          SizedBox(height: 14.h),
                          Container(height: 1, color: Colors.white.withOpacity(0.2)),
                          SizedBox(height: 14.h),
                          _infoRow('تاريخ الانتهاء', _formatExp(creds!.expDate!)),
                          SizedBox(height: 8.h),
                          _infoRow(
                            'الاتصالات المسموحة',
                            '${creds.activeConnections ?? 0} / ${creds.maxConnections ?? 0}',
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Logout
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.logout, color: AppColors.error, size: 22.sp),
                      title: Text(
                        'تسجيل الخروج',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_left, color: AppColors.textMuted, size: 22.sp),
                      onTap: () => _confirmLogout(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12.sp)),
      Text(
        value,
        style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
    ],
  );

  String _formatExp(String timestamp) {
    try {
      final ts = int.parse(timestamp);
      final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return timestamp;
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('تسجيل الخروج', style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp)),
        content: Text(
          'متأكد إنك عايز تسجل خروج؟',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
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
            child: Text('خروج', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
