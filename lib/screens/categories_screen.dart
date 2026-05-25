import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/language_provider.dart';
import '../widgets/common_widgets.dart';
import 'listing_screen.dart';
import 'notifications_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    const categories = SampleData.homeCategories;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ListingScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: CustomSearchBar(
              readOnly: true,
              onPrimaryBackground: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ListingScreen())),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(t['categories_title'] ?? 'Categories',
                style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final isSelected = _selectedIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.gold : (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 70,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.transparent : (isDark ? AppColors.surface : AppColors.backgroundLightMode),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                ),
                                child: Center(
                                    child: Text(cat['icon']!,
                                        style: const TextStyle(fontSize: 30))),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(cat['name']!,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _buildSubCategoryList(categories[_selectedIndex]['name'] as String, isDark, theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryList(String categoryName, bool isDark, ThemeData theme) {
    // In a real app, this would fetch from a repository based on categoryName
    // For now, we'll show a "See All" and some mock subcategories
    final List<String> subCats = [
      'All in $categoryName',
      'Latest $categoryName',
      'Featured $categoryName',
      'Premium $categoryName',
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: subCats.length,
      itemBuilder: (_, i) {
        final name = subCats[i];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ListingScreen(categoryTitle: categoryName)),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: isDark ? AppColors.divider : AppColors.dividerLightMode, width: 0.3))),
            child: Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: TextStyle(
                          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLightMode, 
                          fontSize: 14,
                          fontWeight: i == 0 ? FontWeight.w600 : FontWeight.normal)),
                ),
                Icon(Icons.chevron_right, color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
