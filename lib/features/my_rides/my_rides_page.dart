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

class _MyRidesPageState extends ConsumerState<MyRidesPage> {
  int _selectedSegment = 0;
  String _activityFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final blackColor = theme.colorScheme.onSurface;

    final ridesAsync = ref.watch(myRidesProvider);
    final requestsAsync = ref.watch(incomingRequestsProvider);
    final isActionLoading = ref.watch(rideActionProvider) || ref.watch(requestActionProvider);

    final pendingCount = requestsAsync.maybeWhen(
      data: (reqs) => reqs.where((r) => r.request.status.name == 'pending').length,
      orElse: () => 0,
    );

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
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildSegmentedControl(context, primaryColor, blackColor, pendingCount),
                const SizedBox(height: 12),
                if (_selectedSegment == 0) _buildFilterDropdown(context),
                Expanded(
                  child: _selectedSegment == 0 
                    ? _buildMyActivity(ridesAsync) 
                    : _buildRequests(requestsAsync, primaryColor),
                ),
              ],
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

  Widget _buildSegmentedControl(BuildContext context, Color primaryColor, Color blackColor, int pendingCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEAE5DD);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              title: 'My Activity',
              isSelected: _selectedSegment == 0,
              onTap: () => setState(() => _selectedSegment = 0),
              primaryColor: primaryColor,
              blackColor: blackColor,
            ),
          ),
          Expanded(
            child: _SegmentButton(
              title: 'Requests',
              isSelected: _selectedSegment == 1,
              badgeCount: pendingCount,
              onTap: () => setState(() => _selectedSegment = 1),
              primaryColor: primaryColor,
              blackColor: blackColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showFilterSheet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _activityFilter,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final filters = ['All', 'Created', 'Joined', 'Completed', 'Cancelled'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Filter Activity',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...filters.map((f) => ListTile(
                  title: Text(
                    f,
                    style: GoogleFonts.inter(
                      fontWeight: _activityFilter == f ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: _activityFilter == f ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    setState(() => _activityFilter = f);
                    Navigator.pop(context);
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyActivity(AsyncValue<List<MyRideData>> ridesAsync) {
    return ridesAsync.when(
      data: (allRides) {
        List<MyRideData> filtered = [];
        
        switch (_activityFilter) {
          case 'Created':
            filtered = allRides.where((r) => r.role == 'driver' && r.displayStatus == 'active' && !r.isPast).toList();
            break;
          case 'Joined':
            filtered = allRides.where((r) => r.role == 'passenger' && (r.displayStatus == 'joined' || r.displayStatus == 'pending') && !r.isPast).toList();
            break;
          case 'Completed':
            filtered = allRides.where((r) => r.displayStatus == 'completed' || (r.isPast && !['cancelled', 'rejected'].contains(r.displayStatus))).toList();
            break;
          case 'Cancelled':
            filtered = allRides.where((r) => ['cancelled', 'rejected'].contains(r.displayStatus)).toList();
            break;
          case 'All':
          default:
            filtered = allRides.toList();
            break;
        }

        return _RideListView(rides: filtered, type: _activityFilter.toLowerCase());
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Failed to load rides\n$err', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red)),
      ),
    );
  }

  Widget _buildRequests(AsyncValue<List<IncomingRequestData>> requestsAsync, Color primaryColor) {
    return requestsAsync.when(
      data: (requests) {
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
        child: Text('Failed to load requests\n$err', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.red)),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color blackColor;

  const _SegmentButton({
    required this.title,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
    required this.primaryColor,
    required this.blackColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF333333) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(10), // ~0.04 alpha
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? blackColor : (isDark ? Colors.white60 : const Color(0xFF6F6F72)),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black, // Always black text on yellow accent
                  ),
                ),
              ),
            ],
          ],
        ),
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
              type == 'all' ? 'No rides yet' : 'No $type rides',
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
