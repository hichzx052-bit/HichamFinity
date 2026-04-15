import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/trigger_service.dart';
import '../utils/theme.dart';

/// عرض الفيديو — يطلع فوق الشاشة لما يشتغل trigger
class VideoOverlay extends StatefulWidget {
  final TriggerService triggerService;
  final Widget child;

  const VideoOverlay({
    super.key,
    required this.triggerService,
    required this.child,
  });

  @override
  State<VideoOverlay> createState() => _VideoOverlayState();
}

class _VideoOverlayState extends State<VideoOverlay> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  StreamSubscription? _subscription;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);

    _subscription = widget.triggerService.videoStream.listen(_onTrigger);
  }

  void _onTrigger(TriggerConfig trigger) {
    if (trigger.videoPath == null || trigger.videoPath!.isEmpty) return;
    _playVideo(trigger.videoPath!);
  }

  Future<void> _playVideo(String path) async {
    // إذا فيه فيديو شغال — أوقفه أول
    await _stopVideo();

    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('❌ الفيديو مو موجود: $path');
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      await _controller!.setVolume(1.0);

      setState(() => _isPlaying = true);
      _fadeController.forward();

      await _controller!.play();

      // لما يخلص الفيديو — أقفله
      _controller!.addListener(() {
        if (_controller != null &&
            _controller!.value.position >= _controller!.value.duration &&
            _controller!.value.duration > Duration.zero) {
          _stopVideo();
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في تشغيل الفيديو: $e');
      _stopVideo();
    }
  }

  Future<void> _stopVideo() async {
    if (_controller != null) {
      await _fadeController.reverse();
      await _controller!.dispose();
      _controller = null;
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // المحتوى الأصلي
        widget.child,

        // الفيديو فوق كل شي
        if (_isPlaying && _controller != null && _controller!.value.isInitialized)
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _stopVideo, // اضغط لإغلاق الفيديو
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // الفيديو
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // زر إغلاق
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'اضغط للإغلاق',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
