import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sdga_icons/sdga_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/watch_history_datasource.dart';
import '../cubits/watch_history_cubit.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isLive;

  /// History tracking - if provided, the player will save resume position
  /// to WatchHistoryCubit periodically (only for VOD content, not live)
  final int? contentId;
  final String? contentType; // 'movie' | 'series'
  final String? contentImage;
  final String? contentExtension;
  final int? resumeFromSeconds;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.title,
    this.isLive = false,
    this.contentId,
    this.contentType,
    this.contentImage,
    this.contentExtension,
    this.resumeFromSeconds,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  BetterPlayerController? _controller;
  bool _initialized = false;
  String? _error;
  Timer? _saveTimer;
  bool _resumeApplied = false;

  bool get _trackHistory =>
      !widget.isLive &&
          widget.contentId != null &&
          widget.contentType != null;

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
          // Start at saved resume position
          startAt: widget.resumeFromSeconds != null && widget.resumeFromSeconds! > 0
              ? Duration(seconds: widget.resumeFromSeconds!)
              : null,
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
            progressBarBufferedColor: Color(0x66FFFFFF),
            progressBarBackgroundColor: Color(0x33FFFFFF),
            controlBarColor: Color(0x99000000),
            iconsColor: Colors.white,
            liveTextColor: AppColors.live,
          ),
          errorBuilder: (context, errorMessage) =>
              _buildError(errorMessage ?? 'فشل التشغيل'),
          eventListener: _onPlayerEvent,
        ),
        betterPlayerDataSource: dataSource,
      );

      // Start periodic save if tracking history
      if (_trackHistory) {
        _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          _saveProgress();
        });
      }

      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _error = 'خطأ في التشغيل: $e');
    }
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      if (mounted) {
        setState(() => _error = 'فشل تشغيل المحتوى. تأكد من رابط السيرفر.');
      }
    }

    // Save progress on pause/finish too
    if (event.betterPlayerEventType == BetterPlayerEventType.pause ||
        event.betterPlayerEventType == BetterPlayerEventType.finished) {
      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    if (!_trackHistory || _controller == null) return;
    final video = _controller!.videoPlayerController;
    if (video == null) return;

    final position = video.value.position;
    final duration = video.value.duration;
    if (duration == null || duration.inSeconds <= 0) return;

    // Don't save if barely watched (< 30s) or fully finished
    if (position.inSeconds < 30) return;

    final progress = position.inSeconds / duration.inSeconds;
    final isFinished = progress > 0.95;

    try {
      final cubit = context.read<WatchHistoryCubit>();
      await cubit.record(
        WatchHistoryItem(
          id: widget.contentId!,
          name: widget.title,
          image: widget.contentImage ?? '',
          type: widget.contentType!,
          extension: widget.contentExtension,
          progressSeconds: isFinished ? 0 : position.inSeconds,
          durationSeconds: duration.inSeconds,
          lastWatched: DateTime.now(),
        ),
      );
    } catch (_) {
      // Cubit may not be available; skip silently
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Save one last time before closing
    _saveProgress();
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
        elevation: 0,
        leading: IconButton(
          icon: SDGAIcon(SDGAIconsStroke.arrowRight02, color: Colors.white, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.isLive)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.live,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
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
              ? _buildLoading()
              : BetterPlayer(controller: _controller!),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48.w,
              height: 48.w,
              child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
            ),
            SizedBox(height: 16.h),
            Text(
              widget.resumeFromSeconds != null && widget.resumeFromSeconds! > 0
                  ? 'Resuming...'
                  : 'Loading...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
            ),
          ],
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
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SDGAIcon(
                    SDGAIconsBulk.alert02,
                    color: AppColors.error,
                    size: 40.sp,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.5),
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                icon: SDGAIcon(SDGAIconsStroke.reload, color: Colors.white, size: 18.sp),
                label: Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _error = null;
                    _initialized = false;
                  });
                  _initPlayer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.r)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
