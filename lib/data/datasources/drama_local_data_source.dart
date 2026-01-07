import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/drama_model.dart';
import '../models/drama_section_model.dart';
import '../models/episode_model.dart';
import '../models/history_model.dart';

abstract class DramaLocalDataSource {
  Future<void> cacheTrendingDramas(List<DramaModel> dramas);
  Future<List<DramaModel>?> getTrendingDramas();
  Future<void> cacheLatestDramas(List<DramaModel> dramas);
  Future<List<DramaModel>?> getLatestDramas();
  Future<void> cacheVipDramas(List<DramaModel> dramas);
  Future<List<DramaModel>?> getVipDramas();
  Future<void> cacheSections(String key, List<DramaSectionModel> sections);
  Future<List<DramaSectionModel>?> getCachedSections(String key);
  Future<void> cacheEpisodes(String bookId, List<EpisodeModel> episodes);
  Future<List<EpisodeModel>?> getEpisodes(String bookId);
  Future<void> saveLastWatchedIndex(
    String bookId,
    int index, {
    int position = 0,
    int duration = 0,
  });
  Future<int> getLastWatchedIndex(String bookId);
  Future<Map<String, dynamic>?> getEpisodeProgress(String bookId, int index);
  Future<void> saveHistory(HistoryModel history);
  Future<List<HistoryModel>> getHistory();
}

class DramaLocalDataSourceImpl implements DramaLocalDataSource {
  static const String trendingBox = 'trending_cache';
  static const String latestBox = 'latest_cache';
  static const String vipBox = 'vip_cache';
  static const String sectionsBox = 'sections_cache';
  static const String episodesBox = 'episodes_cache';
  static const String progressBox = 'playback_progress';
  static const String historyBox = 'watch_history';

  @override
  Future<void> cacheTrendingDramas(List<DramaModel> dramas) async {
    final box = await Hive.openBox(trendingBox);
    final jsonList = dramas.map((e) => e.toJson()).toList();
    await box.put('trending', jsonEncode(jsonList));
  }

  @override
  Future<List<DramaModel>?> getTrendingDramas() async {
    final box = await Hive.openBox(trendingBox);
    final String? cached = box.get('trending');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      return decoded.map((e) => DramaModel.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<void> cacheLatestDramas(List<DramaModel> dramas) async {
    final box = await Hive.openBox(latestBox);
    final jsonList = dramas.map((e) => e.toJson()).toList();
    await box.put('latest', jsonEncode(jsonList));
  }

  @override
  Future<List<DramaModel>?> getLatestDramas() async {
    final box = await Hive.openBox(latestBox);
    final String? cached = box.get('latest');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      return decoded.map((e) => DramaModel.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<void> cacheVipDramas(List<DramaModel> dramas) async {
    final box = await Hive.openBox(vipBox);
    final jsonList = dramas.map((e) => e.toJson()).toList();
    await box.put('vip', jsonEncode(jsonList));
  }

  @override
  Future<List<DramaModel>?> getVipDramas() async {
    final box = await Hive.openBox(vipBox);
    final String? cached = box.get('vip');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      return decoded.map((e) => DramaModel.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<void> cacheEpisodes(String bookId, List<EpisodeModel> episodes) async {
    final box = await Hive.openBox(episodesBox);
    final jsonList = episodes.map((e) => e.toJson()).toList();
    await box.put(bookId, jsonEncode(jsonList));
  }

  @override
  Future<List<EpisodeModel>?> getEpisodes(String bookId) async {
    final box = await Hive.openBox(episodesBox);
    final String? cached = box.get(bookId);
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      return decoded.map((e) => EpisodeModel.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<void> saveLastWatchedIndex(
    String bookId,
    int index, {
    int position = 0,
    int duration = 0,
  }) async {
    final box = await Hive.openBox(progressBox);
    await box.put(bookId, index);

    // Save detailed progress for this episode
    final detailKey = '${bookId}_$index';
    await box.put(detailKey, {
      'position': position,
      'duration': duration,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<int> getLastWatchedIndex(String bookId) async {
    final box = await Hive.openBox(progressBox);
    final value = box.get(bookId);
    if (value is int) return value;
    return -1;
  }

  @override
  Future<Map<String, dynamic>?> getEpisodeProgress(
    String bookId,
    int index,
  ) async {
    final box = await Hive.openBox(progressBox);
    final detailKey = '${bookId}_$index';
    final value = box.get(detailKey);
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  @override
  Future<void> cacheSections(
    String key,
    List<DramaSectionModel> sections,
  ) async {
    final box = await Hive.openBox(sectionsBox);
    final jsonList = sections.map((e) => e.toJson()).toList();
    await box.put(key, jsonEncode(jsonList));
  }

  @override
  Future<List<DramaSectionModel>?> getCachedSections(String key) async {
    final box = await Hive.openBox(sectionsBox);
    final String? cached = box.get(key);
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      return decoded.map((e) => DramaSectionModel.fromJson(e)).toList();
    }
    return null;
  }

  @override
  Future<void> saveHistory(HistoryModel history) async {
    final box = await Hive.openBox(historyBox);
    final String? cached = box.get('history');
    List<HistoryModel> historyList = [];
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      historyList = decoded.map((e) => HistoryModel.fromJson(e)).toList();
    }

    // Remove existing entry for the same drama to avoid duplicates and move to top
    historyList.removeWhere(
      (e) =>
          e.drama.bookId == history.drama.bookId &&
          e.provider == history.provider,
    );
    historyList.insert(0, history);

    // Keep only last 100 items
    if (historyList.length > 100) {
      historyList = historyList.sublist(0, 100);
    }

    final jsonList = historyList.map((e) => e.toJson()).toList();
    await box.put('history', jsonEncode(jsonList));
  }

  @override
  Future<List<HistoryModel>> getHistory() async {
    final box = await Hive.openBox(historyBox);
    final String? cached = box.get('history');
    if (cached != null) {
      final List decoded = jsonDecode(cached);
      return decoded.map((e) => HistoryModel.fromJson(e)).toList();
    }
    return [];
  }
}
