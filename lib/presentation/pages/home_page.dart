import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dramabox_free/presentation/blocs/home_bloc.dart';
import 'package:dramabox_free/presentation/pages/player_page.dart';
import 'package:dramabox_free/core/services/shorebird_service.dart';
import 'package:dramabox_free/core/di/injection_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DramaBox'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search dramas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              onSubmitted: (value) {
                context.read<HomeBloc>().add(SearchDramasEvent(value));
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeLoaded) {
            if (state.searchResults != null) {
              return _buildSearchResults(state.searchResults ?? []);
            }
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSectionHeader('Latest'),
                _buildDramaGrid(state.latestDramas),
                _buildSectionHeader('Trending'),
                _buildDramaGrid(state.trendingDramas),
                _buildSectionHeader('VIP'),
                _buildDramaGrid(state.vipDramas),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          } else if (state is HomeError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
      bottomNavigationBar: ValueListenableBuilder<ShorebirdUpdateStatus>(
        valueListenable: sl<ShorebirdService>().updateStatus,
        builder: (context, status, child) {
          return FutureBuilder<int?>(
            future: sl<ShorebirdService>().getCurrentPatchNumber(),
            builder: (context, snapshot) {
              final patch = snapshot.data;
              final versionText =
                  'v1.0.0+4${patch != null ? ' patch $patch' : ''}';

              Widget statusWidget = const SizedBox.shrink();
              Color? bgColor = Colors.black;

              switch (status) {
                case ShorebirdUpdateStatus.idle:
                  statusWidget = Text(
                    versionText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                  break;
                case ShorebirdUpdateStatus.checking:
                  statusWidget = Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Checking for updates...',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  );
                  break;
                case ShorebirdUpdateStatus.downloading:
                  statusWidget = Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Downloading patch...',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                  break;
                case ShorebirdUpdateStatus.readyToRestart:
                  bgColor = Colors.amber[900]?.withValues(alpha: 0.8);
                  statusWidget = const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.system_update_alt,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Update ready! Restart app to apply.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                  break;
                case ShorebirdUpdateStatus.error:
                  statusWidget = Text(
                    'Update failed',
                    style: TextStyle(fontSize: 10, color: Colors.red[400]),
                  );
                  break;
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: bgColor,
                child: SafeArea(top: false, child: statusWidget),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (title == 'Trending')
              const Icon(Icons.trending_up, color: Colors.amber, size: 24)
            else if (title == 'VIP')
              const Icon(Icons.diamond, color: Colors.blueAccent, size: 24)
            else
              const Icon(Icons.new_releases, color: Colors.blue, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<DramaModel> dramas) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSectionHeader('Search Results'),
        _buildDramaGrid(dramas, showChapterCount: false),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildDramaGrid(
    List<DramaModel> dramas, {
    bool showChapterCount = true,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final drama = dramas[index];
          return _buildDramaCard(drama, showChapterCount: showChapterCount);
        }, childCount: dramas.length),
      ),
    );
  }

  Widget _buildDramaCard(DramaModel drama, {bool showChapterCount = true}) {
    // Determine ranking display
    final hasRanking = drama.ranking != null;
    final firstTag = drama.tags.isNotEmpty
        ? drama.tags.first.toUpperCase()
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlayerPage(drama: drama)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Image
              CachedNetworkImage(
                imageUrl: drama.coverWap,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[900] ?? Colors.black87,
                  highlightColor: Colors.grey[800] ?? Colors.black54,
                  child: Container(color: Colors.black),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),

              // Bottom Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.4, 0.65, 0.85, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Badges
              Positioned(
                top: 8,
                left: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasRanking)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'TOP ${drama.ranking}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (firstTag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          firstTag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drama.bookName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (showChapterCount) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ep. ${drama.chapterCount}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          if (drama.hotCode != null) ...[
                            const Spacer(),
                            Text(
                              drama.hotCode ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else if (drama.hotCode != null) ...[
                      Text(
                        drama.hotCode ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
