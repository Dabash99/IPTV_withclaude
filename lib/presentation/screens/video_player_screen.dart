import 'dart:async';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sdga_icons/sdga_icons.dart';
import 'package:volume_controller/volume_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/watch_history_datasource.dart';
import '../cubits/watch_history_cubit.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isLive;
  final int? contentId;
  final String? contentType;
  final String? contentImage;
  final String? contentExtension;
  final int? resumeFromSeconds;

  // Auto-play next episode
  final String? nextEpisodeUrl;
  final String? nextEpisodeTitle;
  final int? nextEpisodeContentId;
  final String? nextEpisodeImage;
  final String? nextEpisodeExtension;

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
    this.nextEpisodeUrl,
    this.nextEpisodeTitle,
    this.nextEpisodeContentId,
    this.nextEpisodeImage,
    this.nextEpisodeExtension,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  BetterPlayerController? _controller;
  final _playerKey = GlobalKey();
  bool _initialized = false;
  String? _error;
  Timer? _saveTimer;

  bool get _trackHistory =>
      !widget.isLive && widget.contentId != null && widget.contentType != null;

  // ── Gesture state ──────────────────────────────────────────────
  double _brightness = 0.5;
  double _volume = 0.5;
  bool _isLeftSide = false;

  bool _showBrightness = false;
  bool _showVolume = false;
  bool _showSeek = false;
  bool _seekForward = true;
  Timer? _indicatorTimer;

  // ── Next-episode countdown ─────────────────────────────────────
  bool _showNextEp = false;
  int _nextEpCountdown = 5;
  Timer? _nextEpTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    VolumeController().getVolume().then((v) => _volume = v);
    ScreenBrightness().current.then((b) => _brightness = b);
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
      if (mounted) setState(() => _error = 'فشل تشغيل المحتوى. تأكد من رابط السيرفر.');
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.pause ||
        event.betterPlayerEventType == BetterPlayerEventType.finished) {
      _saveProgress();
    }
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      if (widget.nextEpisodeUrl != null) _startNextEpCountdown();
    }
  }

  // ── Next episode ───────────────────────────────────────────────
  void _startNextEpCountdown() {
    if (!mounted) return;
    setState(() {
      _showNextEp = true;
      _nextEpCountdown = 5;
    });
    _nextEpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_nextEpCountdown <= 1) {
        t.cancel();
        _playNext();
      } else {
        setState(() => _nextEpCountdown--);
      }
    });
  }

  void _cancelNextEp() {
    _nextEpTimer?.cancel();
    if (mounted) setState(() => _showNextEp = false);
  }

  void _playNext() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          url: widget.nextEpisodeUrl!,
          title: widget.nextEpisodeTitle ?? '',
          isLive: false,
          contentId: widget.nextEpisodeContentId,
          contentType: widget.contentType,
          contentImage: widget.nextEpisodeImage,
          contentExtension: widget.nextEpisodeExtension,
        ),
      ),
    );
  }

  // ── Watch history ──────────────────────────────────────────────
  Future<void> _saveProgress() async {
    if (!_trackHistory || _controller == null) return;
    final video = _controller!.videoPlayerController;
    if (video == null) return;
    final position = video.value.position;
    final duration = video.value.duration;
    if (duration == null || duration.inSeconds <= 0) return;
    if (position.inSeconds < 30) return;
    final progress = position.inSeconds / duration.inSeconds;
    try {
      final cubit = context.read<WatchHistoryCubit>();
      await cubit.record(WatchHistoryItem(
        id: widget.contentId!,
        name: widget.title,
        image: widget.contentImage ?? '',
        type: widget.contentType!,
        extension: widget.contentExtension,
        progressSeconds: progress > 0.95 ? 0 : position.inSeconds,
        durationSeconds: duration.inSeconds,
        lastWatched: DateTime.now(),
      ));
    } catch (_) {}
  }

  // ── Gesture handlers ───────────────────────────────────────────
  void _onVerticalDragStart(DragStartDetails d) {
    final sw = MediaQuery.of(context).size.width;
    _isLeftSide = d.globalPosition.dx < sw / 2;
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) async {
    final delta = -(d.primaryDelta ?? 0) / 200;
    if (_isLeftSide) {
      _brightness = (_brightness + delta).clamp(0.0, 1.0);
      await ScreenBrightness().setScreenBrightness(_brightness);
      if (mounted) setState(() { _showBrightness = true; _showVolume = false; });
    } else {
      _volume = (_volume + delta).clamp(0.0, 1.0);
      VolumeController().setVolume(_volume);
      if (mounted) setState(() { _showVolume = true; _showBrightness = false; });
    }
    _scheduleHideIndicator();
  }

  void _onDoubleTapDown(TapDownDetails d) {
    final sw = MediaQuery.of(context).size.width;
    _seekForward = d.globalPosition.dx > sw / 2;
  }

  void _onDoubleTap() {
    if (_controller == null) return;
    final pos = _controller!.videoPlayerController?.value.position;
    if (pos == null) return;
    final newPos = _seekForward
        ? pos + const Duration(seconds: 10)
        : pos - const Duration(seconds: 10);
    _controller!.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
    if (mounted) setState(() => _showSeek = true);
    _scheduleHideIndicator();
  }

  void _scheduleHideIndicator() {
    _indicatorTimer?.cancel();
    _indicatorTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() { _showBrightness = false; _showVolume = false; _showSeek = false; });
    });
  }

  // ── PiP ───────────────────────────────────────────────────────
  Future<void> _togglePip() async {
    if (_controller == null) return;
    try {
      final supported = await _controller!.isPictureInPictureSupported();
      if (supported == true) {
        await _controller!.enablePictureInPicture(_playerKey);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _nextEpTimer?.cancel();
    _indicatorTimer?.cancel();
    _saveProgress();
    _controller?.dispose();
    ScreenBrightness().resetScreenBrightness();
    VolumeController().removeListener();
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
          if (!widget.isLive)
            IconButton(
              icon: Icon(Icons.picture_in_picture_alt, color: Colors.white, size: 20.sp),
              onPressed: _togglePip,
              tooltip: 'Picture in Picture',
            ),
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
                      width: 6.w, height: 6.w,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    SizedBox(width: 5.w),
                    Text('LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // Player
              if (_error != null)
                _buildError(_error!)
              else if (!_initialized || _controller == null)
                _buildLoading()
              else
                BetterPlayer(controller: _controller!, key: _playerKey),

              // Gesture + indicator overlay
              if (_initialized && _error == null) _buildGestureLayer(),

              // Next-episode countdown overlay
              if (_showNextEp) _buildNextEpOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gesture layer ──────────────────────────────────────────────
  Widget _buildGestureLayer() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTapDown: _onDoubleTapDown,
        onDoubleTap: _onDoubleTap,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        child: Stack(
          children: [
            // Brightness indicator (left)
            if (_showBrightness)
              Positioned(
                left: 24.w, top: 0, bottom: 0,
                child: Center(child: _GestureIndicator(
                  iconData: Icons.brightness_medium,
                  value: _brightness,
                  label: '${(_brightness * 100).round()}%',
                )),
              ),
            // Volume indicator (right)
            if (_showVolume)
              Positioned(
                right: 24.w, top: 0, bottom: 0,
                child: Center(child: _GestureIndicator(
                  iconData: Icons.volume_up,
                  value: _volume,
                  label: '${(_volume * 100).round()}%',
                )),
              ),
            // Seek indicator (center-ish)
            if (_showSeek)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(
                          _seekForward ? Icons.forward_10 : Icons.replay_10,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _seekForward ? '+10s' : '-10s',
                          style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ── Next episode overlay ───────────────────────────────────────
  Widget _buildNextEpOverlay() {
    return Positioned(
      bottom: 16.h,
      left: 16.w,
      right: 16.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Next Episode',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                  SizedBox(height: 2.h),
                  Text(
                    widget.nextEpisodeTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: _cancelNextEp,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('Cancel',
                  style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: _playNext,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Play Now',
                      style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700)),
                    SizedBox(width: 4.w),
                    Container(
                      width: 20.w, height: 20.w,
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '$_nextEpCountdown',
                          style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
              width: 48.w, height: 48.w,
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
                width: 80.w, height: 80.w,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: SDGAIcon(SDGAIconsBulk.alert02, color: AppColors.error, size: 40.sp)),
              ),
              SizedBox(height: 16.h),
              Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14.sp, height: 1.5)),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                icon: SDGAIcon(SDGAIconsStroke.reload, color: Colors.white, size: 18.sp),
                label: Text('Retry',
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700)),
                onPressed: () {
                  setState(() { _error = null; _initialized = false; });
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

// ── Gesture Indicator Widget ───────────────────────────────────────
class _GestureIndicator extends StatelessWidget {
  final IconData iconData;
  final double value;
  final String label;

  const _GestureIndicator({required this.iconData, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: Colors.white, size: 20.sp),
          SizedBox(height: 10.h),
          SizedBox(
            height: 100.h,
            width: 4.w,
            child: RotatedBox(
              quarterTurns: 3,
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(label,
            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
