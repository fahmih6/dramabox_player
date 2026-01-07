import 'package:dramabox_free/core/network/network_client.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/data/models/drama_section_model.dart';
import 'package:dramabox_free/data/models/episode_model.dart';
import 'package:dramabox_free/data/models/netshort_drama_model.dart';
import 'package:dramabox_free/data/models/netshort_episode_model.dart';

abstract class NetshortRemoteDataSource {
  Future<List<DramaSectionModel>> getTheaterDramas();
  Future<List<DramaModel>> getForYouDramas(int page);
  Future<List<DramaModel>> searchDramas(String query);
  Future<List<EpisodeModel>> getDramaEpisodes(String shortPlayId);
}

class NetshortRemoteDataSourceImpl implements NetshortRemoteDataSource {
  final NetworkClient client;

  NetshortRemoteDataSourceImpl({required this.client});

  @override
  Future<List<DramaSectionModel>> getTheaterDramas() async {
    final response = await client.dio.get('/netshort/theaters');
    final data = response.data;
    final List<DramaSectionModel> sections = [];

    if (data is List) {
      for (var group in data) {
        if (group is Map) {
          final String name = group['contentName'] ?? 'Section';
          final List? books = group['contentInfos'] ?? group['dramas'];
          if (books != null) {
            final dramas = books
                .map((e) => NetshortDramaModel.fromJson(e).toDramaModel())
                .toList();
            sections.add(DramaSectionModel(name: name, dramas: dramas));
          }
        }
      }
    }
    return sections;
  }

  @override
  Future<List<DramaModel>> getForYouDramas(int page) async {
    final response = await client.dio.get(
      '/netshort/foryou',
      queryParameters: {'page': page},
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => NetshortDramaModel.fromJson(e).toDramaModel())
          .toList();
    }
    return [];
  }

  @override
  Future<List<DramaModel>> searchDramas(String query) async {
    final response = await client.dio.get(
      '/netshort/search',
      queryParameters: {'query': query},
    );
    final data = response.data;
    if (data is Map && data['searchCodeSearchResult'] is List) {
      final results = data['searchCodeSearchResult'] as List;
      return results
          .map((e) => NetshortDramaModel.fromJson(e).toDramaModel())
          .toList();
    }
    return [];
  }

  @override
  Future<List<EpisodeModel>> getDramaEpisodes(String shortPlayId) async {
    final response = await client.dio.get(
      '/netshort/allepisode',
      queryParameters: {'shortPlayId': shortPlayId},
    );
    final data = response.data;
    if (data is Map && data['shortPlayEpisodeInfos'] is List) {
      final episodes = data['shortPlayEpisodeInfos'] as List;
      return episodes
          .map((e) => NetshortEpisodeModel.fromJson(e).toEpisodeModel())
          .toList();
    }
    return [];
  }
}
