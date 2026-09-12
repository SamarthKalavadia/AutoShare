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
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final mutedText = isDark ? Colors.white54 : const Color(0xFF757575);
    final primaryColor = theme.colorScheme.primary;

    Widget buildSectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: mutedText,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    Widget buildTimelineItem(String number, String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: mutedText,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildFeatureItem(String title) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.horizontal_rule_rounded, size: 12, color: primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildWhyItem(String title, String description) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
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
        title: Text(
          'About AutoShare',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: false,
        backgroundColor: backgroundColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // BRAND HERO
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'AutoShare',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart Auto Ride Sharing',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 48),

              // BIO
              Text(
                'Share the ride. Save the journey.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect with people travelling your way and share available auto-rickshaw seats.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: mutedText,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 120), // Generous whitespace for the first screen fold

              // HOW IT WORKS
              buildSectionHeader('How It Works'),
              buildTimelineItem('01', 'Find or create a ride'),
              buildTimelineItem('02', 'Choose your route'),
              buildTimelineItem('03', 'Request or offer a seat'),
              buildTimelineItem('04', 'Connect with your ride partner'),
              buildTimelineItem('05', 'Travel together'),

              const SizedBox(height: 64),

              // KEY FEATURES
              buildSectionHeader('Key Features'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFeatureItem('Find a Ride'),
                        buildFeatureItem('My Rides'),
                        buildFeatureItem('Chat'),
                        buildFeatureItem('Driver Directory'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildFeatureItem('Create a Ride'),
                        buildFeatureItem('Ride Requests'),
                        buildFeatureItem('Notifications'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 64),

              // WHY AUTOSHARE
              buildSectionHeader('Why AutoShare'),
              buildWhyItem('Convenient', 'Find rides that fit your route.'),
              buildWhyItem('Affordable', 'Share available seats and travel economically.'),
              buildWhyItem('Connected', 'Stay connected with your ride partner.'),

              const SizedBox(height: 80),

              // VERSION
              Center(
                child: Text(
                  _version.isNotEmpty ? 'AutoShare v$_version' : 'Loading version...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedText,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
