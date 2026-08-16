import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/models/request_model.dart';
import 'providers/incoming_requests_provider.dart';
import 'widgets/request_card.dart';

class RequestsPage extends ConsumerStatefulWidget {
  const RequestsPage({super.key});

  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends ConsumerState<RequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);

    final requestsAsync = ref.watch(incomingRequestsProvider);
    final isActionLoading = ref.watch(requestActionProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Requests',
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
                Tab(text: 'Pending'),
                Tab(text: 'Accepted'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          requestsAsync.when(
            data: (requests) {
              final pending = requests
                  .where((r) => r.request.status == RideRequestStatus.pending)
                  .toList();
              final accepted = requests
                  .where((r) => r.request.status == RideRequestStatus.accepted)
                  .toList();
              final rejected = requests
                  .where((r) => r.request.status == RideRequestStatus.rejected)
                  .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _RequestListView(requests: pending, type: 'pending'),
                  _RequestListView(requests: accepted, type: 'accepted'),
                  _RequestListView(requests: rejected, type: 'rejected'),
                ],
              );
            },
            loading: () =>
                Center(child: CircularProgressIndicator(color: primaryColor)),
            error: (err, stack) => Center(
              child: Text(
                'Failed to load requests\n$err',
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

class _RequestListView extends ConsumerWidget {
  final List<IncomingRequestData> requests;
  final String type;

  const _RequestListView({required this.requests, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pending'
                  ? Icons.hourglass_empty_rounded
                  : type == 'accepted'
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              size: 64,
              color: const Color(0xFFEAE5DD),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type requests',
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

  void _handleAccept(
    BuildContext context,
    WidgetRef ref,
    IncomingRequestData data,
  ) async {
    try {
      await ref.read(requestActionProvider.notifier).accept(data.request);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
      }
    }
  }

  void _handleReject(
    BuildContext context,
    WidgetRef ref,
    IncomingRequestData data,
  ) async {
    try {
      await ref.read(requestActionProvider.notifier).reject(data.request);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request rejected')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
      }
    }
  }
}
