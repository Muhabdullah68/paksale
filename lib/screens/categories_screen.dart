import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import 'sub_category_screen.dart';
import 'listing_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _leftCategories = [
    {'name': 'Cars For Sale', 'icon': '🚗'},
    {'name': 'Special Numbers', 'icon': '📟'},
    {'name': 'Villas', 'icon': '🏡'},
    {'name': 'Apartments', 'icon': '🏢'},
    {'name': 'Bikes', 'icon': '🏍️'},
    {'name': 'Jet Ski', 'icon': '🚤'},
    {'name': 'Caravan', 'icon': '🚐'},
    {'name': 'Trucks', 'icon': '🚛'},
    {'name': 'Mobile & Tablets', 'icon': '📱'},
    {'name': 'Computers', 'icon': '💻'},
    {'name': 'Video Games', 'icon': '🎮'},
    {'name': 'Jewellery', 'icon': '💎'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: CustomSearchBar(
              readOnly: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ListingScreen())),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Categories',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: ListView.builder(
                    itemCount: _leftCategories.length,
                    itemBuilder: (_, i) {
                      final cat = _leftCategories[i];
                      final isSelected = _selectedIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.gold : AppColors.divider.withOpacity(0.5),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                ),
                                child: Center(
                                  child: Text(cat['icon'] as String, style: const TextStyle(fontSize: 36)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  cat['name'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? AppColors.gold : AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: SampleData.allCategories.length,
                    itemBuilder: (_, i) {
                      final cat = SampleData.allCategories[i];
                      return InkWell(
                        onTap: () {
                          if (cat['hasArrow'] == true) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SubCategoryScreen(categoryName: cat['name'] as String)),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ListingScreen(categoryTitle: cat['name'] as String)),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: AppColors.divider, width: 0.3))),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(cat['name'] as String,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary, fontSize: 14)),
                              ),
                              if (cat['hasArrow'] == true)
                                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}