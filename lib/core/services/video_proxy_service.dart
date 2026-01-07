import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class VideoProxyService {
  HttpServer? _server;
  int _port = 0;
  final String _localIp = '127.0.0.1';

  /// Initializes the proxy server.
  /// Only starts the server on Android.
  Future<void> init() async {
    if (!Platform.isAndroid) return;

    try {
      // Bind to loopback interface (localhost) on an ephemeral port (0)
      _server = await HttpServer.bind(_localIp, 0);
      _port = _server!.port;
      debugPrint(
        'VideoProxyService: Server running on http://$_localIp:$_port/',
      );

      _server!.listen(_handleRequest);
    } catch (e) {
      debugPrint('VideoProxyService: Failed to start server: $e');
    }
  }

  /// Returns the proxied URL for Android, or the original URL for other platforms.
  String getProxyUrl(String originalUrl) {
    if (!Platform.isAndroid || _server == null) {
      return originalUrl;
    }
    // Encode the original URL to safely pass it as a query parameter
    final encodedUrl = Uri.encodeComponent(originalUrl);
    return 'http://$_localIp:$_port/?url=$encodedUrl';
  }

  /// Handles incoming requests from the video player.
  void _handleRequest(HttpRequest request) async {
    try {
      final urlParam = request.uri.queryParameters['url'];
      if (urlParam == null) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.close();
        return;
      }

      final actualUrl = Uri.parse(urlParam);
      final client = HttpClient(); // This client respects HttpOverrides.global

      final proxyRequest = await client.getUrl(actualUrl);

      // Forward headers from the original request (important for Range requests/seeking)
      request.headers.forEach((name, values) {
        // Host header should not be forwarded as it refers to localhost
        if (name.toLowerCase() != 'host') {
          for (var value in values) {
            proxyRequest.headers.add(name, value);
          }
        }
      });

      final proxyResponse = await proxyRequest.close();

      // Forward response headers back to the client (video player)
      request.response.statusCode = proxyResponse.statusCode;
      proxyResponse.headers.forEach((name, values) {
        for (var value in values) {
          request.response.headers.add(name, value);
        }
      });
      // Ensure content-type is set if missing (helpful for some players)
      if (proxyResponse.headers.contentType == null) {
        request.response.headers.contentType = ContentType.parse("video/mp4");
      }

      // Pipe the response content
      await proxyResponse.pipe(request.response);
    } catch (e) {
      debugPrint('VideoProxyService: Error handling request: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.close();
      } catch (_) {
        // Ignore if response is already closed
      }
    }
  }

  void dispose() {
    _server?.close();
  }
}
