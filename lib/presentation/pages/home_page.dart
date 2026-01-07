import 'package:dramabox_free/core/constants/app_enums.dart';
import 'package:dramabox_free/data/models/drama_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dramabox_free/presentation/blocs/home_bloc.dart';
import 'package:dramabox_free/presentation/pages/player_page.dart';
import 'package:dramabox_free/presentation/pages/search_page.dart';
import 'package:dramabox_free/presentation/cubits/navigation_cubit.dart';
import 'package:dramabox_free/presentation/widgets/drama_shimmer_grid.dart';
import 'package:dramabox_free/presentation/widgets/drama_card.dart';
import 'package:dramabox_free/presentation/pages/history_page.dart';
import 'package:dramabox_free/presentation/blocs/history_bloc.dart';
import 'package:dramabox_free/core/services/shorebird_service.dart';
import 'package:dramabox_free/core/di/injection_container.dart';
import 'package:dramabox_free/domain/repositories/drama_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSectionIndex = 0;
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search dramas...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      final provider = context.read<NavigationCubit>().state;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SearchPage(query: value, provider: provider),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<NavigationCubit, AppContentProvider>(
        builder: (context, provider) {
          return IndexedStack(
            index: _selectedTabIndex == 2 ? 1 : 0,
            children: [
              // Home Content (Dramabox or Netshort)
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading) {
                    return const DramaShimmerGrid();
                  } else if (state is HomeLoaded) {
                    final sections = provider == AppContentProvider.dramabox
                        ? state.sectionsForDramabox
                        : state.sectionsForNetshort;

                    if (sections.isEmpty) {
                      return const DramaShimmerGrid();
                    }

                    // Ensure selected index is valid
                    if (_selectedSectionIndex >= sections.length) {
                      _selectedSectionIndex = 0;
                    }

                    return Column(
                      children: [
                        // Chip Menu
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sections.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedSectionIndex == index;
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedSectionIndex = index;
                                      });
                                    },
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey,
                                        fontSize: isSelected ? 20 : 18,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      child: Text(sections[index].name),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildDramaGrid(
                              sections[_selectedSectionIndex].dramas,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (state is HomeError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox();
                },
              ),
              // History Content
              const HistoryPage(),
            ],
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<ShorebirdUpdateStatus>(
            valueListenable: sl<ShorebirdService>().updateStatus,
            builder: (context, status, child) {
              return FutureBuilder<int?>(
                future: sl<ShorebirdService>().getCurrentPatchNumber(),
                builder: (context, snapshot) {
                  if (status == ShorebirdUpdateStatus.idle) {
                    return const SizedBox.shrink();
                  }

                  final patch = snapshot.data;
                  final versionText =
                      'v1.0.0+4${patch != null ? ' patch $patch' : ''}';
                  Widget statusWidget = const SizedBox.shrink();
                  Color? bgColor = Colors.black;

                  switch (status) {
                    case ShorebirdUpdateStatus.idle:
                      // Handled above
                      break;
                    case ShorebirdUpdateStatus.checking:
                      statusWidget = Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Checking for updates... ($versionText)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      );
                      break;
                    case ShorebirdUpdateStatus.downloading:
                      statusWidget = Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Downloading patch... ($versionText)',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                      break;
                    case ShorebirdUpdateStatus.readyToRestart:
                      bgColor = Colors.amber[900]?.withValues(alpha: 0.8);
                      statusWidget = const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.system_update_alt,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Update ready! Restart app to apply.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                      break;
                    case ShorebirdUpdateStatus.error:
                      statusWidget = Text(
                        'Update failed',
                        style: TextStyle(fontSize: 10, color: Colors.red[400]),
                      );
                      break;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: bgColor,
                    child: SafeArea(top: false, child: statusWidget),
                  );
                },
              );
            },
          ),
          BlocBuilder<NavigationCubit, AppContentProvider>(
            builder: (context, currentProvider) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(color: Colors.grey[900]!, width: 0.5),
                  ),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: _selectedTabIndex,
                  selectedItemColor: Colors.amber,
                  unselectedItemColor: Colors.grey[600],
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  type: BottomNavigationBarType.fixed,
                  onTap: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });

                    if (index == 2) {
                      // History tab selected
                      context.read<HistoryBloc>().add(LoadHistoryEvent());
                      return;
                    }

                    final newProvider = index == 0
                        ? AppContentProvider.dramabox
                        : AppContentProvider.netshort;
                    if (newProvider != currentProvider) {
                      context.read<NavigationCubit>().changeProvider(
                        newProvider,
                      );
                      context.read<HomeBloc>().add(
                        FetchHomeDataEvent(provider: newProvider),
                      );
                    }
                  },
                  items: [
                    BottomNavigationBarItem(
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity:
                                currentProvider ==
                                        AppContentProvider.dramabox &&
                                    _selectedTabIndex == 0
                                ? 1.0
                                : 0.6,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/icons/dramabox.png',
                                height: 26,
                                width: 26,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                      label: 'DramaBox',
                    ),
                    BottomNavigationBarItem(
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(
                            opacity:
                                currentProvider ==
                                        AppContentProvider.netshort &&
                                    _selectedTabIndex == 1
                                ? 1.0
                                : 0.6,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                'assets/icons/netshort.jpg',
                                height: 26,
                                width: 26,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                      label: 'Netshort',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.history_rounded, size: 26),
                      label: 'History',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDramaGrid(
    List<DramaModel> dramas, {
    bool showChapterCount = true,
  }) {
    return GridView.builder(
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
        final provider = context.read<NavigationCubit>().state;
        return DramaCard(
          drama: drama,
          provider: provider,
          showChapterCount: showChapterCount,
          lastWatchedFuture: sl<DramaRepository>().getLastWatchedIndex(
            drama.bookId,
            provider: provider,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlayerPage(drama: drama, provider: provider),
              ),
            );
          },
        );
      },
    );
  }
}
