import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _supportEmail = 'support@autoshare.com';

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'AutoShare Support Request',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (e) {
      debugPrint('Could not launch email: $e');
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

    final faqs = [
      {
        'q': 'How do I create a ride?',
        'a': 'To create a ride, go to the Home screen and tap "Create Ride". Enter your pickup location, drop-off destination, departure time, and available seats, then confirm your details.'
      },
      {
        'q': 'How do I find a ride?',
        'a': 'From the Home screen, tap "Find Ride". Enter your desired destination and you will see a list of available rides heading in that direction. You can also search directly from the Search tab.'
      },
      {
        'q': 'How do I request a seat?',
        'a': 'Once you find a suitable ride, tap on it to view details. Tap the "Request Seat" button at the bottom of the screen. The ride creator will receive a notification to accept or decline your request.'
      },
      {
        'q': 'How do I cancel a ride?',
        'a': 'Go to "My Rides" from the bottom navigation bar. Select the ride you want to cancel, and tap the options menu or "Cancel Ride" button at the bottom.'
      },
      {
        'q': 'How do ride requests work?',
        'a': 'When you create a ride, other users can request seats. You will receive a notification and can review these requests in the "Incoming Requests" section. Accepting a request automatically adds the passenger to your ride and opens a chat.'
      },
      {
        'q': 'How does chat work?',
        'a': 'Once a ride request is accepted, a chat room is created between the ride creator and the passenger. You can safely coordinate pickup details without sharing your personal phone number.'
      },
      {
        'q': 'How do notifications work?',
        'a': 'AutoShare sends push notifications and in-app alerts for new ride requests, request approvals/rejections, and new chat messages.'
      },
      {
        'q': 'How can I delete my account?',
        'a': 'Go to Profile > Privacy (or scroll to the bottom of the Profile page) and tap "Delete Account". Follow the prompts to permanently delete your data.'
      },
      {
        'q': 'How do I change my profile information?',
        'a': 'Go to the Profile tab and tap "Edit Profile". Here you can update your name, gender, bio, and profile picture.'
      },
      {
        'q': 'What should I do if I face a problem?',
        'a': 'If you experience an issue with a ride or user, you can use the Report feature on their profile. For technical issues or general assistance, please use the Contact Support button below.'
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: false,
        backgroundColor: backgroundColor,
        scrolledUnderElevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // FAQs
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: faqs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final faq = entry.value;
                        return Column(
                          children: [
                            Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent, // Remove default border
                              ),
                              child: ExpansionTile(
                                collapsedIconColor: mutedText,
                                iconColor: theme.colorScheme.primary,
                                title: Text(
                                  faq['q']!,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                childrenPadding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                ),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      faq['a']!,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: mutedText,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (index < faqs.length - 1)
                              Divider(height: 1, color: borderColor, indent: 16, endIndent: 16),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Support Section
                  Text(
                    'CONTACT SUPPORT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _launchEmail,
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Email Support'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _supportEmail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
