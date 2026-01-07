import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/models/drama_model.dart';
import '../../core/constants/app_enums.dart';

class DramaCard extends StatelessWidget {
  final DramaModel drama;
  final AppContentProvider provider;
  final VoidCallback onTap;
  final bool showChapterCount;
  final Future<int>? lastWatchedFuture;
  final int? lastWatchedIndex;
  final int? watchedPosition;
  final int? totalDuration;
  final bool hideHotCode;

  const DramaCard({
    super.key,
    required this.drama,
    required this.provider,
    required this.onTap,
    this.showChapterCount = true,
    this.lastWatchedFuture,
    this.lastWatchedIndex,
    this.watchedPosition,
    this.totalDuration,
    this.hideHotCode = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlayData =
        drama.hotCode != null &&
        drama.hotCode != '0' &&
        drama.hotCode!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: drama.coverWap,
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[900]!,
                      highlightColor: Colors.grey[800]!,
                      child: Container(color: Colors.black),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.error, color: Colors.grey),
                    ),
                  ),
                ),
                // Episode Info (Top Left)
                if (showChapterCount && drama.chapterCount > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${drama.chapterCount} Ep',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                // View Count & Play Icon (Conditional)
                if (hasPlayData && !hideHotCode)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 14,
                        ),
                        Text(
                          drama.hotCode!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Last Watched Progress (Bottom Overlay)
                if (lastWatchedIndex != null && lastWatchedIndex! >= 0)
                  _buildProgressBadge(
                    lastWatchedIndex!,
                    watchedPosition: watchedPosition,
                    totalDuration: totalDuration,
                  )
                else if (lastWatchedFuture != null)
                  FutureBuilder<int>(
                    future: lastWatchedFuture,
                    builder: (context, snapshot) {
                      final index = snapshot.data ?? -1;
                      if (index < 0) return const SizedBox.shrink();
                      return _buildProgressBadge(index);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drama.bookName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                if (drama.tags.length > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    drama.tags[1],
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBadge(
    int index, {
    int? watchedPosition,
    int? totalDuration,
  }) {
    double progress = 0.0;
    bool hasProgressData = false;
    if (watchedPosition != null && totalDuration != null && totalDuration > 0) {
      progress = (watchedPosition / totalDuration).clamp(0.0, 1.0);
      hasProgressData = true;
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: Colors.amber.withValues(alpha: 0.95),
              child: Text(
                'LAST WATCHED EP ${index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (hasProgressData)
              SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.black.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
