import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = info.version;
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
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF));
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final mutedText = isDark ? Colors.white60 : const Color(0xFF6F6F72);
    final primaryColor = theme.colorScheme.primary;

    Widget buildSectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: mutedText,
            letterSpacing: 1.2,
          ),
        ),
      );
    }

    Widget buildStepItem(String number, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0EDE9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildFeatureItem(IconData icon, String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildBenefitItem(String title, String description) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedText,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('About AutoShare'),
        centerTitle: false,
        backgroundColor: backgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AutoShare',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Smart Auto Ride Sharing',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AutoShare makes everyday travel simpler by connecting people travelling along similar routes and helping them share available auto-rickshaw seats.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: mutedText,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            // Content Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionHeader('About AutoShare'),
                  Text(
                    'AutoShare is a ride-sharing platform designed to make everyday auto travel more convenient and affordable. It helps people travelling in the same direction connect with each other and share available seats.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),

                  buildSectionHeader('How AutoShare Works'),
                  buildStepItem('01', 'Create or find a ride'),
                  buildStepItem('02', 'Choose your route and travel details'),
                  buildStepItem('03', 'Request or offer available seats'),
                  buildStepItem('04', 'Connect with your ride partner'),
                  buildStepItem('05', 'Travel together'),
                  const SizedBox(height: 32),

                  buildSectionHeader('Key Features'),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FractionallySizedBox(
                        widthFactor: 0.48,
                        child: buildFeatureItem(Icons.search_rounded, 'Find a Ride'),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.48,
                        child: buildFeatureItem(Icons.add_circle_outline_rounded, 'Create a Ride'),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.48,
                        child: buildFeatureItem(Icons.directions_car_filled_outlined, 'My Rides'),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.48,
                        child: buildFeatureItem(Icons.person_add_alt_1_outlined, 'Ride Requests'),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.48,
                        child: buildFeatureItem(Icons.chat_bubble_outline_rounded, 'Real-time Chat'),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.48,
                        child: buildFeatureItem(Icons.notifications_none_rounded, 'Notifications'),
                      ),
                      FractionallySizedBox(
                        widthFactor: 1.0,
                        child: buildFeatureItem(Icons.contacts_outlined, 'Driver Directory'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  buildSectionHeader('Why AutoShare'),
                  buildBenefitItem(
                    'Convenient',
                    'Find or share rides along routes that work for you.',
                  ),
                  buildBenefitItem(
                    'Affordable',
                    'Share available seats and make everyday travel more economical.',
                  ),
                  buildBenefitItem(
                    'Connected',
                    'Communicate with your ride partner through in-app chat.',
                  ),
                  buildBenefitItem(
                    'Simple',
                    'Everything needed for a shared ride is available in one place.',
                  ),
                  const SizedBox(height: 24),

                  buildSectionHeader('Version'),
                  Text(
                    _version.isNotEmpty ? 'AutoShare v$_version' : 'Loading version...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© ${DateTime.now().year} AutoShare',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedText,
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
