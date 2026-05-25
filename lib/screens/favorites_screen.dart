import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../services/language_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final favoritesProvider = context.watch<FavoritesProvider?>();
    final t = context.watch<LanguageProvider>().t;

    if (!authProvider.isAuthenticated) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const AppLogo(),
        ),
        body: EmptyState(
          icon: Icons.lock_outline,
          title: t['sign_in_required'] ?? 'Sign In Required',
          subtitle: t['sign_in_favorites'] ?? 'Please sign in to see your favorite listings.',
        ),
      );
    }

    final favs = favoritesProvider?.favoriteProducts ?? [];
    final filteredFavs = _filter == 'All' 
        ? favs 
        : favs.where((p) => p.category == _filter).toList();

    final cats = ['All', ...favs.map((p) => p.category).toSet()];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const AppLogo(),
        actions: [
          if (favs.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(favoritesProvider),
              child: Text(t['clear_favorites'] ?? 'Clear All',
                  style: const TextStyle(color: AppColors.gold, fontSize: 13)),
            ),
        ],
      ),
      body: favoritesProvider?.isLoading == true 
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : favs.isEmpty 
              ? _buildEmptyState(context) 
              : _buildList(filteredFavs, cats, context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border,
                size: 80, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(t['no_favorites'] ?? 'No Favorites Yet',
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(
              t['no_favorites_hint'] ?? 'Tap the ❤️ on any listing to save it here for quick access',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13),
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
              label: Text(t['browse_listings'] ?? 'Browse Listings',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ProductModel> filteredFavs, List<String> categories, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        if (categories.length > 1)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final c = categories[i];
                final isSel = _filter == c;
                return GestureDetector(
                  onTap: () => setState(() => _filter = c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.gold : theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSel ? AppColors.gold : (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5)),
                    ),
                    child: Center(
                      child: Text(c,
                          style: TextStyle(
                              color: isSel ? Colors.white : theme.textTheme.bodyLarge?.color,
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredFavs.length,
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            itemBuilder: (_, i) => ProductCard(
              product: filteredFavs[i],
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailScreen(product: filteredFavs[i]))),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmClearAll(FavoritesProvider? provider) {
    if (provider == null) return;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.read<LanguageProvider>().t;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        title: Text(t['clear_favorites_confirm'] ?? 'Clear All Favorites?',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text(
            t['clear_favorites_confirm_msg'] ?? 'Are you sure you want to remove all items from your favorites?',
            style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t['cancel'] ?? 'Cancel',
                  style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode))),
          TextButton(
            onPressed: () {
              provider.clearFavorites();
              Navigator.pop(context);
            },
            child: Text(t['clear_favorites'] ?? 'Clear All',
                style: const TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

