import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/language_provider.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late PrivacySettings _settings;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _settings = auth.userModel?.privacy ?? const PrivacySettings();
  }

  Future<void> _save() async {
    await context.read<AuthProvider>().updatePrivacy(_settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Privacy settings saved'),
        backgroundColor: AppColors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Who can contact me?', Icons.contact_mail, theme, isDark),
            _radioOption(
              'Everyone',
              'contactPreference',
              'everyone',
            ),
            _radioOption(
              'Verified users only',
              'contactPreference',
              'verified_only',
            ),
            _radioOption(
              'Women only',
              'contactPreference',
              'women_only',
            ),
            _radioOption(
              'Nobody',
              'contactPreference',
              'nobody',
            ),
            const SizedBox(height: 24),
            _sectionHeader('Who can see my phone number?', Icons.phone, theme, isDark),
            _radioOption(
              'Nobody',
              'phoneVisibility',
              'nobody',
            ),
            _radioOption(
              'People I approve',
              'phoneVisibility',
              'approved',
            ),
            _radioOption(
              'My contacts',
              'phoneVisibility',
              'contacts',
            ),
            const SizedBox(height: 24),
            _sectionHeader('Who can see my location?', Icons.location_on, theme, isDark),
            _radioOption(
              'City only',
              'locationPrecision',
              'city',
            ),
            _radioOption(
              'Area',
              'locationPrecision',
              'area',
            ),
            _radioOption(
              'Approximate location',
              'locationPrecision',
              'approximate',
            ),
            const SizedBox(height: 24),
            _sectionHeader('Other Privacy Options', Icons.shield, theme, isDark),
            _toggleOption(
              'Allow in-app calls',
              'allowCalls',
              'When enabled, users can call you through the app without seeing your number.',
            ),
            _toggleOption(
              'Show my gender on profile',
              'showGender',
              'When disabled, your gender stays private.',
            ),
            _toggleOption(
              'Show my profile photo',
              'showProfilePhoto',
              'When disabled, your profile photo is hidden.',
            ),
            _toggleOption(
              'Sell anonymously',
              'anonymousProfile',
              'Your listings show "Verified Seller" instead of your name.',
            ),
            _toggleOption(
              'Quiet mode',
              'quietMode',
              'You won\'t receive messages from new people for a set period.',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 8),
          Text(title,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            )),
        ],
      ),
    );
  }

  Widget _radioOption(String label, String field, String value) {
    final current = _getField(field);
    return RadioListTile<String>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: current,
      activeColor: AppColors.gold,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _setField(field, v));
      },
    );
  }

  Widget _toggleOption(String title, String field, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: _getBoolField(field),
        activeColor: AppColors.gold,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        onChanged: (v) => setState(() => _setBoolField(field, v)),
      ),
    );
  }

  String _getField(String field) {
    switch (field) {
      case 'contactPreference': return _settings.contactPreference;
      case 'phoneVisibility': return _settings.phoneVisibility;
      case 'locationPrecision': return _settings.locationPrecision;
      default: return '';
    }
  }

  void _setField(String field, String value) {
    switch (field) {
      case 'contactPreference':
        _settings = _settings.copyWith(contactPreference: value);
        break;
      case 'phoneVisibility':
        _settings = _settings.copyWith(phoneVisibility: value);
        break;
      case 'locationPrecision':
        _settings = _settings.copyWith(locationPrecision: value);
        break;
    }
  }

  bool _getBoolField(String field) {
    switch (field) {
      case 'allowCalls': return _settings.allowCalls;
      case 'showGender': return _settings.showGender;
      case 'showProfilePhoto': return _settings.showProfilePhoto;
      case 'anonymousProfile': return _settings.anonymousProfile;
      case 'quietMode': return _settings.quietMode;
      default: return false;
    }
  }

  void _setBoolField(String field, bool value) {
    switch (field) {
      case 'allowCalls':
        _settings = _settings.copyWith(allowCalls: value);
        break;
      case 'showGender':
        _settings = _settings.copyWith(showGender: value);
        break;
      case 'showProfilePhoto':
        _settings = _settings.copyWith(showProfilePhoto: value);
        break;
      case 'anonymousProfile':
        _settings = _settings.copyWith(anonymousProfile: value);
        break;
      case 'quietMode':
        _settings = _settings.copyWith(quietMode: value);
        break;
    }
  }
}
