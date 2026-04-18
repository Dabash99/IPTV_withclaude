import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isLive;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
    this.isLive = false,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  BetterPlayerController? _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _initPlayer();
  }

  void _initPlayer() {
    try {
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.url,
        liveStream: widget.isLive,
        notificationConfiguration: BetterPlayerNotificationConfiguration(
          showNotification: true,
          title: widget.title,
          author: 'IPTV Player',
        ),
        bufferingConfiguration: const BetterPlayerBufferingConfiguration(
          minBufferMs: 5000,
          maxBufferMs: 30000,
          bufferForPlaybackMs: 2500,
          bufferForPlaybackAfterRebufferMs: 5000,
        ),
      );

      _controller = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: true,
          looping: false,
          fit: BoxFit.contain,
          aspectRatio: 16 / 9,
          allowedScreenSleep: false,
          autoDetectFullscreenDeviceOrientation: true,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            enableSkips: true,
            enablePlayPause: true,
            enableMute: true,
            enableFullscreen: true,
            enableProgressBar: true,
            enableProgressText: true,
            enableSubtitles: false,
            enableQualities: true,
            enablePlaybackSpeed: true,
            progressBarPlayedColor: AppColors.primary,
            progressBarHandleColor: AppColors.primary,
            controlBarColor: Colors.black54,
            iconsColor: Colors.white,
          ),
          errorBuilder: (context, errorMessage) => _buildError(errorMessage ?? 'فشل التشغيل'),
          eventListener: (event) {
            if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
              if (mounted) {
                setState(() => _error = 'فشل تشغيل المحتوى. تأكد من رابط السيرفر.');
              }
            }
          },
        ),
        betterPlayerDataSource: dataSource,
      );

      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _error = 'خطأ في التشغيل: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.isLive)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  'مباشر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _error != null
              ? _buildError(_error!)
              : !_initialized || _controller == null
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : BetterPlayer(controller: _controller!),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.error, size: 56.sp),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _initialized = false;
                  });
                  _initPlayer();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: Text('إعادة المحاولة',
                    style: TextStyle(color: Colors.white, fontSize: 13.sp)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
