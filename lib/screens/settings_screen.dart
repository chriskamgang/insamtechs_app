import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    final List<SettingItem> settingItems = [
      SettingItem(
        title: l10n.editProfile,
        icon: Icons.person,
        iconColor: const Color(0xFF1E3A8A),
        onTap: () {
          Navigator.pushNamed(context, '/edit-profile');
        },
      ),
      SettingItem(
        title: l10n.language,
        icon: Icons.language,
        iconColor: const Color(0xFF1E3A8A),
        onTap: () {
          _showLanguageDialog(context, languageProvider, l10n);
        },
      ),
      SettingItem(
        title: l10n.paymentMethod,
        icon: Icons.credit_card,
        iconColor: const Color(0xFF1E3A8A),
        onTap: () {
          // Navigate to payment options
        },
      ),
      SettingItem(
        title: l10n.about,
        icon: Icons.description,
        iconColor: const Color(0xFF1E3A8A),
        onTap: () {
          // Navigate to terms and conditions
        },
      ),
      SettingItem(
        title: l10n.support,
        icon: Icons.help_outline,
        iconColor: const Color(0xFF1E3A8A),
        onTap: () {
          // Navigate to help center
        },
      ),
      SettingItem(
        title: 'Inviter des amis',
        icon: Icons.share,
        iconColor: const Color(0xFF1E3A8A),
        onTap: () {
          // Invite friends functionality
        },
      ),
      SettingItem(
        title: l10n.logout,
        icon: Icons.logout,
        iconColor: const Color(0xFF1E3A8A),
        onTap: () {
          _showLogoutDialog(context, l10n);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          l10n.settings,
          style: TextStyle(
            fontSize: screenWidth * 0.055,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Color(0xFF1E3A8A),
              size: 28,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.grey[400],
              size: 28,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Profile Picture
              CircleAvatar(
                radius: screenWidth * 0.12,
                backgroundImage: const AssetImage('assets/images/profile.jpg'),
                onBackgroundImageError: (exception, stackTrace) {},
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.7),
                  ),
                  child: Icon(
                    Icons.person,
                    size: screenWidth * 0.12,
                    color: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              // Settings List
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: settingItems.map((item) {
                    return _buildSettingTile(item, screenWidth);
                  }).toList(),
                ),
              ),

              SizedBox(height: screenHeight * 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(SettingItem item, double screenWidth) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.04,
          horizontal: screenWidth * 0.02,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: item.iconColor,
                size: 20,
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  static void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.changeLanguage,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.french),
                leading: Radio<String>(
                  value: 'fr',
                  groupValue: languageProvider.currentLocale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      languageProvider.changeLanguage(value);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.languageChanged)),
                      );
                    }
                  },
                ),
              ),
              ListTile(
                title: Text(l10n.english),
                leading: Radio<String>(
                  value: 'en',
                  groupValue: languageProvider.currentLocale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      languageProvider.changeLanguage(value);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.languageChanged)),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.logout,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('Êtes-vous sûr de vouloir vous déconnecter?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signin',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.logout,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SettingItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  SettingItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}