import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

/// App brand logo — inspired by "ABC iptv player" reference style.
/// Uses elegant serif-style letter treatment with subtitle beneath.
class AppLogo extends StatelessWidget {
  final double size;
  final Color color;
  final bool showTagline;

  const AppLogo({
    super.key,
    this.size = 40,
    this.color = Colors.white,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: size.sp,
              fontWeight: FontWeight.w300,
              letterSpacing: -1,
              color: color,
              height: 1,
              fontFamily: 'Cairo',
            ),
            children: [
              const TextSpan(text: 'A'),
              TextSpan(
                text: 'B',
                style: TextStyle(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.5
                    ..color = color,
                ),
              ),
              const TextSpan(text: 'C'),
            ],
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: 2.h),
          Text(
            'iptv player',
            style: TextStyle(
              fontSize: (size / 4).sp,
              color: color.withOpacity(0.85),
              letterSpacing: 2,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ],
    );
  }
}

/// Horizontal logo variant for app bars
class AppLogoHorizontal extends StatelessWidget {
  final Color color;
  const AppLogoHorizontal({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w300,
              letterSpacing: -0.5,
              color: color,
              height: 1,
              fontFamily: 'Cairo',
            ),
            children: [
              const TextSpan(text: 'A'),
              TextSpan(
                text: 'B',
                style: TextStyle(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.2
                    ..color = color,
                ),
              ),
              const TextSpan(text: 'C'),
            ],
          ),
        ),
        SizedBox(width: 6.w),
        Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Text(
            'iptv player',
            style: TextStyle(
              fontSize: 10.sp,
              color: color.withOpacity(0.75),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
