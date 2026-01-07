import 'package:equatable/equatable.dart';
import 'drama_model.dart';

class NetshortDramaModel extends Equatable {
  final String shortPlayId;
  final String shortPlayName;
  final String shortPlayCover;
  final String introduction;
  final List<String> tags;
  final int episodeCount;
  final String? hotCode;

  const NetshortDramaModel({
    required this.shortPlayId,
    required this.shortPlayName,
    required this.shortPlayCover,
    required this.introduction,
    required this.tags,
    required this.episodeCount,
    this.hotCode,
  });

  factory NetshortDramaModel.fromJson(Map<String, dynamic> json) {
    return NetshortDramaModel(
      shortPlayId: json['shortPlayId']?.toString() ?? '',
      shortPlayName: json['shortPlayName'] ?? '',
      shortPlayCover: json['shortPlayCover'] ?? json['coverVerticalUrl'] ?? '',
      introduction: json['introduction'] ?? json['shotIntroduce'] ?? '',
      tags: json['tagNames'] != null
          ? List<String>.from(json['tagNames'])
          : (json['labelArray'] != null
                ? List<String>.from(json['labelArray'])
                : []),
      episodeCount: json['episodeCount'] ?? json['totalEpisode'] ?? 0,
      hotCode: (json['heatScoreShow'] ?? json['scoreShow'] ?? json['hotCode'])
          ?.toString(),
    );
  }

  DramaModel toDramaModel() {
    return DramaModel(
      bookId: shortPlayId,
      bookName: shortPlayName,
      coverWap: shortPlayCover,
      introduction: introduction,
      tags: tags,
      protagonist: '', // Netshort doesn't seem to have this in theater view
      chapterCount: episodeCount,
      hotCode: hotCode,
    );
  }

  @override
  List<Object?> get props => [
    shortPlayId,
    shortPlayName,
    shortPlayCover,
    introduction,
    tags,
    episodeCount,
    hotCode,
  ];
}
