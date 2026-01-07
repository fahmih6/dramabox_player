import 'package:equatable/equatable.dart';

class SubtitleModel extends Equatable {
  final String url;
  final String format;
  final String language;

  const SubtitleModel({
    required this.url,
    required this.format,
    required this.language,
  });

  factory SubtitleModel.fromJson(Map<String, dynamic> json) {
    return SubtitleModel(
      url: json['url'] ?? '',
      format: json['format'] ?? '',
      language: json['subtitleLanguage'] ?? json['language'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'format': format, 'subtitleLanguage': language};
  }

  @override
  List<Object?> get props => [url, format, language];
}

class EpisodeModel extends Equatable {
  final String chapterId;
  final String chapterName;
  final String videoUrl;
  final String chapterImg;
  final List<SubtitleModel> subtitles;

  const EpisodeModel({
    required this.chapterId,
    required this.chapterName,
    required this.videoUrl,
    required this.chapterImg,
    this.subtitles = const [],
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    final List<SubtitleModel> subtitles = [];
    if (json['subtitles'] != null) {
      final list = json['subtitles'] as List;
      subtitles.addAll(list.map((e) => SubtitleModel.fromJson(e)));
    }

    // Check if it's already a parsed model from cache
    if (json.containsKey('videoUrl') &&
        (json['videoUrl'] as String).isNotEmpty) {
      return EpisodeModel(
        chapterId: json['chapterId']?.toString() ?? '',
        chapterName: json['chapterName'] ?? '',
        videoUrl: json['videoUrl'] ?? '',
        chapterImg: json['chapterImg'] ?? '',
        subtitles: subtitles,
      );
    }

    String foundUrl = '';
    final cdnList = json['cdnList'] as List?;
    if (cdnList != null && cdnList.isNotEmpty) {
      // Prefer cdnDomain with "akavideo" or the first one
      final cdn = cdnList.firstWhere(
        (e) => (e['cdnDomain'] as String).contains('akavideo'),
        orElse: () => cdnList.first,
      );
      final videoPaths = cdn['videoPathList'] as List?;
      if (videoPaths != null && videoPaths.isNotEmpty) {
        // Find best quality or 720p if available
        final path = videoPaths.firstWhere(
          (v) => v['quality'] == 720,
          orElse: () => videoPaths.first,
        );
        foundUrl = path['videoPath'] ?? '';
      }
    }

    return EpisodeModel(
      chapterId: json['chapterId']?.toString() ?? '',
      chapterName: json['chapterName'] ?? '',
      videoUrl: foundUrl,
      chapterImg: json['chapterImg'] ?? '',
      subtitles: subtitles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'chapterName': chapterName,
      'videoUrl': videoUrl,
      'chapterImg': chapterImg,
      'subtitles': subtitles.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    chapterId,
    chapterName,
    videoUrl,
    chapterImg,
    subtitles,
  ];
}
