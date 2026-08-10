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

  bool get _isExpired =>
      widget.ride.departureTime.isBefore(DateTime.now());

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
    final disabledReason = _disabledReason;
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
              action: SnackBarAction(
                label: 'OK',
                textColor: primaryColor,
                onPressed: () => ref
                    .read(rideRequestProvider.notifier)
                    .clearError(),
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
                              final existingRequestAsync = ref.watch(currentRideRequestProvider(widget.ride.id));
                              final currentUser = ref.watch(authControllerProvider).value;
                              
                              if (currentUser == null) return const SizedBox.shrink();

                              return existingRequestAsync.when(
                                data: (request) {
                                  if (request != null && request.status == RideRequestStatus.accepted) {
                                    final driverAsync = ref.watch(userProfileProvider(widget.ride.driverId));
                                    
                                    return driverAsync.when(
                                      data: (driver) => SecurityInfoCard(
                                        ride: widget.ride,
                                        driver: driver,
                                        passenger: currentUser,
                                      ),
                                      loading: () => const Center(child: CircularProgressIndicator()),
                                      error: (err, stack) => Text('Error loading contact info: $err'),
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
          isLoading: state.isLoading,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFFFFDF7),
      scrolledUnderElevation: 0,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEAE5DD)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A121212), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Color(0xFF121212),
          ),
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Ride Details',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF121212),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEAE5DD)),
              boxShadow: const [
                BoxShadow(color: Color(0x0A121212), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(
              Icons.share_rounded,
              size: 18,
              color: Color(0xFF121212),
            ),
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
    required bool isLoading,
    required Color backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(top: BorderSide(color: Color(0xFFEAE5DD))),
        boxShadow: const [
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
                color: const Color(0xFFF6F5F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 6),
                  Text(
                    disabledReason,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: canRequest ? _onRequestPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF6C000),
                disabledBackgroundColor: const Color(0xFFEAE5DD),
                foregroundColor: const Color(0xFF121212),
                disabledForegroundColor: const Color(0xFFAAAAAA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
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
                  : Text(
                      _isOwnRide ? 'Your Ride' : 'Request Ride',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Privacy Notice Card ──────────────────────────────────────────────────────

class _PrivacyNoticeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBCBFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF3D5AFE)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Phone number and contact details are revealed only after the ride owner accepts your request.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF3949AB),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
