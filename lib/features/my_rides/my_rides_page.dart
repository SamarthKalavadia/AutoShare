import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/result.dart';
import '../requests/providers/incoming_requests_provider.dart';
import '../requests/widgets/request_card.dart';
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
    final requestsAsync = ref.watch(incomingRequestsProvider);
    final isActionLoading = ref.watch(rideActionProvider) || ref.watch(requestActionProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: blackColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
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
              
              final joined = allRides.where((r) => 
                  r.role == 'passenger' && (r.displayStatus == 'joined' || r.displayStatus == 'pending') && !r.isPast).toList();
                  
              final completed = allRides.where((r) => 
                  r.displayStatus == 'completed' || (r.isPast && !['cancelled', 'rejected'].contains(r.displayStatus))).toList();
                  
              final cancelled = allRides.where((r) => 
                  ['cancelled', 'rejected'].contains(r.displayStatus)).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _RideListView(rides: created, type: 'created'),
                  requestsAsync.when(
                    data: (requests) {
                      // Sort pending first
                      final sorted = List<IncomingRequestData>.from(requests)
                        ..sort((a, b) {
                          if (a.request.status.name == 'pending' && b.request.status.name != 'pending') return -1;
                          if (b.request.status.name == 'pending' && a.request.status.name != 'pending') return 1;
                          return b.request.requestedAt.compareTo(a.request.requestedAt);
                        });
                      return _IncomingRequestsView(requests: sorted);
                    },
                    loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
                    error: (err, stack) => Center(
                      child: Text(
                        'Failed to load requests\n$err',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: Colors.red),
                      ),
                    ),
                  ),
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
          VoidCallback? onDelete;

          if (data.role == 'driver' && data.displayStatus == 'active' && !data.isPast) {
            onCancel = () => _handleCancelRide(context, ref, data);
          } else if (data.role == 'passenger' && (data.displayStatus == 'pending' || data.displayStatus == 'joined') && !data.isPast) {
            onCancel = () => _handleCancelRequest(context, ref, data);
          }

          // Allow drivers to permanently delete their completed or cancelled rides
          if (data.role == 'driver' &&
              (data.displayStatus == 'completed' || data.displayStatus == 'cancelled')) {
            onDelete = () => _handleDeleteRide(context, ref, data);
          }

          return MyRideCard(
            data: data,
            onView: () {
              context.push('/ride-details', extra: data.ride);
            },
            onCancel: onCancel,
            onDelete: onDelete,
            onTrack: data.role == 'passenger' && data.displayStatus == 'pending'
                ? () {
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

  void _handleDeleteRide(BuildContext context, WidgetRef ref, MyRideData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Ride', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete this ride and all associated requests. This action cannot be undone.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(rideActionProvider.notifier).deleteMyRide(data.ride.id);
    if (!context.mounted) return;

    if (result is Success<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride deleted successfully.')),
      );
      // No need to manually invalidate — the Firestore stream auto-updates
    } else if (result is Failure<void>) {
      // Surface the real error message — do NOT pretend deletion succeeded
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCancelRide(BuildContext context, WidgetRef ref, MyRideData data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Ride', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this ride?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(rideActionProvider.notifier).cancelMyRide(data.ride.id);
    if (!context.mounted) return;

    if (result is Success<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride cancelled successfully.')),
      );
      ref.invalidate(myRidesProvider);
    } else if (result is Failure<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel ride: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCancelRequest(BuildContext context, WidgetRef ref, MyRideData data) async {
    if (data.request == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Request', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel your ride request?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(rideActionProvider.notifier).cancelMyRequest(data.request!);
    if (!context.mounted) return;

    if (result is Success<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request cancelled successfully.')),
      );
      ref.invalidate(myRidesProvider);
    } else if (result is Failure<void>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel request: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _IncomingRequestsView extends ConsumerWidget {
  final List<IncomingRequestData> requests;

  const _IncomingRequestsView({required this.requests});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Color(0xFFEAE5DD),
            ),
            const SizedBox(height: 16),
            Text(
              'No ride requests yet',
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
        ref.invalidate(incomingRequestsProvider);
      },
      color: const Color(0xFFF6C000),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final data = requests[index];
          return RequestCard(
            data: data,
            onAccept: () => _handleAccept(context, ref, data),
            onReject: () => _handleReject(context, ref, data),
          );
        },
      ),
    );
  }

  void _handleAccept(BuildContext context, WidgetRef ref, IncomingRequestData data) async {
    try {
      await ref.read(requestActionProvider.notifier).accept(data.request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  void _handleReject(BuildContext context, WidgetRef ref, IncomingRequestData data) async {
    try {
      await ref.read(requestActionProvider.notifier).reject(data.request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    }
  }
}
