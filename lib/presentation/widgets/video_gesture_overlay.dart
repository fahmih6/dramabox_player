import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dramabox_free/presentation/cubits/video_control_cubit.dart';

class VideoGestureOverlay extends StatelessWidget {
  final VideoControlCubit videoControlCubit;

  const VideoGestureOverlay({super.key, required this.videoControlCubit});

  @override
  Widget build(BuildContext context) {
    return _GestureHandler(videoControlCubit: videoControlCubit);
  }
}

class _GestureHandler extends StatefulWidget {
  final VideoControlCubit videoControlCubit;

  const _GestureHandler({required this.videoControlCubit});

  @override
  State<_GestureHandler> createState() => _GestureHandlerState();
}

class _GestureHandlerState extends State<_GestureHandler> {
  Timer? _longPressTimer;
  Timer? _doubleTapTimer;
  bool _isLongPressActive = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;
  Offset? _lastTapDownPosition; // Restored for movement detection

  bool _hasMoved = false;

  static const _longPressDuration = Duration(milliseconds: 300);
  static const _doubleTapDuration = Duration(milliseconds: 300);

  void _handlePointerDown(PointerDownEvent event) {
    _longPressTimer?.cancel();
    _lastTapDownPosition = event.localPosition;
    _hasMoved = false;

    _longPressTimer = Timer(_longPressDuration, () {
      if (!_hasMoved) {
        _isLongPressActive = true;
        widget.videoControlCubit.startSpeedUp();
      }
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_lastTapDownPosition == null || _hasMoved) return;

    final distance = (event.localPosition - _lastTapDownPosition!).distance;
    if (distance > 10.0) {
      _hasMoved = true;
      _longPressTimer?.cancel();
      if (_isLongPressActive) {
        _isLongPressActive = false;
        widget.videoControlCubit.endSpeedUp();
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();

    if (_hasMoved) {
      // If we moved, it was likely a scroll or drag, so ignore as tap/long-press
      return;
    }

    if (_isLongPressActive) {
      _isLongPressActive = false;
      widget.videoControlCubit.endSpeedUp();
    } else {
      // It was a tap (or double tap sequence)
      _handleTap(event.localPosition);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();
    if (_isLongPressActive) {
      _isLongPressActive = false;
      widget.videoControlCubit.endSpeedUp();
    }
  }

  void _handleTap(Offset position) {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < _doubleTapDuration) {
      // Double tap detected
      _doubleTapTimer?.cancel();
      _tapCount = 0;
      _lastTapTime = null;

      final screenWidth = MediaQuery.of(context).size.width;
      final isRight = position.dx > screenWidth / 2;
      // Also ensure we tap roughly in the same place?
      // Current logic is fine for full screen areas.
      widget.videoControlCubit.seek(isRight);
    } else {
      // First tap or new sequence
      _tapCount = 1;
      _lastTapTime = now;

      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(_doubleTapDuration, () {
        if (_tapCount == 1) {
          widget.videoControlCubit.toggleControls();
        }
        _tapCount = 0;
        _lastTapTime = null;
      });
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: Container(color: Colors.transparent),
    );
  }
}
