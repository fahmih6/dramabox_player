import 'package:equatable/equatable.dart';
import '../../core/constants/app_enums.dart';
import 'drama_model.dart';

class HistoryModel extends Equatable {
  final DramaModel drama;
  final int episodeIndex;
  final String episodeName;
  final AppContentProvider provider;
  final DateTime watchedAt;
  final int watchedPosition; // in milliseconds
  final int totalDuration; // in milliseconds

  const HistoryModel({
    required this.drama,
    required this.episodeIndex,
    required this.episodeName,
    required this.provider,
    required this.watchedAt,
    this.watchedPosition = 0,
    this.totalDuration = 0,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      drama: DramaModel.fromJson(json['drama']),
      episodeIndex: json['episodeIndex'] ?? 0,
      episodeName: json['episodeName'] ?? '',
      provider: AppContentProvider.values.firstWhere(
        (e) => e.toString() == json['provider'],
        orElse: () => AppContentProvider.dramabox,
      ),
      watchedAt: DateTime.parse(
        json['watchedAt'] ?? DateTime.now().toIso8601String(),
      ),
      watchedPosition: json['watchedPosition'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drama': drama.toJson(),
      'episodeIndex': episodeIndex,
      'episodeName': episodeName,
      'provider': provider.toString(),
      'watchedAt': watchedAt.toIso8601String(),
      'watchedPosition': watchedPosition,
      'totalDuration': totalDuration,
    };
  }

  @override
  List<Object?> get props => [
    drama,
    episodeIndex,
    provider,
    watchedAt,
    watchedPosition,
    totalDuration,
  ];
}
