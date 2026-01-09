import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
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

class LoadMoreHomeDataEvent extends HomeEvent {
  final AppContentProvider provider;
  final int sectionIndex;
  LoadMoreHomeDataEvent({required this.provider, required this.sectionIndex});

  @override
  List<Object?> get props => [provider, sectionIndex];
}

class PreloadAllEvent extends HomeEvent {}

class SearchDramasEvent extends HomeEvent {
  final String query;
  final AppContentProvider provider;
  SearchDramasEvent(this.query, {this.provider = AppContentProvider.dramabox});

  @override
  List<Object?> get props => [query, provider];
}

class LoadMoreSearchEvent extends HomeEvent {
  final String query;
  final AppContentProvider provider;
  LoadMoreSearchEvent(this.query, {required this.provider});

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
  final int searchPage;
  final bool searchHasMore;
  final bool isLoadingMore;

  HomeLoaded({
    required this.providerSections,
    this.searchResults,
    this.searchPage = 1,
    this.searchHasMore = true,
    this.isLoadingMore = false,
  });

  List<DramaSectionModel> get sectionsForDramabox =>
      providerSections[AppContentProvider.dramabox] ?? [];
  List<DramaSectionModel> get sectionsForNetshort =>
      providerSections[AppContentProvider.netshort] ?? [];

  HomeLoaded copyWith({
    Map<AppContentProvider, List<DramaSectionModel>>? providerSections,
    List<DramaModel>? searchResults,
    int? searchPage,
    bool? searchHasMore,
    bool? isLoadingMore,
  }) {
    return HomeLoaded(
      providerSections: providerSections ?? this.providerSections,
      searchResults: searchResults ?? this.searchResults,
      searchPage: searchPage ?? this.searchPage,
      searchHasMore: searchHasMore ?? this.searchHasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    providerSections,
    searchResults,
    searchPage,
    searchHasMore,
    isLoadingMore,
  ];
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
            if (state is HomeLoaded) {
              final s = state as HomeLoaded;
              emit(
                s.copyWith(
                  providerSections: Map.of(sectionsMap),
                  searchResults: s.searchResults,
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

    on<LoadMoreHomeDataEvent>((event, emit) async {
      final s = state;
      if (s is! HomeLoaded || s.isLoadingMore) return;

      final sections = List<DramaSectionModel>.from(
        s.providerSections[event.provider] ?? [],
      );
      if (event.sectionIndex >= sections.length) return;

      final section = sections[event.sectionIndex];
      if (!section.hasMore) return;

      emit(s.copyWith(isLoadingMore: true));

      try {
        final nextPage = section.currentPage + 1;
        List<DramaModel> moreDramas = [];

        if (event.provider == AppContentProvider.dramabox) {
          if (section.name == 'Latest') {
            moreDramas = await repository.getLatestDramas(
              provider: event.provider,
              page: nextPage,
            );
          } else if (section.name == 'Trending') {
            moreDramas = await repository.getTrendingDramas(
              provider: event.provider,
              page: nextPage,
            );
          } else if (section.name == 'VIP') {
            moreDramas = await repository.getVipDramas(
              provider: event.provider,
              page: nextPage,
            );
          }
        } else {
          // Netshort Theater/ForYou uses same endpoint usually or we can generalize
          moreDramas = await repository.getLatestDramas(
            provider: event.provider,
            page: nextPage,
          );
        }

        if (moreDramas.isEmpty) {
          sections[event.sectionIndex] = section.copyWith(hasMore: false);
        } else {
          sections[event.sectionIndex] = section.copyWith(
            dramas: [...section.dramas, ...moreDramas],
            currentPage: nextPage,
            hasMore: moreDramas.length >= 10, // Assuming page size is 10
          );
        }

        final sectionsMap = Map<AppContentProvider, List<DramaSectionModel>>.of(
          s.providerSections,
        );
        sectionsMap[event.provider] = sections;

        emit(s.copyWith(providerSections: sectionsMap, isLoadingMore: false));
      } catch (e) {
        emit(s.copyWith(isLoadingMore: false));
      }
    }, transformer: droppable());

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
          page: 1,
        );
        final sectionsMap = currentState is HomeLoaded
            ? currentState.providerSections
            : <AppContentProvider, List<DramaSectionModel>>{};

        emit(
          HomeLoaded(
            providerSections: sectionsMap,
            searchResults: searchResults,
            searchPage: 1,
            searchHasMore: searchResults.length >= 10,
          ),
        );
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });

    on<LoadMoreSearchEvent>((event, emit) async {
      final s = state;
      if (s is! HomeLoaded || s.isLoadingMore || !s.searchHasMore) return;

      emit(s.copyWith(isLoadingMore: true));

      try {
        final nextPage = s.searchPage + 1;
        final moreResults = await repository.searchDramas(
          event.query,
          provider: event.provider,
          page: nextPage,
        );

        if (moreResults.isEmpty) {
          emit(s.copyWith(searchHasMore: false, isLoadingMore: false));
        } else {
          emit(
            s.copyWith(
              searchResults: [...(s.searchResults ?? []), ...moreResults],
              searchPage: nextPage,
              searchHasMore: moreResults.length >= 10,
              isLoadingMore: false,
            ),
          );
        }
      } catch (e) {
        emit(s.copyWith(isLoadingMore: false));
      }
    }, transformer: droppable());
  }
}
