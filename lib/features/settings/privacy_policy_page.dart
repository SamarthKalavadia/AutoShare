import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Last updated: August 2026'),
            const SizedBox(height: 24),
            const Text('AutoShare respects your privacy. This Privacy Policy explains what information AutoShare collects, how it is used, how it is protected, and the choices available to you when using the AutoShare application.'),
            const SizedBox(height: 32),
            
            _buildSectionHeader('1. INFORMATION WE COLLECT'),
            const SizedBox(height: 16),
            const Text('Depending on how you use AutoShare, we may collect:'),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Name and profile information',
              'Email address and account information',
              'Profile picture',
              'User ID',
              'Ride information such as pickup, destination, date, time, seats and fare',
              'Location information when required for ride and location features',
              'Chat messages and communication data',
              'Device and technical information required to operate and secure the application',
              'Notification-related information required to deliver app notifications',
            ]),
            const SizedBox(height: 16),
            const Text('We only collect information that is reasonably necessary to provide and improve AutoShare\'s services.'),
            const SizedBox(height: 32),

            _buildSectionHeader('2. HOW WE USE YOUR INFORMATION'),
            const SizedBox(height: 16),
            const Text('We use your information to:'),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Create and manage your AutoShare account',
              'Provide Find Ride and Create Ride functionality',
              'Connect users travelling along similar routes',
              'Process ride requests and ride participation',
              'Enable communication between relevant ride partners',
              'Send ride, chat and account notifications',
              'Display your profile to relevant users',
              'Improve reliability, security and performance',
              'Prevent fraud, abuse and unauthorized use',
              'Respond to support requests',
              'Comply with applicable legal requirements',
            ]),
            const SizedBox(height: 32),

            _buildSectionHeader('3. LOCATION INFORMATION'),
            const SizedBox(height: 16),
            const Text('AutoShare may access precise location information when you use location-based features.'),
            const SizedBox(height: 16),
            const Text('Location may be used to:'),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Select pickup and drop-off locations',
              'Help find relevant rides',
              'Provide location-based ride functionality',
            ]),
            const SizedBox(height: 16),
            const Text('AutoShare does not use location for unrelated purposes.'),
            const SizedBox(height: 32),

            _buildSectionHeader('4. CHAT AND USER CONTENT'),
            const SizedBox(height: 16),
            const Text('When you use AutoShare\'s chat functionality, messages and related information may be stored and processed so that messages can be delivered and displayed to the intended participants.'),
            const SizedBox(height: 16),
            const Text('Users are responsible for the information and content they choose to share through the application.'),
            const SizedBox(height: 32),

            _buildSectionHeader('5. HOW WE SHARE INFORMATION'),
            const SizedBox(height: 16),
            const Text('AutoShare may use trusted service providers required to operate the application.'),
            const SizedBox(height: 16),
            const Text('These may include services provided by Google/Firebase and other infrastructure or technology providers used by AutoShare for functions such as:'),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Authentication',
              'Cloud data storage',
              'Profile image storage',
              'Push notifications',
              'Application infrastructure',
              'Maps and location-related services',
            ]),
            const SizedBox(height: 16),
            const Text('AutoShare does not sell your personal information.'),
            const SizedBox(height: 16),
            const Text('Information may also be disclosed when required by law, to protect users or the service, or to prevent fraud, abuse, or security threats.'),
            const SizedBox(height: 32),

            _buildSectionHeader('6. INFORMATION VISIBLE TO OTHER USERS'),
            const SizedBox(height: 16),
            const Text('Some information may be visible to other AutoShare users when required for the application\'s functionality.'),
            const SizedBox(height: 16),
            const Text('Depending on the feature, this may include:'),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Your name',
              'Profile picture',
              'Ride information',
              'Relevant ride details',
              'Information required to communicate with a ride partner',
            ]),
            const SizedBox(height: 16),
            const Text('AutoShare does not intentionally make private account information publicly available unless required for the service or permitted by you.'),
            const SizedBox(height: 32),

            _buildSectionHeader('7. DATA SECURITY'),
            const SizedBox(height: 16),
            const Text('AutoShare uses reasonable technical and organizational measures to protect user information against unauthorized access, loss, misuse, or disclosure.'),
            const SizedBox(height: 16),
            const Text('Data transmitted between the application and supported services is protected using appropriate security mechanisms.'),
            const SizedBox(height: 16),
            const Text('However, no internet-based service can guarantee absolute security.'),
            const SizedBox(height: 32),

            _buildSectionHeader('8. DATA RETENTION'),
            const SizedBox(height: 16),
            const Text('We retain information only for as long as reasonably necessary to provide AutoShare\'s services, maintain security, comply with legal obligations, resolve disputes, and enforce our policies.'),
            const SizedBox(height: 16),
            const Text('When information is no longer required, it may be deleted or securely handled according to applicable requirements.'),
            const SizedBox(height: 32),

            _buildSectionHeader('9. ACCOUNT AND DATA DELETION'),
            const SizedBox(height: 16),
            const Text('You can request deletion of your AutoShare account through the account deletion option available in the application.'),
            const SizedBox(height: 16),
            const Text('When an account deletion request is completed, associated personal information will be deleted or anonymized where required and where technically applicable.'),
            const SizedBox(height: 16),
            const Text('Certain information may be retained where necessary for legitimate purposes such as legal compliance, fraud prevention, security, or dispute resolution.'),
            const SizedBox(height: 32),

            _buildSectionHeader('10. CHILDREN\'S PRIVACY'),
            const SizedBox(height: 16),
            const Text('AutoShare is not intended for children who are not legally permitted to use the service.'),
            const SizedBox(height: 16),
            const Text('We do not knowingly collect personal information from children in violation of applicable law.'),
            const SizedBox(height: 32),

            _buildSectionHeader('11. THIRD-PARTY SERVICES'),
            const SizedBox(height: 16),
            const Text('AutoShare may use third-party services such as Google services and Firebase to provide authentication, cloud storage, notifications, maps, and other application functionality.'),
            const SizedBox(height: 16),
            const Text('Those services may process information according to their own privacy policies and applicable terms.'),
            const SizedBox(height: 32),

            _buildSectionHeader('12. YOUR CHOICES'),
            const SizedBox(height: 16),
            const Text('You may:'),
            const SizedBox(height: 8),
            _buildBulletPoints([
              'Update information in your profile',
              'Control available device permissions',
              'Manage notification permissions through your device',
              'Request deletion of your AutoShare account',
              'Contact AutoShare regarding privacy questions',
            ]),
            const SizedBox(height: 32),

            _buildSectionHeader('13. CHANGES TO THIS PRIVACY POLICY'),
            const SizedBox(height: 16),
            const Text('We may update this Privacy Policy when AutoShare\'s services or data practices change.'),
            const SizedBox(height: 16),
            const Text('When material changes are made, the "Last updated" date will be updated and appropriate notice may be provided through the application.'),
            const SizedBox(height: 32),

            _buildSectionHeader('14. CONTACT'),
            const SizedBox(height: 16),
            const Text('For privacy-related questions or requests, users may contact AutoShare through the official support/contact method provided by AutoShare.'),
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
