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
          _version = '${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {
      // Fallback if package_info_plus fails for some reason
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
    final cardColor =
        theme.cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF));
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFEAE5DD);
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final mutedText = isDark ? Colors.white70 : const Color(0xFF6F6F72);
    final primaryColor = theme.colorScheme.primary;

    Widget buildSection(String title, String content) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: mutedText,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildFeatureItem(String feature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Text(
              feature,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: textColor,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo / Identity
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                Icons.directions_car_filled_outlined,
                size: 64,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AutoShare',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Smart Auto Ride Sharing',
              style: theme.textTheme.titleMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '"AutoShare helps people travelling in the same direction share available auto-rickshaw seats, making everyday travel more convenient and affordable."',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: mutedText,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Content Sections wrapped in a clean card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSection(
                    'What is AutoShare?',
                    'AutoShare connects people travelling along similar routes so available seats in an auto-rickshaw can be shared.',
                  ),
                  
                  Text(
                    'HOW IT WORKS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        '1. Create or find a ride',
                        '2. Choose your route and travel details',
                        '3. Send or receive ride requests',
                        '4. Connect with your ride partner',
                        '5. Travel together'
                      ].map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          step,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            height: 1.5,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),

                  Text(
                    'KEY FEATURES',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildFeatureItem('Create a Ride'),
                  buildFeatureItem('Find a Ride'),
                  buildFeatureItem('Ride Requests'),
                  buildFeatureItem('Real-time Chat'),
                  buildFeatureItem('Notifications'),
                  buildFeatureItem('Driver Directory'),
                  buildFeatureItem('Profile & Account Management'),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Version Info
            if (_version.isNotEmpty)
              Text(
                'Version $_version',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: mutedText,
                  letterSpacing: 1.0,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '© ${DateTime.now().year} AutoShare',
              style: theme.textTheme.labelSmall?.copyWith(
                color: mutedText.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
