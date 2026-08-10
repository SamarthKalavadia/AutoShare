import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/my_rides_provider.dart';
import 'widgets/my_ride_card.dart';

class MyRidesPage extends ConsumerStatefulWidget {
  const MyRidesPage({super.key});

  @override
  ConsumerState<MyRidesPage> createState() => _MyRidesPageState();
}

class _MyRidesPageState extends ConsumerState<MyRidesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final blackColor = theme.colorScheme.onSurface;
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);

    final ridesAsync = ref.watch(myRidesProvider);
    final isActionLoading = ref.watch(rideActionProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Rides',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: blackColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: blackColor,
              unselectedLabelColor: mutedText,
              labelStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Created'),
                Tab(text: 'Requested'),
                Tab(text: 'Joined'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          ridesAsync.when(
            data: (allRides) {
              final created = allRides.where((r) => 
                  r.role == 'driver' && r.displayStatus == 'active' && !r.isPast).toList();
              
              final requested = allRides.where((r) => 
                  r.role == 'passenger' && r.displayStatus == 'pending' && !r.isPast).toList();
                  
              final joined = allRides.where((r) => 
                  r.displayStatus == 'joined' && !r.isPast).toList();
                  
              final completed = allRides.where((r) => 
                  r.displayStatus == 'completed' || (r.isPast && !['cancelled', 'rejected'].contains(r.displayStatus))).toList();
                  
              final cancelled = allRides.where((r) => 
                  ['cancelled', 'rejected'].contains(r.displayStatus)).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _RideListView(rides: created, type: 'created'),
                  _RideListView(rides: requested, type: 'requested'),
                  _RideListView(rides: joined, type: 'joined'),
                  _RideListView(rides: completed, type: 'completed'),
                  _RideListView(rides: cancelled, type: 'cancelled'),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
            error: (err, stack) => Center(
              child: Text(
                'Failed to load rides\n$err',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.red),
              ),
            ),
          ),
          if (isActionLoading)
            Container(
              color: Colors.black.withAlpha(26), // ~0.1 alpha
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }
}

class _RideListView extends ConsumerWidget {
  final List<MyRideData> rides;
  final String type;

  const _RideListView({required this.rides, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForType(type),
              size: 64,
              color: const Color(0xFFEAE5DD),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type rides',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6F6F72),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myRidesProvider);
      },
      color: const Color(0xFFF6C000),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final data = rides[index];

          // Determine callbacks
          VoidCallback? onCancel;
          if (data.role == 'driver' && data.displayStatus == 'active' && !data.isPast) {
            onCancel = () => _handleCancelRide(context, ref, data);
          } else if (data.role == 'passenger' && (data.displayStatus == 'pending' || data.displayStatus == 'joined') && !data.isPast) {
            onCancel = () => _handleCancelRequest(context, ref, data);
          }

          return MyRideCard(
            data: data,
            onView: () {
              context.push('/ride-details', extra: data.ride);
            },
            onCancel: onCancel,
            onTrack: data.role == 'passenger' && data.displayStatus == 'pending'
                ? () {
                    // TODO: Optional track status UI
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Your request is still pending approval.')),
                    );
                  }
                : null,
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'created':
        return Icons.directions_car_filled_outlined;
      case 'requested':
        return Icons.hourglass_empty_rounded;
      case 'joined':
        return Icons.group_add_outlined;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'cancelled':
      default:
        return Icons.cancel_outlined;
    }
  }

  void _handleCancelRide(BuildContext context, WidgetRef ref, MyRideData data) async {
    try {
      await ref.read(rideActionProvider.notifier).cancelMyRide(data.ride.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel ride: $e')),
        );
      }
    }
  }

  void _handleCancelRequest(BuildContext context, WidgetRef ref, MyRideData data) async {
    if (data.request == null) return;
    try {
      await ref.read(rideActionProvider.notifier).cancelMyRequest(data.request!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel request: $e')),
        );
      }
    }
  }
}
