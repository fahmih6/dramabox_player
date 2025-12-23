import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:dramabox_free/data/models/episode_model.dart';
import 'package:dramabox_free/domain/repositories/drama_repository.dart';

// Events
abstract class PlayerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEpisodesEvent extends PlayerEvent {
  final String bookId;
  LoadEpisodesEvent(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class SaveProgressEvent extends PlayerEvent {
  final String bookId;
  final int index;
  SaveProgressEvent(this.bookId, this.index);

  @override
  List<Object?> get props => [bookId, index];
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
  PlayerLoaded(this.episodes, this.initialIndex);

  @override
  List<Object?> get props => [episodes, initialIndex];
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
        final episodes = await repository.getDramaEpisodes(event.bookId);
        final initialIndex = await repository.getLastWatchedIndex(event.bookId);
        emit(PlayerLoaded(episodes, initialIndex));
      } catch (e) {
        emit(PlayerError(e.toString()));
      }
    }, transformer: restartable());

    on<SaveProgressEvent>((event, emit) async {
      try {
        await repository.saveLastWatchedIndex(event.bookId, event.index);
      } catch (e) {
        debugPrint("Error saving progress: $e");
      }
    }, transformer: sequential());
  }
}
