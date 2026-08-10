import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/search_ride_provider.dart';
import 'widgets/search_filter_card.dart';
import 'widgets/ride_card.dart';
import 'widgets/loading_shimmer.dart';
import 'widgets/empty_search.dart';
import 'widgets/ride_sort_bottom_sheet.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  String _currentSort = 'Earliest Departure';

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return RideSortBottomSheet(
          currentSort: _currentSort,
          onSortSelected: (sort) {
            setState(() {
              _currentSort = sort;
            });
            ref.read(searchRideProvider.notifier).sortRides(sort);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final blackColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);

    final state = ref.watch(searchRideProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: backgroundColor,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 4,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: blackColor),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Find Ride',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: blackColor,
              ),
            ),
            centerTitle: true,
          ),
          
          // Subtitle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Discover rides travelling your way.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: mutedText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Filter Card
          const SliverToBoxAdapter(
            child: SearchFilterCard(),
          ),

          // Results Header (Only if results exist or loading)
          if (state.isLoading || state.searchResults.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Rides',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: blackColor,
                      ),
                    ),
                    if (!state.isLoading)
                      InkWell(
                        onTap: _showSortBottomSheet,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFEAE5DD)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.sort_rounded, size: 16, color: blackColor),
                              const SizedBox(width: 6),
                              Text(
                                'Sort',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: blackColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Results List
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: LoadingShimmer(),
            )
          else if (state.searchResults.isEmpty && state.hasSearched)
            const SliverToBoxAdapter(
              child: EmptySearch(),
            )
          else if (state.searchResults.isEmpty && !state.hasSearched)
            const SliverToBoxAdapter(
              child: SizedBox.shrink(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ride = state.searchResults[index];
                    return RideCard(
                      key: ValueKey(ride.id),
                      ride: ride,
                    );
                  },
                  childCount: state.searchResults.length,
                ),
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
