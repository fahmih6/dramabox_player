import 'package:dramabox_free/core/constants/app_enums.dart';
import 'package:dramabox_free/data/datasources/netshort_remote_data_source.dart';
import 'package:dramabox_free/domain/repositories/drama_repository.dart';
import 'package:dramabox_free/data/datasources/drama_local_data_source.dart';
import 'package:dramabox_free/data/datasources/drama_remote_data_source.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/data/models/drama_section_model.dart';
import 'package:dramabox_free/data/models/episode_model.dart';
import 'package:dramabox_free/data/models/history_model.dart';

class DramaRepositoryImpl implements DramaRepository {
  final DramaRemoteDataSource dramaboxRemoteDataSource;
  final NetshortRemoteDataSource netshortRemoteDataSource;
  final DramaLocalDataSource localDataSource;

  DramaRepositoryImpl({
    required this.dramaboxRemoteDataSource,
    required this.netshortRemoteDataSource,
    required this.localDataSource,
  });

  String _getCacheKey(String baseKey, AppContentProvider provider) {
    return '${provider.name}_$baseKey';
  }

  @override
  Future<List<DramaSectionModel>> getHomeSections({
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    final cacheKey = _getCacheKey('home_sections', provider);
    if (provider == AppContentProvider.netshort) {
      final sections = await netshortRemoteDataSource.getTheaterDramas();
      await localDataSource.cacheSections(cacheKey, sections);
      return sections;
    } else {
      // Dramabox fixed sections
      final results = await Future.wait([
        dramaboxRemoteDataSource.getLatestDramas(),
        dramaboxRemoteDataSource.getTrendingDramas(),
        dramaboxRemoteDataSource.getVipDramas(),
      ]);

      final sections = [
        DramaSectionModel(name: 'Latest', dramas: results[0]),
        DramaSectionModel(name: 'Trending', dramas: results[1]),
        DramaSectionModel(name: 'VIP', dramas: results[2]),
      ];
      await localDataSource.cacheSections(cacheKey, sections);
      return sections;
    }
  }

  @override
  Future<List<DramaSectionModel>?> getCachedHomeSections({
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    final cacheKey = _getCacheKey('home_sections', provider);
    return await localDataSource.getCachedSections(cacheKey);
  }

  @override
  Future<List<DramaModel>> getTrendingDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
    int page = 1,
  }) async {
    try {
      if (provider == AppContentProvider.dramabox) {
        final remoteDramas = await dramaboxRemoteDataSource.getTrendingDramas(
          page: page,
        );
        if (page == 1) {
          await localDataSource.cacheTrendingDramas(remoteDramas);
        }
        return remoteDramas;
      } else {
        return await netshortRemoteDataSource.getForYouDramas(page: page);
      }
    } catch (e) {
      if (page == 1) {
        final cached = await localDataSource.getTrendingDramas();
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<List<DramaModel>> getLatestDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
    int page = 1,
  }) async {
    try {
      if (provider == AppContentProvider.dramabox) {
        final remoteDramas = await dramaboxRemoteDataSource.getLatestDramas(
          page: page,
        );
        if (page == 1) {
          await localDataSource.cacheLatestDramas(remoteDramas);
        }
        return remoteDramas;
      } else {
        return await netshortRemoteDataSource.getForYouDramas(page: page);
      }
    } catch (e) {
      if (page == 1) {
        final cached = await localDataSource.getLatestDramas();
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<List<DramaModel>> getVipDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
    int page = 1,
  }) async {
    try {
      if (provider == AppContentProvider.dramabox) {
        final remoteDramas = await dramaboxRemoteDataSource.getVipDramas(
          page: page,
        );
        if (page == 1) {
          await localDataSource.cacheVipDramas(remoteDramas);
        }
        return remoteDramas;
      } else {
        return await netshortRemoteDataSource.getForYouDramas(page: page);
      }
    } catch (e) {
      if (page == 1) {
        final cached = await localDataSource.getVipDramas();
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<List<DramaModel>?> getCachedTrendingDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    return await localDataSource.getTrendingDramas();
  }

  @override
  Future<List<DramaModel>?> getCachedLatestDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    return await localDataSource.getLatestDramas();
  }

  @override
  Future<List<DramaModel>?> getCachedVipDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    return await localDataSource.getVipDramas();
  }

  @override
  Future<List<DramaModel>> searchDramas(
    String query, {
    AppContentProvider provider = AppContentProvider.dramabox,
    int page = 1,
  }) async {
    if (provider == AppContentProvider.dramabox) {
      return await dramaboxRemoteDataSource.searchDramas(query, page: page);
    } else {
      return await netshortRemoteDataSource.searchDramas(query, page: page);
    }
  }

  @override
  Future<List<EpisodeModel>> getDramaEpisodes(
    String bookId, {
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    final cacheKey = _getCacheKey(bookId, provider);
    final cached = await localDataSource.getEpisodes(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      // If none of the episodes have subtitles, and it's Netshort, it might be stale cache
      // from before the subtitle update. Refresh in this case.
      bool hasAnySubtitle = cached.any((e) => e.subtitles.isNotEmpty);
      if (provider != AppContentProvider.netshort || hasAnySubtitle) {
        return cached;
      }
    }

    final List<EpisodeModel> remoteEpisodes;
    if (provider == AppContentProvider.dramabox) {
      remoteEpisodes = await dramaboxRemoteDataSource.getDramaEpisodes(bookId);
    } else {
      remoteEpisodes = await netshortRemoteDataSource.getDramaEpisodes(bookId);
    }

    await localDataSource.cacheEpisodes(cacheKey, remoteEpisodes);
    return remoteEpisodes;
  }

  @override
  Future<void> saveLastWatchedIndex(
    String bookId,
    int index, {
    int position = 0,
    int duration = 0,
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    final cacheKey = _getCacheKey(bookId, provider);
    await localDataSource.saveLastWatchedIndex(
      cacheKey,
      index,
      position: position,
      duration: duration,
    );
  }

  @override
  Future<int> getLastWatchedIndex(
    String bookId, {
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    final cacheKey = _getCacheKey(bookId, provider);
    return localDataSource.getLastWatchedIndex(cacheKey);
  }

  @override
  Future<Map<String, dynamic>?> getEpisodeProgress(
    String bookId,
    int episodeIndex, {
    AppContentProvider provider = AppContentProvider.dramabox,
  }) async {
    final cacheKey = _getCacheKey(bookId, provider);
    return await localDataSource.getEpisodeProgress(cacheKey, episodeIndex);
  }

  @override
  Future<int> getLocalLastWatchedIndex(String bookId) async {
    // Try both providers if no specific provider is given
    final dramaboxKey = _getCacheKey(bookId, AppContentProvider.dramabox);
    final dramaboxIndex = await localDataSource.getLastWatchedIndex(
      dramaboxKey,
    );
    if (dramaboxIndex >= 0) return dramaboxIndex;

    final netshortKey = _getCacheKey(bookId, AppContentProvider.netshort);
    final netshortIndex = await localDataSource.getLastWatchedIndex(
      netshortKey,
    );
    if (netshortIndex >= 0) return netshortIndex;

    // Last fallback: try the raw bookId (backward compatibility)
    return await localDataSource.getLastWatchedIndex(bookId);
  }

  @override
  Future<void> saveHistory(HistoryModel history) async {
    return localDataSource.saveHistory(history);
  }

  @override
  Future<List<HistoryModel>> getHistory() async {
    return localDataSource.getHistory();
  }
}
