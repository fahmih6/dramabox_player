import 'package:equatable/equatable.dart';
import 'episode_model.dart';

class NetshortEpisodeModel extends Equatable {
  final String episodeId;
  final String episodeName;
  final int episodeNo;
  final String playVoucher;
  final String episodeCover;
  final List<SubtitleModel> subtitles;

  const NetshortEpisodeModel({
    required this.episodeId,
    required this.episodeName,
    required this.episodeNo,
    required this.playVoucher,
    required this.episodeCover,
    this.subtitles = const [],
  });

  factory NetshortEpisodeModel.fromJson(Map<String, dynamic> json) {
    return NetshortEpisodeModel(
      episodeId: json['episodeId']?.toString() ?? '',
      episodeName: json['episodeName'] ?? 'Episode ${json['episodeNo']}',
      episodeNo: json['episodeNo'] ?? 0,
      playVoucher: json['playVoucher'] ?? '',
      episodeCover: json['episodeCover'] ?? '',
      subtitles: json['subtitleList'] != null
          ? (json['subtitleList'] as List)
                .map((e) => SubtitleModel.fromJson(e))
                .toList()
          : [],
    );
  }

  EpisodeModel toEpisodeModel() {
    return EpisodeModel(
      chapterId: episodeId,
      chapterName: episodeName,
      videoUrl: playVoucher,
      chapterImg: episodeCover,
      subtitles: subtitles,
    );
  }

  @override
  List<Object?> get props => [
    episodeId,
    episodeName,
    episodeNo,
    playVoucher,
    episodeCover,
    subtitles,
  ];
}
