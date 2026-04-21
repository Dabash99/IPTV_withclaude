import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../cubits/auth_cubit.dart';
import '../widgets/app_logo.dart';
import '../widgets/poster_backdrop.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Placeholder cinematic posters - these show only during first-launch splash
  final _samplePosters = const [
    'https://image.tmdb.org/t/p/w500/kXfqcdQKsToO0OUXHcrrNCHDBzO.jpg',
    'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
    'https://image.tmdb.org/t/p/w500/uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg',
    'https://image.tmdb.org/t/p/w500/62HCnUTziyWcpDaBO2i1DX17ljH.jpg',
    'https://image.tmdb.org/t/p/w500/1PNd6b2j7HAnT4HmwplkOBnpEQB.jpg',
    'https://image.tmdb.org/t/p/w500/iADOJ8Zymht2JPMoy3R7xceZprc.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.read<AuthCubit>().checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (state is AuthUnauthenticated || state is AuthError) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Cinematic backdrop
            Positioned.fill(
              child: PosterBackdrop(posters: _samplePosters),
            ),
            // Content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      const AppLogo(size: 56),
                      SizedBox(height: 40.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 48.w),
                        child: Column(
                          children: [
                            Text(
                              'Welcome to our',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w300,
                                height: 1.3,
                              ),
                            ),
                            Text(
                              'IPTV PLAYER',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                height: 1.3,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'with this application, you can watch\nyour broadcasts using the link you\nreceive ip tv service',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.sp,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        width: 40.w,
                        height: 40.w,
                        child: const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Version 1.2.1',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.sp,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
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
