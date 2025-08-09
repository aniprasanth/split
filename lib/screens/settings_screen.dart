import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:splitzy/utils/theme_provider.dart';
import 'package:splitzy/services/auth_service.dart';
import 'package:splitzy/services/local_storage_service.dart';
import 'package:splitzy/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final settings = await LocalStorageService.loadNotificationSettings();
      if (mounted) {
        setState(() {
          _notificationsEnabled = settings['expenseAdded'] ?? true;
        });
      }
    } catch (e) {
      // If loading fails, use default value
      if (mounted) {
        setState(() {
          _notificationsEnabled = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Section
          _buildProfileSection(context),

          const SizedBox(height: 24),

          // Preferences Section
          _buildSection(
            context,
            'Preferences',
            [
              _buildThemeToggle(context, themeProvider),
              _buildNotificationsToggle(context),
              _buildLanguageOption(context),
            ],
          ),

          const SizedBox(height: 24),

          // Account Section
          _buildSection(
            context,
            'Account',
            [
              _buildAccountOption(
                context,
                'Backup Data',
                Icons.backup_outlined,
                onTap: () => _showBackupDialog(context),
              ),
              _buildAccountOption(
                context,
                'Export Data',
                Icons.file_download_outlined,
                onTap: () => _exportData(context),
              ),
              _buildAccountOption(
                context,
                'Sign Out',
                Icons.logout_outlined,
                onTap: () => _showSignOutDialog(context),
                isDestructive: true,
              ),
              _buildAccountOption(
                context,
                'Delete Account',
                Icons.delete_forever_outlined,
                onTap: () => _showDeleteAccountDialog(context),
                isDestructive: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Information Section
          _buildSection(
            context,
            'App Information',
            [
              _buildAccountOption(
                context,
                'About Splitzy',
                Icons.info_outline,
                onTap: () => _showAboutDialog(context),
              ),
              _buildAccountOption(
                context,
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                onTap: () => _launchURL('https://yourapp.com/privacy'),
              ),
              _buildAccountOption(
                context,
                'Terms of Service',
                Icons.description_outlined,
                onTap: () => _launchURL('https://yourapp.com/terms'),
              ),
              _buildAccountOption(
                context,
                'Rate App',
                Icons.star_outline,
                onTap: () => _rateApp(),
              ),
              _buildAccountOption(
                context,
                'Share App',
                Icons.share_outlined,
                onTap: () => _shareApp(),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // App Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 30,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName.isNotEmpty == true ? user!.displayName : 'Your Name',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email.isNotEmpty == true ? user!.email : 'your@email.com',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editProfile(context),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeProvider themeProvider) {
    return ListTile(
      leading: Icon(
        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Dark Mode'),
      subtitle: Text(themeProvider.isDarkMode ? 'Enabled' : 'Disabled'),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.toggleTheme(value);
        },
      ),
    );
  }

  Widget _buildNotificationsToggle(BuildContext context) {
    return ListTile(
      leading: Icon(
        _notificationsEnabled ? Icons.notifications : Icons.notifications_off,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Notifications'),
      subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled'),
      trailing: Switch(
        value: _notificationsEnabled,
        onChanged: (value) async {
          // Capture context-dependent objects before async operations
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          
          setState(() {
            _notificationsEnabled = value;
          });

          // Save notification settings
          await LocalStorageService.saveNotificationSettings(
            expenseAdded: value,
            settlementAdded: value,
            groupInvite: value,
            reminderNotifications: value,
          );

          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(
                  value ? 'Notifications enabled' : 'Notifications disabled',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.language,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Language'),
      subtitle: const Text('English'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showLanguageDialog(context),
    );
  }

  Widget _buildAccountOption(
      BuildContext context,
      String title,
      IconData icon, {
        VoidCallback? onTap,
        bool isDestructive = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _editProfile(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to edit your profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(currentUser: currentUser),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: 'en',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('हिंदी (Hindi)'),
              value: 'hi',
              groupValue: 'en',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text('Backup your data to Google Drive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBackup();
            },
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    // Capture context-dependent objects before async operations
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (currentUser == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please sign in to export your data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting data...'),
            ],
          ),
        ),
      );

      // Simulate data export (in real app, this would export actual data)
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      navigator.pop(); // Close loading dialog

      // Create export data summary
      final exportData = '''
Splitzy Data Export
User: ${currentUser.displayName} (${currentUser.email})
Export Date: ${DateTime.now().toLocal()}

This export contains:
- User profile information
- Group memberships
- Expense history
- Settlement records

Note: This is a demo export. In the full version, actual data would be exported in CSV or JSON format.
      ''';

      // Share the export data
      SharePlus.instance.share(
        ShareParams(
          text: exportData,
          subject: 'Splitzy Data Export',
        ),
      );

    } catch (e) {
      if (mounted) {
        navigator.pop(); // Close loading dialog if open
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? You can sign back in anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Splitzy',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text('Splitzy makes it easy to split expenses with friends and family.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Create groups and add expenses'),
        const Text('• Track who owes what'),
        const Text('• Settle up with UPI payments'),
        const Text('• Export expense reports'),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    // Capture context-dependent objects before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      // Handle error
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  void _rateApp() async {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.yourapp.splitzy';
    const appStoreUrl = 'https://apps.apple.com/app/splitzy/id123456789';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Splitzy'),
        content: const Text('Help us improve by rating Splitzy on your app store!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _launchURL(playStoreUrl);
            },
            child: const Text('Play Store'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _launchURL(appStoreUrl);
            },
            child: const Text('App Store'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out Splitzy - the best app for splitting expenses with friends!\n\nDownload it now: https://play.google.com/store/apps/details?id=com.yourapp.splitzy',
        subject: 'Check out Splitzy!',
      ),
    );
  }

  Future<void> _performBackup() async {
    // Capture context-dependent objects before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please sign in to backup your data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating backup...'),
            ],
          ),
        ),
      );

      // Save current timestamp as last backup
      await LocalStorageService.saveLastSyncTime(DateTime.now());

      // Simulate backup process
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      navigator.pop(); // Close loading dialog

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Backup completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Close loading dialog if open
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Signing out...'),
            ],
          ),
        ),
      );

      await authService.signOut();

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Navigate to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      );

      // Delete account
      await authService.deleteAccount();

      if (!mounted) return;
      navigator.pop(); // Close loading dialog

      // Clear local storage
      await LocalStorageService.clearAll();

      // Sign out and redirect to login
      await authService.signOut();
      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        navigator.pop(); // Close loading dialog if open
        if (e.code == 'requires-recent-login') {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Please re-authenticate and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Account deletion failed: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Close loading dialog if open
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Account deletion failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  final dynamic currentUser;

  const _EditProfileDialog({required this.currentUser});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.displayName ?? '');
    _phoneController = TextEditingController(text: widget.currentUser.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            enabled: !_isLoading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    // Validate input
    final name = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    
    // Capture context-dependent objects before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (name.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate phone number if provided
    if (phoneNumber.isNotEmpty) {
      // You can import and use Validators.validatePhoneNumber here if needed
      // For now, basic validation
      if (phoneNumber.length < 10) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid phone number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await authService.updateUserProfile(
        name: name,
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : null,
      );

      if (!mounted) return;
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

