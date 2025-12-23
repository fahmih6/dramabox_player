import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/presentation/blocs/player_bloc.dart';
import 'package:dramabox_free/presentation/widgets/video_player_item.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PlayerPage extends StatefulWidget {
  final DramaModel drama;

  const PlayerPage({super.key, required this.drama});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  int _currentIndex = 0;
  ScrollController? _pageController;

  @override
  void initState() {
    super.initState();
    // Start loading data immediately
    context.read<PlayerBloc>().add(LoadEpisodesEvent(widget.drama.bookId));
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We use a unique key for the whole screen content to ensure
    // fresh state when switching dramas
    return BlocConsumer<PlayerBloc, PlayerState>(
      listener: (context, state) {
        if (state is PlayerLoaded) {
          // Initialize or reset the controller with the saved index
          if (_pageController == null) {
            _currentIndex = state.initialIndex;
            final screenHeight = MediaQuery.of(context).size.height;
            _pageController = ScrollController(
              initialScrollOffset: state.initialIndex * screenHeight,
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          key: ValueKey(widget.drama.bookId),
          backgroundColor: Colors.black,
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(PlayerState state) {
    if (state is PlayerLoading || _pageController == null) {
      if (state is PlayerError) return _buildError(state.message);
      return const _PlayerLoadingView();
    }

    if (state is PlayerLoaded) {
      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final metrics = notification.metrics;
            if (metrics.viewportDimension > 0) {
              final page = (metrics.pixels / metrics.viewportDimension).round();
              if (page != _currentIndex &&
                  page >= 0 &&
                  page < state.episodes.length) {
                setState(() {
                  _currentIndex = page;
                });
              }
            }
          } else if (notification is ScrollEndNotification) {
            // Save progress when scrolling stops
            context.read<PlayerBloc>().add(
              SaveProgressEvent(widget.drama.bookId, _currentIndex),
            );
          }
          return false;
        },
        child: CustomScrollView(
          controller: _pageController,
          physics: const PageScrollPhysics(),
          scrollDirection: Axis.vertical,
          // Preload next 3 episodes
          cacheExtent: MediaQuery.of(context).size.height * 3,
          slivers: [
            SliverFillViewport(
              delegate: SliverChildBuilderDelegate((context, index) {
                return VideoPlayerItem(
                  key: ValueKey(
                    "${widget.drama.bookId}_${state.episodes[index].chapterId}",
                  ),
                  episode: state.episodes[index],
                  index: index,
                  isVisible: _currentIndex == index,
                  dramaTitle: widget.drama.bookName,
                  onBack: () => Navigator.pop(context),
                  onFinished: () {
                    if (index < state.episodes.length - 1) {
                      _pageController?.animateTo(
                        (index + 1) * MediaQuery.of(context).size.height,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                );
              }, childCount: state.episodes.length),
            ),
          ],
        ),
      );
    }

    if (state is PlayerError) {
      return _buildError(state.message);
    }

    return const SizedBox();
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerLoadingView extends StatefulWidget {
  const _PlayerLoadingView();

  @override
  State<_PlayerLoadingView> createState() => _PlayerLoadingViewState();
}

class _PlayerLoadingViewState extends State<_PlayerLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startProgressSimulation();
  }

  void _startProgressSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 0.7) {
          _progress += 0.02;
        } else if (_progress < 0.9) {
          _progress += 0.005;
        } else if (_progress < 0.95) {
          _progress += 0.001;
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric Rings
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: _RingsPainter(
                  progress: _pulseController.value,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                child: const SizedBox.expand(),
              );
            },
          ),

          // Central Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glow
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.video_collection_rounded,
                  size: 64,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 48),

              // Percentage
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[900],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.amber,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.amber),
                  SizedBox(width: 8),
                  Icon(Icons.circle, size: 6, color: Colors.amber),
                  SizedBox(width: 8),
                  Icon(Icons.circle, size: 6, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 24),

              // Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Fetching episodes... please wait.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This may take a moment depending on your connection.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 8; i++) {
      final radius = (i * 40.0) + (progress * 20.0);
      final opacity = (1.0 - (radius / (size.width / 1.2))).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: opacity * 0.2);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
