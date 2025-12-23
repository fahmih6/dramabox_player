import '../../data/models/drama_model.dart';
import '../../data/models/episode_model.dart';

abstract class DramaRepository {
  Future<List<DramaModel>> getTrendingDramas();
  Future<List<DramaModel>> getLatestDramas();
  Future<List<DramaModel>> getVipDramas();
  Future<List<DramaModel>?> getCachedTrendingDramas();
  Future<List<DramaModel>?> getCachedLatestDramas();
  Future<List<DramaModel>?> getCachedVipDramas();
  Future<List<DramaModel>> searchDramas(String query);
  Future<List<EpisodeModel>> getDramaEpisodes(String bookId);
  Future<void> saveLastWatchedIndex(String bookId, int index);
  Future<int> getLastWatchedIndex(String bookId);
}
