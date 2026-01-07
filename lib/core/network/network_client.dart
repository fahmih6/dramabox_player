import 'package:dio/dio.dart';

class NetworkClient {
  final Dio dio;

  NetworkClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.sansekai.my.id/api',
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'accept': 'application/json'},
        ),
      );
}
