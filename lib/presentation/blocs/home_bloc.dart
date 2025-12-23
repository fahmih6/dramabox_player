import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/domain/repositories/drama_repository.dart';

// Events
abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchHomeDataEvent extends HomeEvent {}

class SearchDramasEvent extends HomeEvent {
  final String query;
  SearchDramasEvent(this.query);

  @override
  List<Object?> get props => [query];
}

// States
abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<DramaModel> trendingDramas;
  final List<DramaModel> latestDramas;
  final List<DramaModel> vipDramas;
  final List<DramaModel>? searchResults;

  HomeLoaded({
    required this.trendingDramas,
    required this.latestDramas,
    required this.vipDramas,
    this.searchResults,
  });

  HomeLoaded copyWith({
    List<DramaModel>? trendingDramas,
    List<DramaModel>? latestDramas,
    List<DramaModel>? vipDramas,
    List<DramaModel>? searchResults,
  }) {
    return HomeLoaded(
      trendingDramas: trendingDramas ?? this.trendingDramas,
      latestDramas: latestDramas ?? this.latestDramas,
      vipDramas: vipDramas ?? this.vipDramas,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object?> get props => [
    trendingDramas,
    latestDramas,
    vipDramas,
    searchResults,
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
    on<FetchHomeDataEvent>((event, emit) async {
      final cachedTrending = await repository.getCachedTrendingDramas() ?? [];
      final cachedLatest = await repository.getCachedLatestDramas() ?? [];
      final cachedVip = await repository.getCachedVipDramas() ?? [];

      var currentLoadedState = HomeLoaded(
        trendingDramas: cachedTrending,
        latestDramas: cachedLatest,
        vipDramas: cachedVip,
      );

      // Emit cached data immediately if any exists
      emit(currentLoadedState);

      try {
        await Future.wait([
          repository
              .getTrendingDramas()
              .then((dramas) {
                currentLoadedState = currentLoadedState.copyWith(
                  trendingDramas: dramas,
                );
                emit(currentLoadedState);
              })
              .catchError((_) {}),
          repository
              .getLatestDramas()
              .then((dramas) {
                currentLoadedState = currentLoadedState.copyWith(
                  latestDramas: dramas,
                );
                emit(currentLoadedState);
              })
              .catchError((_) {}),
          repository
              .getVipDramas()
              .then((dramas) {
                currentLoadedState = currentLoadedState.copyWith(
                  vipDramas: dramas,
                );
                emit(currentLoadedState);
              })
              .catchError((_) {}),
        ]);
      } catch (e) {
        if (state is! HomeLoaded) {
          emit(HomeError(e.toString()));
        }
      }
    });

    on<SearchDramasEvent>((event, emit) async {
      if (event.query.isEmpty) {
        add(FetchHomeDataEvent());
        return;
      }

      final currentState = state;
      List<DramaModel> trending = [];
      List<DramaModel> latest = [];
      List<DramaModel> vip = [];

      if (currentState is HomeLoaded) {
        trending = currentState.trendingDramas;
        latest = currentState.latestDramas;
        vip = currentState.vipDramas;
      }

      emit(HomeLoading());
      try {
        final searchResults = await repository.searchDramas(event.query);
        emit(
          HomeLoaded(
            trendingDramas: trending,
            latestDramas: latest,
            vipDramas: vip,
            searchResults: searchResults,
          ),
        );
      } catch (e) {
        emit(HomeError(e.toString()));
      }
    });
  }
}
