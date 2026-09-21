import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/localization/app_localizations.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        // Strip any build numbers like "+1" or "(1)"
        final cleanVersion = info.version.split('+').first.split(' ').first;
        setState(() {
          _version = cleanVersion.isNotEmpty ? cleanVersion : '1.0.0';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _version = '1.0.0';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFFBF9F4);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF121212);
    final mutedText = isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6F6F72);
    final subtleText = isDark ? const Color(0xFF636366) : const Color(0xFF8E8E93);
    final primaryYellow = isDark ? const Color(0xFFFFC400) : const Color(0xFFD49A00);
    final dividerColor = isDark ? const Color(0xFF222224) : const Color(0xFFEAE5DD);
    final timelineNumberColor = isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC);
    final connectorColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    void handleBack() {
      if (context.canPop()) {
        context.pop();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/profile');
      }
    }

    return PopScope(
      canPop: context.canPop() || Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBack();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            context.l10n.aboutAutoShare,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          centerTitle: false,
          backgroundColor: backgroundColor,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: handleBack,
          ),
        ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ==========================================
              // 1. HERO SECTION (Centered Product Hero)
              // ==========================================
              Center(
                child: Column(
                  children: [
                    // Existing Full AutoShare Logo with clean rounded corners
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 84,
                        height: 84,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // App Title
                    Text(
                      'AutoShare',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Category Tagline
                    Text(
                      'Smart Auto Ride Sharing',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: primaryYellow,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Hero Hook
                    Text(
                      'Share the ride.\nSave the journey.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Supporting One-Liner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Connect with people travelling your way and share available auto-rickshaw seats.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: mutedText,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Subtle Divider
              Divider(color: dividerColor, height: 1, thickness: 1),

              const SizedBox(height: 44),

              // ==========================================
              // HOW IT WORKS (Vertical Process)
              // ==========================================
              _buildSectionHeader('HOW IT WORKS', subtleText),
              const SizedBox(height: 28),

              _buildTimelineStep(
                number: '01',
                title: 'Find or create a ride',
                isLast: false,
                textColor: textColor,
                numberColor: timelineNumberColor,
                connectorColor: connectorColor,
              ),
              _buildTimelineStep(
                number: '02',
                title: 'Choose your route',
                isLast: false,
                textColor: textColor,
                numberColor: timelineNumberColor,
                connectorColor: connectorColor,
              ),
              _buildTimelineStep(
                number: '03',
                title: 'Request or offer a seat',
                isLast: false,
                textColor: textColor,
                numberColor: timelineNumberColor,
                connectorColor: connectorColor,
              ),
              _buildTimelineStep(
                number: '04',
                title: 'Connect with your ride partner',
                isLast: false,
                textColor: textColor,
                numberColor: timelineNumberColor,
                connectorColor: connectorColor,
              ),
              _buildTimelineStep(
                number: '05',
                title: 'Travel together',
                isLast: true,
                textColor: textColor,
                numberColor: timelineNumberColor,
                connectorColor: connectorColor,
              ),

              const SizedBox(height: 48),

              // Subtle Divider
              Divider(color: dividerColor, height: 1, thickness: 1),

              const SizedBox(height: 44),

              // ==========================================
              // 4. KEY FEATURES (2-Column Grid)
              // ==========================================
              _buildSectionHeader('KEY FEATURES', subtleText),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureItem(
                          icon: Icons.search_rounded,
                          title: 'Find a Ride',
                          iconColor: primaryYellow,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          icon: Icons.electric_rickshaw_rounded,
                          title: 'My Rides',
                          iconColor: primaryYellow,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Real-time Chat',
                          iconColor: primaryYellow,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          icon: Icons.badge_outlined,
                          title: 'Driver Directory',
                          iconColor: primaryYellow,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureItem(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Create a Ride',
                          iconColor: primaryYellow,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          icon: Icons.group_outlined,
                          title: 'Ride Requests',
                          iconColor: primaryYellow,
                          textColor: textColor,
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureItem(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          iconColor: primaryYellow,
                          textColor: textColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Subtle Divider
              Divider(color: dividerColor, height: 1, thickness: 1),

              const SizedBox(height: 44),

              // ==========================================
              // 5. WHY AUTOSHARE (Value Statements)
              // ==========================================
              _buildSectionHeader('WHY AUTOSHARE', subtleText),
              const SizedBox(height: 24),

              _buildValueBenefit(
                title: 'Convenient',
                description: 'Find rides that fit your route.',
                accentColor: primaryYellow,
                textColor: textColor,
                mutedColor: mutedText,
              ),
              const SizedBox(height: 22),
              _buildValueBenefit(
                title: 'Affordable',
                description: 'Share available seats and travel economically.',
                accentColor: primaryYellow,
                textColor: textColor,
                mutedColor: mutedText,
              ),
              const SizedBox(height: 22),
              _buildValueBenefit(
                title: 'Connected',
                description: 'Stay connected with your ride partner.',
                accentColor: primaryYellow,
                textColor: textColor,
                mutedColor: mutedText,
              ),

              const SizedBox(height: 64),

              // ==========================================
              // 6. VERSION (Subtle Footer)
              // ==========================================
              Center(
                child: Text(
                  'AutoShare v$_version',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subtleText,
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
        color: color,
      ),
    );
  }

  Widget _buildTimelineStep({
    required String number,
    required String title,
    required bool isLast,
    required Color textColor,
    required Color numberColor,
    required Color connectorColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Text(
                  number,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: numberColor,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.only(bottom: 6),
                      color: connectorColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1, bottom: isLast ? 0 : 28),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildValueBenefit({
    required String title,
    required String description,
    required Color accentColor,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: mutedColor,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
