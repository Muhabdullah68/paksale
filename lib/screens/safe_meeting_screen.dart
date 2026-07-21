import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/language_provider.dart';

class SafeMeetingScreen extends StatelessWidget {
  const SafeMeetingScreen({super.key});

  static const List<Map<String, dynamic>> locations = [
    {'name': 'Centaurus Mall', 'city': 'Islamabad', 'type': 'Shopping Mall'},
    {'name': 'Giga Mall', 'city': 'Islamabad', 'type': 'Shopping Mall'},
    {'name': 'Emporium Mall', 'city': 'Lahore', 'type': 'Shopping Mall'},
    {'name': 'Packages Mall', 'city': 'Lahore', 'type': 'Shopping Mall'},
    {'name': 'Dolmen Mall Clifton', 'city': 'Karachi', 'type': 'Shopping Mall'},
    {'name': 'Lucky One Mall', 'city': 'Karachi', 'type': 'Shopping Mall'},
    {'name': 'MM Alam Road', 'city': 'Lahore', 'type': 'Commercial Area'},
    {'name': 'Gulberg Main Boulevard', 'city': 'Lahore', 'type': 'Commercial Area'},
    {'name': 'Clifton Block 5', 'city': 'Karachi', 'type': 'Commercial Area'},
    {'name': 'F-6 Markaz', 'city': 'Islamabad', 'type': 'Commercial Area'},
    {'name': 'Butt Karahi Gulgasht', 'city': 'Multan', 'type': 'Restaurant/Café'},
    {'name': 'Café Aylanto', 'city': 'Lahore', 'type': 'Restaurant/Café'},
    {'name': 'Espresso F-7', 'city': 'Islamabad', 'type': 'Restaurant/Café'},
    {'name': 'Coffee Planet', 'city': 'Karachi', 'type': 'Restaurant/Café'},
  ];

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
        title: const Text('Safe Meeting Places', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.gold.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.gold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Always meet in a busy public place. Let someone know where you\'re going. Consider bringing a friend.',
                    style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: locations.length,
              itemBuilder: (_, i) {
                final loc = locations[i];
                IconData icon;
                switch (loc['type']) {
                  case 'Shopping Mall': icon = Icons.store_mall_directory; break;
                  case 'Commercial Area': icon = Icons.business; break;
                  default: icon = Icons.local_cafe;
                }
                return Card(
                  color: theme.cardTheme.color,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.gold, size: 22),
                    ),
                    title: Text(loc['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text('${loc['city']} • ${loc['type']}', style: const TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.green, size: 14),
                          SizedBox(width: 4),
                          Text('Safe', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
