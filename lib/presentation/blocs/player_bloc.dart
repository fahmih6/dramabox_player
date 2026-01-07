import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dramabox_free/core/constants/app_enums.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/data/models/episode_model.dart';
import 'package:dramabox_free/data/models/history_model.dart';
import 'package:dramabox_free/domain/repositories/drama_repository.dart';

// Events
abstract class PlayerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEpisodesEvent extends PlayerEvent {
  final String bookId;
  final AppContentProvider provider;
  LoadEpisodesEvent(this.bookId, {this.provider = AppContentProvider.dramabox});

  @override
  List<Object?> get props => [bookId, provider];
}

class SaveProgressEvent extends PlayerEvent {
  final DramaModel drama;
  final int index;
  final String episodeName;
  final AppContentProvider provider;
  final int position; // in ms
  final int duration; // in ms
  final bool isHistoryUpdate;
  SaveProgressEvent(
    this.drama,
    this.index, {
    this.episodeName = '',
    this.provider = AppContentProvider.dramabox,
    this.position = 0,
    this.duration = 0,
    this.isHistoryUpdate = false,
  });

  @override
  List<Object?> get props => [
    drama,
    index,
    episodeName,
    provider,
    position,
    duration,
    isHistoryUpdate,
  ];
}

// States
abstract class PlayerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerLoaded extends PlayerState {
  final List<EpisodeModel> episodes;
  final int initialIndex;
  final int initialPosition;
  PlayerLoaded(this.episodes, this.initialIndex, {this.initialPosition = 0});

  @override
  List<Object?> get props => [episodes, initialIndex, initialPosition];
}

class PlayerError extends PlayerState {
  final String message;
  PlayerError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final DramaRepository repository;

  PlayerBloc({required this.repository}) : super(PlayerInitial()) {
    on<LoadEpisodesEvent>((event, emit) async {
      emit(PlayerLoading());
      try {
        final episodes = await repository.getDramaEpisodes(
          event.bookId,
          provider: event.provider,
        );
        final initialIndex = await repository.getLastWatchedIndex(
          event.bookId,
          provider: event.provider,
        );

        int initialPosition = 0;
        if (initialIndex >= 0) {
          final progress = await repository.getEpisodeProgress(
            event.bookId,
            initialIndex,
            provider: event.provider,
          );
          if (progress != null) {
            initialPosition = progress['position'] ?? 0;
          }
        }

        emit(
          PlayerLoaded(
            episodes,
            initialIndex,
            initialPosition: initialPosition,
          ),
        );
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    }, transformer: restartable());

    on<SaveProgressEvent>((event, emit) async {
      try {
        await repository.saveLastWatchedIndex(
          event.drama.bookId,
          event.index,
          position: event.position,
          duration: event.duration,
          provider: event.provider,
        );

        // Save to History only if requested (e.g., on watched threshold or episode change)
        if (event.isHistoryUpdate) {
          await repository.saveHistory(
            HistoryModel(
              drama: event.drama,
              episodeIndex: event.index,
              episodeName: event.episodeName,
              provider: event.provider,
              watchedAt: DateTime.now(),
              watchedPosition: event.position,
              totalDuration: event.duration,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error saving progress: $e");
      }
    }, transformer: sequential());
  }
}
