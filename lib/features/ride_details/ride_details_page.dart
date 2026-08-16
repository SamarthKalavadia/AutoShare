import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/ride_model.dart';
import '../../data/models/request_model.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'providers/ride_request_provider.dart';
import 'providers/driver_profile_provider.dart';
import '../my_rides/providers/my_rides_provider.dart';
import 'widgets/driver_info_card.dart';
import 'widgets/route_info_card.dart';
import 'widgets/ride_info_card.dart';
import 'widgets/request_success_dialog.dart';
import 'widgets/security_info_card.dart';

class RideDetailsPage extends ConsumerStatefulWidget {
  final RideModel ride;

  const RideDetailsPage({super.key, required this.ride});

  @override
  ConsumerState<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends ConsumerState<RideDetailsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

    // Start entrance animation after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fadeCtrl.forward());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Derived helpers ────────────────────────────────────────────────────────

  bool get _isOwnRide {
    final uid = ref.read(authControllerProvider).value?.uid ?? '';
    return widget.ride.driverId == uid;
  }

  bool get _isExpired => widget.ride.departureTime.isBefore(DateTime.now());

  bool get _isClosed =>
      widget.ride.status == 'completed' || widget.ride.status == 'cancelled';

  String? get _disabledReason {
    if (_isOwnRide) return 'This is your own ride';
    if (_isClosed) {
      return widget.ride.status == 'completed'
          ? 'Ride already completed'
          : 'Ride was cancelled';
    }
    if (_isExpired) return 'Ride has already departed';
    if (widget.ride.availableSeats <= 0) return 'No seats available';
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _onRequestPressed() async {
    HapticFeedback.mediumImpact();
    await ref.read(rideRequestProvider.notifier).submitRequest(widget.ride);

    if (!mounted) return;

    final state = ref.read(rideRequestProvider);
    if (state.isSuccess) {
      await showRequestSuccessDialog(context);
      if (mounted) context.pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;

    final state = ref.watch(rideRequestProvider);
    final existingReqAsync = ref.watch(
      currentRideRequestProvider(widget.ride.id),
    );
    final existingReq = existingReqAsync.value;

    String? disabledReason = _disabledReason;
    if (disabledReason == null && existingReq != null) {
      if (existingReq.status == RideRequestStatus.pending) {
        disabledReason = 'Request Pending - Waiting for driver response';
      } else if (existingReq.status == RideRequestStatus.accepted) {
        disabledReason = 'Request Accepted - You have joined this ride';
      }
    }

    final canRequest = disabledReason == null && !state.isLoading;

    // Listen for error messages to show snackbar.
    ref.listen(rideRequestProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                next.error!,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              backgroundColor: const Color(0xFF1C1C1E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'OK',
                textColor: primaryColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
      }
    });

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          DriverInfoCard(ride: widget.ride),
                          const SizedBox(height: 16),
                          RouteInfoCard(ride: widget.ride),
                          const SizedBox(height: 16),
                          RideInfoCard(ride: widget.ride),
                          const SizedBox(height: 16),

                          // Security or Privacy notice card
                          Consumer(
                            builder: (context, ref, _) {
                              final existingRequestAsync = ref.watch(
                                currentRideRequestProvider(widget.ride.id),
                              );
                              final currentUser = ref
                                  .watch(authControllerProvider)
                                  .value;

                              if (currentUser == null)
                                return const SizedBox.shrink();

                              return existingRequestAsync.when(
                                data: (request) {
                                  if (request != null &&
                                      request.status ==
                                          RideRequestStatus.accepted) {
                                    final driverAsync = ref.watch(
                                      userProfileProvider(widget.ride.driverId),
                                    );

                                    return driverAsync.when(
                                      data: (driver) => SecurityInfoCard(
                                        ride: widget.ride,
                                        driver: driver,
                                        passenger: currentUser,
                                      ),
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (err, stack) => Text(
                                        'Error loading contact info: $err',
                                      ),
                                    );
                                  }

                                  return _PrivacyNoticeCard();
                                },
                                loading: () => _PrivacyNoticeCard(),
                                error: (err, stack) => _PrivacyNoticeCard(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),

        // Sticky bottom button
        bottomSheet: _buildBottomButton(
          context: context,
          canRequest: canRequest,
          disabledReason: disabledReason,
          existingReq: existingReq,
          isLoading: state.isLoading,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final iconBg = isDark ? const Color(0xFF28282A) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final iconColor = theme.colorScheme.onSurface;

    return SliverAppBar(
      backgroundColor: backgroundColor,
      scrolledUnderElevation: 0,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : const [
                    BoxShadow(
                      color: Color(0x0A121212),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: iconColor,
          ),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text(
        'Ride Details',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
              boxShadow: isDark
                  ? []
                  : const [
                      BoxShadow(
                        color: Color(0x0A121212),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(Icons.share_rounded, size: 18, color: iconColor),
          ),
          onPressed: () {
            // Share functionality can be wired to share_plus package later.
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Bottom Button ──────────────────────────────────────────────────────────

  Widget _buildBottomButton({
    required BuildContext context,
    required bool canRequest,
    required String? disabledReason,
    required RideRequestModel? existingReq,
    required bool isLoading,
    required Color backgroundColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFEAE5DD);
    final disabledBg = isDark
        ? const Color(0xFF28282A)
        : const Color(0xFFF3F3F3);

    String buttonLabel = 'Request Ride';
    if (_isOwnRide) {
      buttonLabel = 'Your Ride';
    } else if (existingReq != null) {
      buttonLabel = existingReq.status == RideRequestStatus.accepted
          ? 'Already Joined'
          : 'Request Pending';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  color: Color(0x12121212),
                  blurRadius: 20,
                  offset: Offset(0, -8),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (disabledReason != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: disabledBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    disabledReason,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (existingReq != null &&
              existingReq.status == RideRequestStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            'Cancel Request',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            'Are you sure you want to cancel your request for this ride?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel Request'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref
                            .read(rideActionProvider.notifier)
                            .cancelMyRequest(existingReq);
                        ref.invalidate(
                          currentRideRequestProvider(widget.ride.id),
                        );
                        ref.invalidate(myRidesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request cancelled successfully.'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Text(
                      'Cancel Request',
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withAlpha(120),
                      foregroundColor: const Color(0xFF121212),
                      disabledForegroundColor: const Color(0xFF121212),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Requested',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canRequest ? _onRequestPressed : null,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: disabledBg,
                  foregroundColor: const Color(0xFF121212),
                  disabledForegroundColor: isDark
                      ? Colors.white30
                      : const Color(0xFFAAAAAA),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF121212),
                        ),
                      )
                    : Text(buttonLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Privacy Notice Card ──────────────────────────────────────────────────────

class _PrivacyNoticeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C223A) : const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF283593) : const Color(0xFFBBCBFF),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: isDark ? const Color(0xFF7986CB) : const Color(0xFF3D5AFE),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Phone number and contact details are revealed only after the ride owner accepts your request.',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w400,
                color: isDark
                    ? const Color(0xFFC5CAE9)
                    : const Color(0xFF3949AB),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
