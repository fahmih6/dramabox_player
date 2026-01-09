import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dramabox_free/core/constants/app_enums.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:dramabox_free/presentation/blocs/home_bloc.dart';
import 'package:dramabox_free/presentation/widgets/drama_shimmer_grid.dart';
import 'package:dramabox_free/presentation/widgets/drama_card.dart';
import 'package:dramabox_free/presentation/pages/player_page.dart';
import 'package:dramabox_free/core/di/injection_container.dart';
import 'package:dramabox_free/domain/repositories/drama_repository.dart';

class SearchPage extends StatefulWidget {
  final String query;
  final AppContentProvider provider;

  const SearchPage({super.key, required this.query, required this.provider});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final HomeBloc _homeBloc;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _homeBloc = sl<HomeBloc>();
    _homeBloc.add(SearchDramasEvent(widget.query, provider: widget.provider));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _homeBloc.add(
        LoadMoreSearchEvent(_searchController.text, provider: widget.provider),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search dramas...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _homeBloc.add(
                    SearchDramasEvent(value, provider: widget.provider),
                  );
                }
              },
            ),
          ),
        ),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const DramaShimmerGrid();
            } else if (state is HomeLoaded) {
              final dramas = state.searchResults ?? [];
              if (dramas.isEmpty) {
                return const Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return Stack(
                children: [
                  _buildDramaGrid(dramas),
                  if (state.isLoadingMore)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else if (state is HomeError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildDramaGrid(List<DramaModel> dramas) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: dramas.length,
      itemBuilder: (context, index) {
        final drama = dramas[index];
        return DramaCard(
          drama: drama,
          provider: widget.provider,
          lastWatchedFuture: sl<DramaRepository>().getLastWatchedIndex(
            drama.bookId,
            provider: widget.provider,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlayerPage(drama: drama, provider: widget.provider),
              ),
            );
          },
        );
      },
    );
  }
}
