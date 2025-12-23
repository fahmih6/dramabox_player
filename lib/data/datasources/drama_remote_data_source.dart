import 'package:dio/dio.dart';
import 'package:dramabox_free/core/network/network_client.dart';
import 'package:dramabox_free/core/utils/isolate_parser.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/data/models/episode_model.dart';

abstract class DramaRemoteDataSource {
  Future<List<DramaModel>> getTrendingDramas();
  Future<List<DramaModel>> getLatestDramas();
  Future<List<DramaModel>> getVipDramas();
  Future<List<DramaModel>> searchDramas(String query);
  Future<List<EpisodeModel>> getDramaEpisodes(String bookId);
}

class DramaRemoteDataSourceImpl implements DramaRemoteDataSource {
  final NetworkClient client;

  DramaRemoteDataSourceImpl({required this.client});

  @override
  Future<List<DramaModel>> getTrendingDramas() async {
    final response = await client.dio.get('/dramabox/trending');
    final data = response.data;
    if (data is List) {
      return data.map((e) => DramaModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<DramaModel>> getLatestDramas() async {
    final response = await client.dio.get('/dramabox/latest');
    final data = response.data;
    if (data is List) {
      return data.map((e) => DramaModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<DramaModel>> getVipDramas() async {
    final response = await client.dio.get('/dramabox/vip');
    final data = response.data;
    final List<DramaModel> allDramas = [];

    if (data is Map && data['columnVoList'] is List) {
      final columns = data['columnVoList'] as List;
      for (var column in columns) {
        if (column is Map && column['bookList'] is List) {
          final books = column['bookList'] as List;
          allDramas.addAll(books.map((e) => DramaModel.fromJson(e)).toList());
        }
      }
    }
    return allDramas;
  }

  @override
  Future<List<DramaModel>> searchDramas(String query) async {
    final response = await client.dio.get(
      '/dramabox/search',
      queryParameters: {'query': query},
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => DramaModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<EpisodeModel>> getDramaEpisodes(String bookId) async {
    final Response<String> rawResponse = await client.dio.get<String>(
      '/dramabox/allepisode',
      queryParameters: {'bookId': bookId},
      options: Options(responseType: ResponseType.plain),
    );

    final dynamic decoded = await IsolateParser.parseJson(
      rawResponse.data ?? '',
    );
    if (decoded is List) {
      return decoded.map((e) => EpisodeModel.fromJson(e)).toList();
    }
    return [];
  }
}
