import 'package:flutter/material.dart';
import 'faq_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF4338CA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('images/profile_avatar.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Marcus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'marcus@example.com',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // Navigate to profile edit
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // FAQ Section
            _buildSettingsSection(
              context,
              title: 'FAQ',
              icon: Icons.help_outline,
              items: [
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'Frequently Asked Questions',
                  subtitle: 'Browse comprehensive documentation',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FAQScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              context,
              title: 'Contact Support',
              icon: Icons.contact_support_outlined,
              items: [
                _SettingsItem(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'support@scentsafe.com',
                  onTap: () {
                    _showContactDialog(
                        context, 'Email', 'support@scentsafe.com');
                  },
                ),
                _SettingsItem(
                  icon: Icons.phone_outlined,
                  title: 'Phone Support',
                  subtitle: '+1 (555) 123-4567',
                  onTap: () {
                    _showContactDialog(context, 'Phone', '+1 (555) 123-4567');
                  },
                ),
                _SettingsItem(
                  icon: Icons.language_outlined,
                  title: 'Website',
                  subtitle: 'www.scentsafe.com',
                  onTap: () {
                    _showContactDialog(context, 'Website', 'www.scentsafe.com');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // App Version
            Center(
              child: Text(
                'ScentSafe v1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_SettingsItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3250),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF3D4250)),
          // Section Items
          ...items.map((item) => _buildSettingsItem(item)),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(_SettingsItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1B2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFFFFD700),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context, String type, String value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3250),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.contact_mail,
                color: Color(0xFFFFD700),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              type,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'Email'
                  ? 'We typically respond within 24 hours.'
                  : type == 'Phone'
                      ? 'Available Mon-Fri, 9AM-6PM EST.'
                      : 'Visit us for documentation and guides.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Copy to clipboard or open
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard!'),
                  backgroundColor: Color(0xFF7C3AED),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Copy',
              style: TextStyle(color: Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3250),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Log Out',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? You will need to sign in again to access your account.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login screen
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
