import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/language_provider.dart';
import '../providers/cms_provider.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        child: Text(
          cmsProvider.helpContent.isEmpty
              ? 'Help content will be available soon.'
              : cmsProvider.helpContent,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
