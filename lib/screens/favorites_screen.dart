import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import 'listing_screen.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _filter = 'All';

  List<ProductModel> get _filtered {
    final favs = AppState().favorites;
    if (_filter == 'All') return favs;
    return favs.where((p) => p.category == _filter).toList();
  }

  List<String> get _categories {
    final cats = AppState().favorites.map((p) => p.category).toSet().toList();
    return ['All', ...cats];
  }

  @override
  void initState() {
    super.initState();
    AppState().addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppState().removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final favs = AppState().favorites;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const AppLogo(),
        actions: [
          if (favs.isNotEmpty)
            TextButton(
              onPressed: _confirmClearAll,
              child: const Text('Clear All',
                  style: TextStyle(color: AppColors.gold, fontSize: 13)),
            ),
        ],
      ),
      body: favs.isEmpty ? _buildEmptyState() : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border,
                size: 80, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 20),
            const Text('No Favorites Yet',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            const Text(
              'Tap the ❤️ on any listing to save it here for quick access',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ListingScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              icon: const Icon(Icons.search, color: Colors.white, size: 18),
              label: const Text('Browse Listings',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    return Column(
      children: [
        if (_categories.length > 1)
          Container(
            height: 44,
            color: AppColors.primaryDark,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _filter == cat;
                return GestureDetector(
                  onTap: () => setState(() => _filter = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.gold : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: selected
                              ? AppColors.gold
                              : AppColors.divider),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text('${items.length} saved item${items.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13)),
              const Spacer(),
              const Text('Swipe left to remove',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
              child: Text('No items in "$_filter"',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14)))
              : ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final p = items[i];
              return Dismissible(
                key: Key('fav-${p.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          color: Colors.white, size: 24),
                      SizedBox(height: 4),
                      Text('Remove',
                          style: TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
                onDismissed: (_) {
                  AppState().toggleFavorite(p);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text('Removed "${_shortTitle(p.title)}"'),
                      backgroundColor: AppColors.primaryDark,
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: AppColors.gold,
                        onPressed: () {
                          AppState().toggleFavorite(p);
                        },
                      ),
                    ),
                  );
                },
                child: ProductCard(
                  product: p,
                  showCompareButton: false,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _shortTitle(String t) =>
      t.length > 30 ? '${t.substring(0, 30)}…' : t;

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Clear Favorites',
            style: TextStyle(color: Colors.white)),
        content: const Text('Remove all saved listings?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final p in AppState().favorites.toList()) {
                AppState().toggleFavorite(p);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}