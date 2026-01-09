import 'package:dramabox_free/core/constants/app_enums.dart';
import '../../data/models/drama_model.dart';
import '../../data/models/drama_section_model.dart';
import '../../data/models/episode_model.dart';
import '../../data/models/history_model.dart';

abstract class DramaRepository {
  Future<List<DramaSectionModel>> getHomeSections({
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<List<DramaSectionModel>?> getCachedHomeSections({
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<List<DramaModel>> getTrendingDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
    int page = 1,
  });
  Future<List<DramaModel>> getLatestDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
    int page = 1,
  });
  Future<List<DramaModel>> getVipDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
    int page = 1,
  });
  Future<List<DramaModel>?> getCachedTrendingDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<List<DramaModel>?> getCachedLatestDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<List<DramaModel>?> getCachedVipDramas({
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<List<DramaModel>> searchDramas(
    String query, {
    AppContentProvider provider = AppContentProvider.dramabox,
    int page = 1,
  });
  Future<List<EpisodeModel>> getDramaEpisodes(
    String bookId, {
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<void> saveLastWatchedIndex(
    String bookId,
    int index, {
    int position = 0,
    int duration = 0,
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<int> getLastWatchedIndex(
    String bookId, {
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<Map<String, dynamic>?> getEpisodeProgress(
    String bookId,
    int episodeIndex, {
    AppContentProvider provider = AppContentProvider.dramabox,
  });
  Future<int> getLocalLastWatchedIndex(String bookId);
  Future<void> saveHistory(HistoryModel history);
  Future<List<HistoryModel>> getHistory();
}
