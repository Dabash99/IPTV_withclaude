import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../../core/constants/app_colors.dart'; // قم بإلغاء التعليق إذا كنت بحاجة إليه

/// App brand logo — uses an image asset instead of text.
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
        // تأكد من وضع مسار الصورة الصحيح هنا
        Image.asset(
          'assets/images/logo.png',
          height: size.h, // استخدام ScreenUtil لضبط الحجم
          fit: BoxFit.contain,
          // color: color, // قم بإلغاء التعليق هنا فقط إذا كانت صورتك شفافة (أيقونة) وتريد تلوينها
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
  final double height;

  const AppLogoHorizontal({
    super.key,
    this.color = Colors.white,
    this.height = 26, // تمت إضافة الحجم للتحكم في ارتفاع الصورة
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // تأكد من وضع مسار الصورة الصحيح هنا
        Image.asset(
          'assets/images/logo.png',
          height: height.h,
          fit: BoxFit.contain,
          // color: color, // قم بإلغاء التعليق هنا فقط إذا كنت تريد تلوين الصورة
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