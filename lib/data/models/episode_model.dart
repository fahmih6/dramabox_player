import 'package:equatable/equatable.dart';

class EpisodeModel extends Equatable {
  final String chapterId;
  final String chapterName;
  final String videoUrl;
  final String chapterImg;

  const EpisodeModel({
    required this.chapterId,
    required this.chapterName,
    required this.videoUrl,
    required this.chapterImg,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    // Check if it's already a parsed model from cache
    if (json.containsKey('videoUrl') &&
        (json['videoUrl'] as String).isNotEmpty) {
      return EpisodeModel(
        chapterId: json['chapterId']?.toString() ?? '',
        chapterName: json['chapterName'] ?? '',
        videoUrl: json['videoUrl'] ?? '',
        chapterImg: json['chapterImg'] ?? '',
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
      chapterImg: json['chapterImg'] ?? json['chapterImg'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'chapterName': chapterName,
      'videoUrl': videoUrl,
      'chapterImg': chapterImg,
    };
  }

  @override
  List<Object?> get props => [chapterId, chapterName, videoUrl, chapterImg];
}
