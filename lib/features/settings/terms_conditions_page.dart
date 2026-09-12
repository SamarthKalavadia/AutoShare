import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Last updated: August 2026'),
            const SizedBox(height: 24),
            const Text('Welcome to AutoShare. By creating an account or using the AutoShare application, you agree to these Terms & Conditions. If you do not agree, please do not use AutoShare.'),
            const SizedBox(height: 32),
            _buildSectionHeader('1. ABOUT AUTOSHARE'),
            const SizedBox(height: 16),
            const Text('AutoShare is a ride-sharing platform that connects people travelling in similar directions so they can find, offer, request, and share available auto-rickshaw seats.'),
            const SizedBox(height: 16),
            const Text('AutoShare provides the technology platform for connecting users. AutoShare does not operate or guarantee every individual ride arranged through the platform.'),
            const SizedBox(height: 32),
            
            _buildSectionHeader('2. USER ACCOUNTS'),
            const SizedBox(height: 16),
            const Text('Users must provide accurate information when creating and using an account.'),
            const SizedBox(height: 16),
            const Text('You are responsible for maintaining the security of your account and must not impersonate another person, create misleading accounts, or allow unauthorized use of your account.'),
            const SizedBox(height: 32),

            _buildSectionHeader('3. RIDES'),
            const SizedBox(height: 16),
            const Text('Ride creators are responsible for providing accurate ride information, including route, date, time, available seats, and fare where applicable.'),
            const SizedBox(height: 16),
            const Text('Passengers are responsible for reviewing ride information before requesting or joining a ride.'),
            const SizedBox(height: 16),
            const Text('A ride request is not confirmed until it is accepted through the application.'),
            const SizedBox(height: 32),

            _buildSectionHeader('4. CANCELLATIONS'),
            const SizedBox(height: 16),
            const Text('Users should cancel rides or requests as soon as possible when they can no longer participate.'),
            const SizedBox(height: 16),
            const Text('Repeated or abusive cancellations may result in restrictions on account or platform access.'),
            const SizedBox(height: 32),

            _buildSectionHeader('5. FARES'),
            const SizedBox(height: 16),
            const Text('Any fare displayed in AutoShare must be reviewed by users before confirming participation.'),
            const SizedBox(height: 16),
            const Text('AutoShare does not process or guarantee payment between users unless a payment feature is explicitly provided within the application.'),
            const SizedBox(height: 32),

            _buildSectionHeader('6. USER CONDUCT'),
            const SizedBox(height: 16),
            const Text('Users must treat other users respectfully and lawfully.'),
            const SizedBox(height: 16),
            const Text('You must not:'),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Harass, threaten, abuse, or discriminate against another user.',
              'Impersonate another person.',
              'Provide intentionally false ride or account information.',
              'Use AutoShare for illegal or fraudulent activities.',
              'Misuse chat or communication features.',
              'Attempt to access another user\'s account or data.',
              'Interfere with or misuse AutoShare\'s systems.',
            ]),
            const SizedBox(height: 32),

            _buildSectionHeader('7. SAFETY'),
            const SizedBox(height: 16),
            const Text('Users are responsible for following applicable traffic, transportation, and safety laws.'),
            const SizedBox(height: 16),
            const Text('Drivers must operate vehicles responsibly, and passengers must follow reasonable safety requirements.'),
            const SizedBox(height: 16),
            const Text('AutoShare cannot guarantee the identity, conduct, vehicle condition, or actions of every user and does not guarantee that every listed ride will take place.'),
            const SizedBox(height: 16),
            const Text('If you believe you are in immediate danger, contact the appropriate local emergency services.'),
            const SizedBox(height: 32),

            _buildSectionHeader('8. CHAT AND COMMUNICATION'),
            const SizedBox(height: 16),
            const Text('AutoShare provides communication features for relevant ride partners.'),
            const SizedBox(height: 16),
            const Text('Users must not use chat to send abusive, threatening, fraudulent, illegal, or unwanted content.'),
            const SizedBox(height: 16),
            const Text('AutoShare may take action against accounts that misuse communication features.'),
            const SizedBox(height: 32),

            _buildSectionHeader('9. ACCOUNT SUSPENSION'),
            const SizedBox(height: 16),
            const Text('AutoShare may restrict, suspend, or terminate an account if a user violates these Terms, engages in fraudulent or unsafe behavior, misuses the platform, or creates a risk to other users or the service.'),
            const SizedBox(height: 32),

            _buildSectionHeader('10. PLATFORM AVAILABILITY'),
            const SizedBox(height: 16),
            const Text('AutoShare aims to provide a reliable service but does not guarantee uninterrupted availability.'),
            const SizedBox(height: 16),
            const Text('The application may be temporarily unavailable because of maintenance, technical problems, network failures, third-party services, or circumstances outside AutoShare\'s reasonable control.'),
            const SizedBox(height: 32),

            _buildSectionHeader('11. USER RESPONSIBILITY'),
            const SizedBox(height: 16),
            const Text('Users are responsible for their own decisions, actions, belongings, and interactions when using AutoShare.'),
            const SizedBox(height: 16),
            const Text('AutoShare is a platform that facilitates connections between users and is not responsible for agreements or interactions outside the functionality provided by the application, except where applicable law requires otherwise.'),
            const SizedBox(height: 32),

            _buildSectionHeader('12. PRIVACY'),
            const SizedBox(height: 16),
            const Text('Your use of AutoShare is also governed by the AutoShare Privacy Policy, which explains how your information is collected, used, stored, and handled.'),
            const SizedBox(height: 32),

            _buildSectionHeader('13. ACCOUNT DELETION'),
            const SizedBox(height: 16),
            const Text('Users may request deletion of their AutoShare account through the account deletion option provided in the application.'),
            const SizedBox(height: 16),
            const Text('Account and associated data will be handled according to AutoShare\'s Privacy Policy and applicable legal requirements.'),
            const SizedBox(height: 32),

            _buildSectionHeader('14. CHANGES TO THESE TERMS'),
            const SizedBox(height: 16),
            const Text('AutoShare may update these Terms when necessary. Material changes may be communicated through the application.'),
            const SizedBox(height: 16),
            const Text('The "Last updated" date will be updated when these Terms are revised.'),
            const SizedBox(height: 32),

            _buildSectionHeader('15. CONTACT'),
            const SizedBox(height: 16),
            const Text('For questions regarding these Terms, users may use the support/contact method provided by AutoShare.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBulletPoints(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points.map((point) => Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(fontSize: 16)),
            Expanded(child: Text(point)),
          ],
        ),
      )).toList(),
    );
  }
}
