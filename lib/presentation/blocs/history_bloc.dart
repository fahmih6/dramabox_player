import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/history_model.dart';
import '../../domain/repositories/drama_repository.dart';

// Events
abstract class HistoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {}

class AddHistoryEvent extends HistoryEvent {
  final HistoryModel history;
  AddHistoryEvent(this.history);

  @override
  List<Object?> get props => [history];
}

class ClearHistoryEvent extends HistoryEvent {}

// States
abstract class HistoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<HistoryModel> history;
  HistoryLoaded(this.history);

  @override
  List<Object?> get props => [history];
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final DramaRepository repository;

  HistoryBloc({required this.repository}) : super(HistoryInitial()) {
    on<LoadHistoryEvent>((event, emit) async {
      emit(HistoryLoading());
      try {
        final history = await repository.getHistory();
        emit(HistoryLoaded(history));
      } catch (e) {
        emit(HistoryError(e.toString()));
      }
    });

    on<AddHistoryEvent>((event, emit) async {
      try {
        await repository.saveHistory(event.history);
        // Refresh local state if already loaded
        if (state is HistoryLoaded) {
          final currentHistory = (state as HistoryLoaded).history;
          final updatedHistory = List<HistoryModel>.from(currentHistory);
          updatedHistory.removeWhere(
            (e) =>
                e.drama.bookId == event.history.drama.bookId &&
                e.provider == event.history.provider,
          );
          updatedHistory.insert(0, event.history);
          if (updatedHistory.length > 100) updatedHistory.removeLast();
          emit(HistoryLoaded(updatedHistory));
        } else {
          // If not loaded, just fetch fresh
          final history = await repository.getHistory();
          emit(HistoryLoaded(history));
        }
      } catch (e) {
        debugPrint("Error adding history: $e");
      }
    });
  }
}
