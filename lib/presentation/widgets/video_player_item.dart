import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dramabox_free/data/models/episode_model.dart';

class VideoPlayerItem extends StatefulWidget {
  final EpisodeModel episode;
  final int index;
  final bool isVisible;
  final String dramaTitle;
  final VoidCallback onBack;
  final VoidCallback? onFinished;

  const VideoPlayerItem({
    super.key,
    required this.episode,
    required this.index,
    required this.isVisible,
    required this.dramaTitle,
    required this.onBack,
    this.onFinished,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  CachedVideoPlayerPlus? _player;
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showUI = true;
  Timer? _hideTimer;
  bool _finishedTriggered = false;
  bool _isSpeedUp = false;
  String? _seekAction; // 'forward' or 'backward'
  Timer? _seekActionTimer;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _startHideTimer();
  }

  void _initializeController() async {
    if (_isInitializing) return;
    if (widget.episode.videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = "Video URL is empty";
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      _player = CachedVideoPlayerPlus.networkUrl(
        Uri.parse(widget.episode.videoUrl),
        invalidateCacheIfOlderThan: const Duration(days: 7),
      );

      final player = _player;
      if (player == null) return;

      await player.initialize();
      player.controller.setLooping(false);
      player.controller.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isInitializing = false;
        });
        if (widget.isVisible) {
          _player?.controller.play();
        }
      }
    } catch (e) {
      debugPrint("Error initializing video: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isInitializing = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || !_isInitialized || _player == null) return;

    final player = _player;
    if (player == null) return;
    final position = player.controller.value.position;
    final duration = player.controller.value.duration;

    if (position >= duration &&
        duration != Duration.zero &&
        !_finishedTriggered) {
      _finishedTriggered = true;
      widget.onFinished?.call();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showUI = false;
        });
      }
    });
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    if (_showUI) {
      _startHideTimer();
    }
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode.videoUrl != widget.episode.videoUrl) {
      _isInitialized = false;
      _finishedTriggered = false;
      _player?.dispose();
      _player = null;
      _initializeController();
    } else if (_isInitialized) {
      if (widget.isVisible) {
        _player?.controller.play();
      } else {
        _player?.controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekActionTimer?.cancel();
    _player?.dispose();
    super.dispose();
  }

  void _seek(bool forward) async {
    if (!_isInitialized || _player == null) return;
    final player = _player;
    if (player == null) return;
    final currentPosition = player.controller.value.position;
    final seekTo = forward
        ? currentPosition + const Duration(seconds: 3)
        : currentPosition - const Duration(seconds: 3);

    await player.controller.seekTo(seekTo);

    setState(() {
      _seekAction = forward ? 'forward' : 'backward';
    });
    _seekActionTimer?.cancel();
    _seekActionTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _seekAction = null);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Thumbnail / First Frame
          if (!_isInitialized)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.episode.chapterImg,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[900] ?? Colors.black87,
                  highlightColor: Colors.grey[800] ?? Colors.black54,
                  child: Container(color: Colors.black),
                ),
                errorWidget: (context, url, error) =>
                    Container(color: Colors.black),
              ),
            ),

          Center(
            child: _isInitialized && _player != null
                ? Builder(
                    builder: (context) {
                      final player = _player;
                      if (player == null) {
                        return const SizedBox();
                      }
                      return AspectRatio(
                        aspectRatio: player.controller.value.aspectRatio,
                        child: VideoPlayer(player.controller),
                      );
                    },
                  )
                : const SizedBox(),
          ),

          // Loading indicator on top of thumbnail if not initialized and no error
          if (!_isInitialized && !_hasError)
            const Center(
              child: CircularProgressIndicator(color: Colors.white24),
            ),

          // Error UI
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white54,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _initializeController,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // Tap listener for Speed and Seek
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleUI,
              onLongPressStart: (details) {
                // Only if on right side
                if (details.localPosition.dx >
                    MediaQuery.of(context).size.width / 2) {
                  _player?.controller.setPlaybackSpeed(1.5);
                  setState(() => _isSpeedUp = true);
                }
              },
              onLongPressEnd: (_) {
                _player?.controller.setPlaybackSpeed(1.0);
                setState(() => _isSpeedUp = false);
              },
              onDoubleTapDown: (details) {
                final isRight =
                    details.localPosition.dx >
                    MediaQuery.of(context).size.width / 2;
                _seek(isRight);
              },
              child: Container(color: Colors.transparent),
            ),
          ),

          // Visual Feedback for Speed Up
          if (_isSpeedUp)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fast_forward_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '1.5x Speed Playing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Visual Feedback for Seeking
          if (_seekAction != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _seekAction == 'forward'
                          ? Icons.fast_forward_rounded
                          : Icons.fast_rewind_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '3s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Top Bar (Back button + Episode Index)
          AnimatedOpacity(
            opacity: _showUI ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onBack,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Ep. ${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom UI (Drama Info and Progress Indicator)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showUI ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Controls Row: Play/Pause + Duration
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            if (_isInitialized && _player != null)
                              GestureDetector(
                                onTap: () {
                                  final controller = _player?.controller;
                                  if (controller == null) return;
                                  if (controller.value.isPlaying) {
                                    controller.pause();
                                  } else {
                                    controller.play();
                                  }
                                  setState(() {});
                                  _startHideTimer();
                                },
                                child: Icon(
                                  _player?.controller.value.isPlaying ?? false
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            const SizedBox(width: 12),
                            if (_isInitialized && _player != null)
                              Builder(
                                builder: (context) {
                                  final player = _player;
                                  if (player == null) {
                                    return const SizedBox();
                                  }
                                  return ValueListenableBuilder(
                                    valueListenable: player.controller,
                                    builder:
                                        (
                                          context,
                                          VideoPlayerValue value,
                                          child,
                                        ) {
                                          return Text(
                                            '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          );
                                        },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_isInitialized && _player != null)
                        Builder(
                          builder: (context) {
                            final player = _player;
                            if (player == null) {
                              return const SizedBox(height: 4);
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: VideoProgressIndicator(
                                player.controller,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Colors.amber,
                                  bufferedColor: Colors.grey,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            );
                          },
                        )
                      else
                        const SizedBox(height: 4),

                      const SizedBox(height: 20),

                      // Drama Title & Episode Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.dramaTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 10, color: Colors.black),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
