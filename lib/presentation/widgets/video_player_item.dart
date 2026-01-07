import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/presentation/widgets/drama_details_sheet.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dramabox_free/data/models/episode_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dramabox_free/presentation/cubits/video_control_cubit.dart';
import 'video_gesture_overlay.dart';

class VideoPlayerItem extends StatefulWidget {
  final EpisodeModel episode;
  final int index;
  final bool isVisible;
  final String dramaTitle;
  final VoidCallback onBack;
  final VoidCallback? onFinished;
  final VoidCallback? onWatched;
  final void Function(int position, int duration, bool isHistoryUpdate)?
  onProgress;
  final int initialPosition;
  final DramaModel drama;
  final List<EpisodeModel> episodes;
  final Function(int) onEpisodeSelected;

  const VideoPlayerItem({
    super.key,
    required this.episode,
    required this.index,
    required this.isVisible,
    required this.dramaTitle,
    required this.onBack,
    this.onFinished,
    this.onWatched,
    this.onProgress,
    this.initialPosition = 0,
    required this.drama,
    required this.episodes,
    required this.onEpisodeSelected,
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
  bool _watchedTriggered = false;
  int _lastReportedSecond = -1;

  // Subtitle state
  SubtitleModel? _selectedSubtitle;
  List<Caption> _captions = [];
  String _currentCaption = '';
  bool _subtitlesEnabled = true;

  @override
  void initState() {
    super.initState();
    _selectSubtitle();
    _initializeController();
    _startHideTimer();
  }

  void _selectSubtitle() {
    if (widget.episode.subtitles.isEmpty) return;

    // Prioritize Indonesia (ID) first
    _selectedSubtitle = widget.episode.subtitles.firstWhere(
      (s) => s.language.toLowerCase().contains('id'),
      orElse: () => widget.episode.subtitles.firstWhere(
        (s) => s.language.toLowerCase().contains('en'),
        orElse: () => widget.episode.subtitles.first,
      ),
    );

    if (_selectedSubtitle != null) {
      _loadSubtitles(_selectedSubtitle!.url);
    }
  }

  Future<void> _loadSubtitles(String url) async {
    try {
      final response = await Dio().get(url);
      if (response.data is String) {
        final vttContent = response.data as String;
        _parseVTT(vttContent);
      }
    } catch (e) {
      debugPrint("Error loading subtitles: $e");
    }
  }

  void _parseVTT(String content) {
    try {
      final lines = content.split('\n');
      final List<Caption> captions = [];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.contains('-->')) {
          final times = line.split('-->');
          if (times.length == 2) {
            final startTimePart = times[0].trim();
            final endTimeLine = times[1].trim();
            final endTimePart = endTimeLine.split(' ')[0];

            final start = _parseVTTTime(startTimePart);
            final end = _parseVTTTime(endTimePart);

            // Text can be on multiple lines until an empty line
            String text = '';
            i++;
            while (i < lines.length && lines[i].trim().isNotEmpty) {
              if (text.isNotEmpty) text += '\n';
              text += lines[i].trim();
              i++;
            }

            if (text.isNotEmpty) {
              captions.add(
                Caption(
                  number: captions.length,
                  start: start,
                  end: end,
                  text: text,
                ),
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _captions = captions;
        });
      }
    } catch (e) {
      debugPrint("Error parsing VTT: $e");
    }
  }

  Duration _parseVTTTime(String time) {
    // Format: 00:00:00.000 or 00:00.000
    final parts = time.split(':');
    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final secondsParts = parts[2].split('.');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = int.parse(secondsParts[1]);
      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    } else if (parts.length == 2) {
      final minutes = int.parse(parts[0]);
      final secondsParts = parts[1].split('.');
      final seconds = int.parse(secondsParts[0]);
      final milliseconds = int.parse(secondsParts[1]);
      return Duration(
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );
    }
    return Duration.zero;
  }

  void _updateCurrentCaption(Duration position) {
    if (_captions.isEmpty || !_subtitlesEnabled) {
      if (_currentCaption.isNotEmpty) {
        setState(() => _currentCaption = '');
      }
      return;
    }

    final caption = _captions.firstWhere(
      (c) => position >= c.start && position <= c.end,
      orElse: () => const Caption(
        number: -1,
        start: Duration.zero,
        end: Duration.zero,
        text: '',
      ),
    );

    if (_currentCaption != caption.text) {
      setState(() {
        _currentCaption = caption.text;
      });
    }
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

        if (widget.initialPosition > 0) {
          _player?.controller.seekTo(
            Duration(milliseconds: widget.initialPosition),
          );
        }

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

    _updateCurrentCaption(position);

    if (position >= duration &&
        duration != Duration.zero &&
        !_finishedTriggered) {
      _finishedTriggered = true;
      widget.onFinished?.call();
      // Also ensure watched is triggered if it hasn't been yet (for short episodes)
      if (widget.isVisible && !_watchedTriggered) {
        _watchedTriggered = true;
        widget.onWatched?.call();
      }
    }

    if (widget.isVisible && !_watchedTriggered) {
      final threshold = widget.index == 0 ? 10 : 3;
      if (position.inSeconds >= threshold) {
        _watchedTriggered = true;
        widget.onWatched?.call();
      }
    }

    // Process periodic progress updates
    if (widget.isVisible) {
      final currentSecond = position.inSeconds;
      if (currentSecond != _lastReportedSecond) {
        _lastReportedSecond = currentSecond;
        widget.onProgress?.call(
          position.inMilliseconds,
          duration.inMilliseconds,
          currentSecond % 2 == 0,
        );
      }
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<VideoControlCubit>().setControlsVisible(false);
      }
    });
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode.videoUrl != widget.episode.videoUrl) {
      _isInitialized = false;
      _finishedTriggered = false;
      _watchedTriggered = false;
      _player?.dispose();
      _player = null;
      _captions = [];
      _currentCaption = '';
      _selectSubtitle();
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
    _player?.dispose();
    super.dispose();
  }

  void _seek(bool forward) async {
    if (!mounted) return;
    if (!_isInitialized || _player == null) return;
    final player = _player;
    if (player == null) return;
    final currentPosition = player.controller.value.position;
    final seekTo = forward
        ? currentPosition + const Duration(seconds: 3)
        : currentPosition - const Duration(seconds: 3);

    await player.controller.seekTo(seekTo);
    // Clearing seek action is handled by the consumer logic or a timer if needed by UI
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoControlCubit(),
      child: BlocConsumer<VideoControlCubit, VideoControlState>(
        listener: (context, state) {
          // Handle side effects like player control
          if (_isInitialized && _player != null) {
            if (state.isSpeedUp) {
              _player!.controller.setPlaybackSpeed(1.5);
            } else {
              _player!.controller.setPlaybackSpeed(1.0);
            }

            if (state.seekAction != null) {
              _seek(state.seekAction == 'forward');
              // Clear the seek action state immediately after processing to prevent loops
              // Or better, let the UI showing "Seek" be the one relying on state
              // Actually the Seek side effect (video position) is handled here.
              // The visual feedback is handled by the builder.
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  context.read<VideoControlCubit>().clearSeek();
                }
              });
            }
          }

          if (state.areControlsVisible && !_showUI) {
            setState(() => _showUI = true);
            _startHideTimer();
          } else if (!state.areControlsVisible && _showUI) {
            setState(() => _showUI = false);
          }
        },
        builder: (context, state) {
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

                // Subtitle Overlay
                if (_currentCaption.isNotEmpty && _subtitlesEnabled)
                  Positioned(
                    bottom: _showUI ? 220 : 160,
                    left: 32,
                    right: 32,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentCaption,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

                // Layer 1: Background Toggle Layer (Handles taps on empty space)
                Positioned.fill(
                  child: VideoGestureOverlay(
                    videoControlCubit: context.read<VideoControlCubit>(),
                  ),
                ),

                // Visual Feedback for Speed Up
                if (state.isSpeedUp)
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
                if (state.seekAction != null)
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
                            state.seekAction == 'forward'
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

                // Layer 2: UI Bars & Buttons
                // Top Bar (Back button + Episode Index)
                AnimatedOpacity(
                  opacity: _showUI ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showUI, // Prevent clicks when hidden
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                widget.onBack();
                                _startHideTimer();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 0.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Ep. ${widget.index + 1} / ${widget.episodes.length} Episodes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Spacer(),
                            if (widget.episode.subtitles.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _subtitlesEnabled = !_subtitlesEnabled;
                                  });
                                  _startHideTimer();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _subtitlesEnabled
                                        ? Colors.redAccent.withValues(
                                            alpha: 0.8,
                                          )
                                        : Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _subtitlesEnabled
                                              ? Icons.closed_caption
                                              : Icons.closed_caption_disabled,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'CC',
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
                              ),
                          ],
                        ),
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
                    child: IgnorePointer(
                      ignoring: !_showUI, // Prevent clicks when hidden
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.8),
                              Colors.black.withValues(alpha: 0.4),
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
                              const SizedBox(height: 12),
                              // Controls Row: Play/Pause + Duration
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    if (_isInitialized && _player != null)
                                      GestureDetector(
                                        onTap: () {
                                          final controller =
                                              _player?.controller;
                                          if (controller == null) return;
                                          if (controller.value.isPlaying) {
                                            controller.pause();
                                          } else {
                                            controller.play();
                                          }
                                          setState(() {});
                                          _startHideTimer();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 10,
                                                sigmaY: 10,
                                              ),
                                              child: Icon(
                                                _player
                                                            ?.controller
                                                            .value
                                                            .isPlaying ??
                                                        false
                                                    ? Icons.pause_rounded
                                                    : Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ),
                                          ),
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontFeatures: [
                                                        FontFeature.tabularFigures(),
                                                      ],
                                                    ),
                                                  );
                                                },
                                          );
                                        },
                                      ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          useSafeArea: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) =>
                                              DramaDetailsSheet(
                                                drama: widget.drama,
                                                episodes: widget.episodes,
                                                currentIndex: widget.index,
                                                onEpisodeSelected:
                                                    widget.onEpisodeSelected,
                                              ),
                                        );
                                        _startHideTimer();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.15,
                                            ),
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 10,
                                              sigmaY: 10,
                                            ),
                                            child: const Icon(
                                              Icons
                                                  .format_list_bulleted_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

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

                              const SizedBox(height: 16),

                              // Drama Title & Episode Info
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
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
                                          Shadow(
                                            blurRadius: 10,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
