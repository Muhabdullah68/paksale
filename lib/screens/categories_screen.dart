import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/language_provider.dart';
import '../widgets/common_widgets.dart';
import '../providers/cms_provider.dart';
import '../web/web_shell.dart';
import 'listing_screen.dart';
import 'notifications_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final bool webEmbedded;
  const CategoriesScreen({super.key, this.webEmbedded = false});

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
    
    final cmsProvider = context.watch<CMSProvider>();
    final categories = cmsProvider.categories.isNotEmpty
        ? cmsProvider.categories.map((c) => {
            'id': c['id']?.toString() ?? '',
            'name': c['name']?.toString() ?? '',
            'icon': c['icon']?.toString() ?? '',
          }).toList()
        : SampleData.homeCategories;

    if (_selectedIndex >= categories.length) {
      _selectedIndex = 0;
    }

    final String selectedCatName = categories.isNotEmpty ? (categories[_selectedIndex]['name'] as String) : '';

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(t['categories_title'] ?? 'Categories',
              style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: widget.webEmbedded
              ? null
              : MediaQuery.of(context).size.height * 0.65,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: ListView.builder(
                  shrinkWrap: widget.webEmbedded,
                  physics: widget.webEmbedded
                      ? const NeverScrollableScrollPhysics()
                      : null,
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
                  child: _buildSubCategoryList(selectedCatName, isDark, theme),
                ),
              ],
            ),
          ),
          const SocialMediaSection(),
        ],
    );

    final scrollableBody = widget.webEmbedded
        ? body
        : SingleChildScrollView(child: body);

    if (kIsWeb) {
      return widget.webEmbedded
          ? scrollableBody
          : WebPage(
              breadcrumbs: const [WebCrumb('Categories')],
              content: scrollableBody,
            );
    }

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
      body: body,
    );
  }

  Widget _buildSubCategoryList(String categoryName, bool isDark, ThemeData theme) {
    // Get the category with subcategories from cmsProvider or sample data
    final cmsProvider = context.watch<CMSProvider>();
    final categories = cmsProvider.categories.isNotEmpty
        ? cmsProvider.categories
        : SampleData.homeCategories;
        
    // Find the selected category
    final selectedCategory = categories.firstWhere(
      (cat) => cat['name'] == categoryName,
      orElse: () => SampleData.homeCategories[0],
    );
    
    // Get subcategories (fallback to empty list if not present)
    final subCategoriesRaw = selectedCategory['subCategories'];
    final List<Map<String, dynamic>> subCats = subCategoriesRaw is List
            ? subCategoriesRaw.cast<Map<String, dynamic>>().toList()
        : [];
        
    if (subCats.isEmpty) {
      // Fallback to simple list if no subcategories
      return Center(child: Text('No subcategories found', 
        style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.lightTextMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      shrinkWrap: widget.webEmbedded,
      physics: widget.webEmbedded
          ? const NeverScrollableScrollPhysics()
          : null,
      itemCount: subCats.length,
      itemBuilder: (_, i) {
        final subCat = subCats[i];
        final name = subCat['name'] as String;
        final icon = subCat['icon'] as String? ?? '';
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ListingScreen(
                    categoryTitle: categoryName,
                    subCategoryTitle: name,
                  )),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: isDark ? AppColors.divider : AppColors.dividerLightMode, width: 0.3))),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
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
