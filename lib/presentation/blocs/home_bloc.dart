import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dramabox_free/core/constants/app_enums.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/data/models/drama_section_model.dart';
import 'package:dramabox_free/domain/repositories/drama_repository.dart';

// Events
abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchHomeDataEvent extends HomeEvent {
  final AppContentProvider provider;
  final bool forceRefresh;
  FetchHomeDataEvent({
    this.provider = AppContentProvider.dramabox,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [provider, forceRefresh];
}

class PreloadAllEvent extends HomeEvent {}

class SearchDramasEvent extends HomeEvent {
  final String query;
  final AppContentProvider provider;
  SearchDramasEvent(this.query, {this.provider = AppContentProvider.dramabox});

  @override
  List<Object?> get props => [query, provider];
}

// States
abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final Map<AppContentProvider, List<DramaSectionModel>> providerSections;
  final List<DramaModel>? searchResults;

  HomeLoaded({required this.providerSections, this.searchResults});

  List<DramaSectionModel> get sectionsForDramabox =>
      providerSections[AppContentProvider.dramabox] ?? [];
  List<DramaSectionModel> get sectionsForNetshort =>
      providerSections[AppContentProvider.netshort] ?? [];

  HomeLoaded copyWith({
    Map<AppContentProvider, List<DramaSectionModel>>? providerSections,
    List<DramaModel>? searchResults,
  }) {
    return HomeLoaded(
      providerSections: providerSections ?? this.providerSections,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object?> get props => [providerSections, searchResults];
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final DramaRepository repository;

  HomeBloc({required this.repository}) : super(HomeInitial()) {
    on<PreloadAllEvent>((event, emit) async {
      final providers = [
        AppContentProvider.dramabox,
        AppContentProvider.netshort,
      ];

      Map<AppContentProvider, List<DramaSectionModel>> sectionsMap = {};
      if (state is HomeLoaded) {
        sectionsMap = Map.of((state as HomeLoaded).providerSections);
      }

      // 1. Load cached for both first
      for (final provider in providers) {
        final cached = await repository.getCachedHomeSections(
          provider: provider,
        );
        if (cached != null && cached.isNotEmpty) {
          sectionsMap[provider] = cached;
        }
      }

      if (sectionsMap.isNotEmpty) {
        emit(HomeLoaded(providerSections: sectionsMap));
      } else {
        emit(HomeLoading());
      }

      // 2. Fetch fresh for both
      await Future.wait(
        providers.map((provider) async {
          try {
            final sections = await repository.getHomeSections(
              provider: provider,
            );
            sectionsMap[provider] = sections;
            // We can't emit inside group comfortably if we want atomic updates,
            // but for preloading we can emit as each finishes.
            if (state is HomeLoaded) {
              emit(
                HomeLoaded(
                  providerSections: Map.of(sectionsMap),
                  searchResults: (state as HomeLoaded).searchResults,
                ),
              );
            } else {
              emit(HomeLoaded(providerSections: Map.of(sectionsMap)));
            }
          } catch (e) {
            debugPrint("Error preloading $provider: $e");
          }
        }),
      );
    });

    on<FetchHomeDataEvent>((event, emit) async {
      final provider = event.provider;

      if (state is! HomeLoaded) {
        emit(HomeLoading());
      }

      try {
        final sections = await repository.getHomeSections(provider: provider);
        final sectionsMap = state is HomeLoaded
            ? Map.of((state as HomeLoaded).providerSections)
            : <AppContentProvider, List<DramaSectionModel>>{};

        sectionsMap[provider] = sections;

        if (state is HomeLoaded) {
          emit((state as HomeLoaded).copyWith(providerSections: sectionsMap));
        } else {
          emit(HomeLoaded(providerSections: sectionsMap));
        }
      } catch (e) {
        if (state is! HomeLoaded) {
          emit(HomeError(e.toString()));
        }
      }
    });

    on<SearchDramasEvent>((event, emit) async {
      final provider = event.provider;
      if (event.query.isEmpty) {
        add(FetchHomeDataEvent(provider: provider));
        return;
      }

      final currentState = state;

      emit(HomeLoading());
      try {
        final searchResults = await repository.searchDramas(
          event.query,
          provider: provider,
        );
        final sectionsMap = currentState is HomeLoaded
            ? currentState.providerSections
            : <AppContentProvider, List<DramaSectionModel>>{};

        emit(
          HomeLoaded(
            providerSections: sectionsMap,
            searchResults: searchResults,
          ),
        );
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }
}
