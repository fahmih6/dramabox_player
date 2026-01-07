import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoGestureOverlay extends StatefulWidget {
  final VoidCallback? onToggleUI;
  final Function(bool) onSeek;
  final VideoPlayerController? controller;
  final ValueNotifier<bool> isSpeedUpNotifier;

  const VideoGestureOverlay({
    super.key,
    this.onToggleUI,
    required this.onSeek,
    this.controller,
    required this.isSpeedUpNotifier,
  });

  @override
  State<VideoGestureOverlay> createState() => _VideoGestureOverlayState();
}

class _VideoGestureOverlayState extends State<VideoGestureOverlay> {
  void _resetSpeed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller != null) {
        widget.controller!.setPlaybackSpeed(1.0);
      }
      try {
        widget.isSpeedUpNotifier.value = false;
      } catch (e) {
        debugPrint('Error updating isSpeedUpNotifier: $e');
      }
    });
  }

  @override
  void dispose() {
    _resetSpeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onToggleUI,
      onLongPressStart: (details) {
        widget.controller?.setPlaybackSpeed(1.5);
        widget.isSpeedUpNotifier.value = true;
      },
      onLongPressEnd: (_) => _resetSpeed(),
      onLongPressUp: () => _resetSpeed(),
      onLongPressCancel: () => _resetSpeed(),
      onDoubleTapDown: (details) {
        final isRight =
            details.localPosition.dx > MediaQuery.of(context).size.width / 2;
        widget.onSeek(isRight);
      },
      child: Container(color: Colors.transparent),
    );
  }
}
