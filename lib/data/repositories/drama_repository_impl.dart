import 'package:dramabox_free/domain/repositories/drama_repository.dart';
import 'package:dramabox_free/data/datasources/drama_local_data_source.dart';
import 'package:dramabox_free/data/datasources/drama_remote_data_source.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/data/models/episode_model.dart';

class DramaRepositoryImpl implements DramaRepository {
  final DramaRemoteDataSource remoteDataSource;
  final DramaLocalDataSource localDataSource;

  DramaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<DramaModel>> getTrendingDramas() async {
    try {
      final remoteDramas = await remoteDataSource.getTrendingDramas();
      await localDataSource.cacheTrendingDramas(remoteDramas);
      return remoteDramas;
    } catch (e) {
      final cached = await localDataSource.getTrendingDramas();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<DramaModel>> getLatestDramas() async {
    try {
      final remoteDramas = await remoteDataSource.getLatestDramas();
      await localDataSource.cacheLatestDramas(remoteDramas);
      return remoteDramas;
    } catch (e) {
      final cached = await localDataSource.getLatestDramas();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<DramaModel>> getVipDramas() async {
    try {
      final remoteDramas = await remoteDataSource.getVipDramas();
      await localDataSource.cacheVipDramas(remoteDramas);
      return remoteDramas;
    } catch (e) {
      final cached = await localDataSource.getVipDramas();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<DramaModel>?> getCachedTrendingDramas() async {
    return await localDataSource.getTrendingDramas();
  }

  @override
  Future<List<DramaModel>?> getCachedLatestDramas() async {
    return await localDataSource.getLatestDramas();
  }

  @override
  Future<List<DramaModel>?> getCachedVipDramas() async {
    return await localDataSource.getVipDramas();
  }

  @override
  Future<List<DramaModel>> searchDramas(String query) async {
    return await remoteDataSource.searchDramas(query);
  }

  @override
  Future<List<EpisodeModel>> getDramaEpisodes(String bookId) async {
    final cached = await localDataSource.getEpisodes(bookId);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final remoteEpisodes = await remoteDataSource.getDramaEpisodes(bookId);
    await localDataSource.cacheEpisodes(bookId, remoteEpisodes);
    return remoteEpisodes;
  }

  @override
  Future<void> saveLastWatchedIndex(String bookId, int index) async {
    await localDataSource.saveLastWatchedIndex(bookId, index);
  }

  @override
  Future<int> getLastWatchedIndex(String bookId) async {
    return await localDataSource.getLastWatchedIndex(bookId);
  }
}
