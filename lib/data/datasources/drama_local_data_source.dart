import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/drama_model.dart';
import '../models/episode_model.dart';

abstract class DramaLocalDataSource {
  Future<void> cacheTrendingDramas(List<DramaModel> dramas);
  Future<List<DramaModel>?> getTrendingDramas();
  Future<void> cacheLatestDramas(List<DramaModel> dramas);
  Future<List<DramaModel>?> getLatestDramas();
  Future<void> cacheVipDramas(List<DramaModel> dramas);
  Future<List<DramaModel>?> getVipDramas();
  Future<void> cacheEpisodes(String bookId, List<EpisodeModel> episodes);
  Future<List<EpisodeModel>?> getEpisodes(String bookId);
  Future<void> saveLastWatchedIndex(String bookId, int index);
  Future<int> getLastWatchedIndex(String bookId);
}

class DramaLocalDataSourceImpl implements DramaLocalDataSource {
  static const String trendingBox = 'trending_cache';
  static const String latestBox = 'latest_cache';
  static const String vipBox = 'vip_cache';
  static const String episodesBox = 'episodes_cache';
  static const String progressBox = 'playback_progress';

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
  Future<void> saveLastWatchedIndex(String bookId, int index) async {
    final box = await Hive.openBox(progressBox);
    await box.put(bookId, index);
  }

  @override
  Future<int> getLastWatchedIndex(String bookId) async {
    final box = await Hive.openBox(progressBox);
    return box.get(bookId) ?? 0;
  }
}
