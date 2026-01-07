import 'package:equatable/equatable.dart';

class DramaModel extends Equatable {
  final String bookId;
  final String bookName;
  final String coverWap;
  final String introduction;
  final List<String> tags;
  final String protagonist;
  final int chapterCount;
  final int? ranking;
  final String? hotCode;

  const DramaModel({
    required this.bookId,
    required this.bookName,
    required this.coverWap,
    required this.introduction,
    required this.tags,
    required this.protagonist,
    required this.chapterCount,
    this.ranking,
    this.hotCode,
  });

  factory DramaModel.fromJson(Map<String, dynamic> json) {
    final rankVo = json['rankVo'] as Map<String, dynamic>?;
    return DramaModel(
      bookId: json['bookId']?.toString() ?? '',
      bookName: json['bookName'] ?? '',
      coverWap: json['coverWap'] ?? json['cover'] ?? '',
      introduction: json['introduction'] ?? '',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : (json['tagNames'] != null
                ? List<String>.from(json['tagNames'])
                : []),
      protagonist: json['protagonist'] ?? '',
      chapterCount:
          int.tryParse(
            (json['chapterCount'] ??
                    json['totalChapter'] ??
                    json['chapterTotal'] ??
                    json['episodeCount'] ??
                    '0')
                .toString(),
          ) ??
          0,
      ranking: rankVo != null ? rankVo['sort'] : json['ranking'],
      hotCode: rankVo != null ? rankVo['hotCode'] : json['hotCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'bookName': bookName,
      'coverWap': coverWap,
      'introduction': introduction,
      'tags': tags,
      'protagonist': protagonist,
      'chapterCount': chapterCount,
      'ranking': ranking,
      'hotCode': hotCode,
    };
  }

  DramaModel copyWith({
    String? bookId,
    String? bookName,
    String? coverWap,
    String? introduction,
    List<String>? tags,
    String? protagonist,
    int? chapterCount,
    int? ranking,
    String? hotCode,
  }) {
    return DramaModel(
      bookId: bookId ?? this.bookId,
      bookName: bookName ?? this.bookName,
      coverWap: coverWap ?? this.coverWap,
      introduction: introduction ?? this.introduction,
      tags: tags ?? this.tags,
      protagonist: protagonist ?? this.protagonist,
      chapterCount: chapterCount ?? this.chapterCount,
      ranking: ranking ?? this.ranking,
      hotCode: hotCode ?? this.hotCode,
    );
  }

  @override
  List<Object?> get props => [
    bookId,
    bookName,
    coverWap,
    introduction,
    tags,
    protagonist,
    chapterCount,
    ranking,
    hotCode,
  ];
}
