import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/language_provider.dart';
import '../providers/cms_provider.dart';
import 'safe_meeting_screen.dart';
import 'female_support_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final cmsProvider = context.watch<CMSProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t['help'] ?? 'Help',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: theme.cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_city, color: AppColors.green, size: 22),
                    ),
                    title: const Text('Safe Meeting Places', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Find public places for secure transactions', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafeMeetingScreen())),
                  ),
                  Divider(height: 1, color: isDark ? AppColors.divider : AppColors.dividerLightMode, indent: 60),
                  ListTile(
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.female, color: AppColors.gold, size: 22),
                    ),
                    title: const Text('Female Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Contact our female support team', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FemaleSupportScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              cmsProvider.helpContent.isEmpty
                  ? 'Help content will be available soon.'
                  : cmsProvider.helpContent,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
