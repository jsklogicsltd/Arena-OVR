import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen looping muted video + dark scrim only — no [child].
/// Use once in [MaterialApp.builder] under the navigator so all routes share one player.
class VideoBackdrop extends StatefulWidget {
  const VideoBackdrop({super.key});

  @override
  State<VideoBackdrop> createState() => _VideoBackdropState();
}

class _VideoBackdropState extends State<VideoBackdrop> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset(
      'assets/videos/arena_ovr_background.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    await _controller.initialize();
    await _controller.setVolume(0.0);

    if (!mounted) return;
    await _controller.setLooping(true);
    await _controller.play();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (_controller.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        Container(color: Colors.black.withValues(alpha: 0.4)),
      ],
    );
  }
}
