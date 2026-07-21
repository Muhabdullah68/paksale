import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import '../services/language_provider.dart';
import '../services/currency_provider.dart';

// ─── Logo Icon ────────────────────────────────────────────────────────────────
class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const AppLogoIcon({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

// ─── App Logo ──────────────────────────────────────────────────────────────────
class AppLogo extends StatelessWidget {
  final double fontSize;
  const AppLogo({super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final appName = t['appName'] ?? 'Pak Sale';
    
    // Split name for two-tone color if it contains 'Sale'
    String part1 = appName;
    String part2 = '';
    
    if (appName.contains('Sale')) {
      part1 = appName.substring(0, appName.indexOf('Sale'));
      part2 = 'Sale';
    } else if (appName.contains(' ')) {
      final parts = appName.split(' ');
      part1 = parts[0];
      part2 = ' ${parts.sublist(1).join(' ')}';
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: part1,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
          TextSpan(
            text: part2,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Search Bar ────────────────────────────────────────────────────────
class CustomSearchBar extends StatelessWidget {
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String hint;
  final bool onPrimaryBackground;

  const CustomSearchBar({
    super.key,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.controller,
    this.hint = 'Search in Pak Sale...',
    this.onPrimaryBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // If on primary background (like our dark red AppBar), always use white-ish colors
    final textColor = (isDark || onPrimaryBackground) ? Colors.white : Colors.black87;
    final hintColor = (isDark || onPrimaryBackground) ? Colors.white60 : Colors.black45;

    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 42, maxHeight: 52),
        decoration: BoxDecoration(
          color: (isDark || onPrimaryBackground)
              ? Colors.white.withValues(alpha: 0.15) 
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: (isDark || onPrimaryBackground)
                  ? AppColors.gold.withValues(alpha: 0.3) 
                  : AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: readOnly
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.search, color: hintColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  style: TextStyle(color: hintColor, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )
            : TextField(
          controller: controller,
          onChanged: onChanged,
          autofocus: true,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintColor, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: hintColor, size: 18),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageProvider>().t;
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.1), blurRadius: 16)],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 22,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: t['nav_home'] ?? 'Home'),
          BottomNavigationBarItem(icon: const Icon(Icons.grid_view_outlined), activeIcon: const Icon(Icons.grid_view), label: t['nav_categories'] ?? 'Categories'),
          BottomNavigationBarItem(icon: const Icon(Icons.add_circle_outline, size: 28), activeIcon: const Icon(Icons.add_circle, size: 28), label: t['nav_post_ad'] ?? 'Post Ad'),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite_outline), activeIcon: const Icon(Icons.favorite), label: t['nav_saved'] ?? 'Saved'),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: t['nav_account'] ?? 'Account'),
        ],
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final bool isGridView;
  final VoidCallback? onCompare;
  final bool showCompareButton;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isGridView = false,
    this.onCompare,
    this.showCompareButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return isGridView ? _buildGrid(context) : _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final currencyProvider = context.watch<CurrencyProvider>();
    final favoritesProvider = context.watch<FavoritesProvider?>();
    final compareProvider = context.watch<CompareProvider>();
    final isFav = favoritesProvider?.isFavorite(product.id) ?? false;
    final inCompare = compareProvider.isInCompare(product.id);
    
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.2)),
            boxShadow: isDark ? null : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    child: _buildImage(context, 100, 100),
                  ),
                  if (p.isSold)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text(t['sold'] ?? 'SOLD',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                  if (p.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                        child: const Text('⭐', style: TextStyle(fontSize: 9)),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color, 
                              fontSize: 13, 
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              p.price == 0 ? (t['contact'] ?? 'Contact') : currencyProvider.formatPrice(p.price),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: theme.textTheme.titleLarge?.color, 
                                  fontSize: 17, 
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _ConditionBadge(condition: p.condition),
                          const Spacer(),
                          Icon(Icons.location_on, size: 11, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) ?? AppColors.textMuted),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                                '${p.location}${p.city.isNotEmpty ? ', ${p.city}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: theme.textTheme.bodySmall?.color
                                            ?.withValues(alpha: 0.5) ??
                                        AppColors.textMuted,
                                    fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 11, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) ?? AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text('${p.views}', style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) ?? AppColors.textMuted, fontSize: 10)),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(p.postedTime, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) ?? AppColors.textMuted, fontSize: 10)),
                          ),
                          const Spacer(),
                          if (showCompareButton)
                            GestureDetector(
                              onTap: () {
                                if (compareProvider.toggleCompare(p)) {
                                  // Added
                                } else if (!inCompare) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(t['compare_limit'] ?? 'Compare limit reached (max 3)'),
                                    backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                                  ));
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: inCompare ? AppColors.gold.withValues(alpha: 0.2) : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                                ),
                                child: Text(inCompare ? (t['compare'] ?? '✓ Compare') : (t['compare'] ?? '+ Compare'),
                                    style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 10),
                child: GestureDetector(
                  onTap: () {
                    if (favoritesProvider != null) {
                      favoritesProvider.toggleFavorite(product);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(t['sign_in_favorites'] ?? 'Please sign in to save favorites'),
                        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                      ));
                    }
                  },
                  child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.redAccent : AppColors.textMuted, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final currencyProvider = context.watch<CurrencyProvider>();
    final favoritesProvider = context.watch<FavoritesProvider?>();
    final compareProvider = context.watch<CompareProvider>();
    final isFav = favoritesProvider?.isFavorite(product.id) ?? false;
    final inCompare = compareProvider.isInCompare(product.id);
    
    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.2)),
            boxShadow: isDark ? null : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildImage(context, double.infinity, double.infinity, isGrid: true),
                    ),
                    if (p.isSold)
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(t['sold'] ?? 'SOLD',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                      ),
                    if (p.isFeatured)
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                          child: Text(t['featured_label'] ?? 'Featured', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (p.isBoosted)
                      Positioned(
                        top: p.isFeatured ? 28 : 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(4)),
                          child: const Text('🚀 Boosted', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () {
                          if (favoritesProvider != null) {
                            favoritesProvider.toggleFavorite(product);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(t['sign_in_favorites'] ?? 'Please sign in to save favorites'),
                              backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                            ));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                          child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                              size: 16, color: isFav ? Colors.redAccent : Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      p.price == 0 ? (t['contact'] ?? 'Contact') : currencyProvider.formatPrice(p.price),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 9, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) ?? AppColors.textMuted),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text('${p.location}${p.city.isNotEmpty ? ', ${p.city}' : ''}', 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) ?? AppColors.textMuted, fontSize: 9)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ConditionBadge(condition: p.condition, small: true),
                        const Spacer(),
                        Flexible( 
                          child: Text(p.postedTime, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5) ?? AppColors.textMuted, fontSize: 9)),
                        ),
                      ],
                    ),
                    if (showCompareButton) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          if (compareProvider.toggleCompare(p)) {
                            // Added
                          } else if (!compareProvider.isInCompare(p.id)) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(t['compare_limit'] ?? 'Compare limit reached (max 3)'),
                              backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
                            ));
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: inCompare ? AppColors.gold.withValues(alpha: 0.15) : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                          ),
                          child: Text(inCompare ? (t['compare_added'] ?? '✓ Added') : (t['compare'] ?? '+ Compare'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, double width, double height, {bool isGrid = false}) {
    if (product.imageUrls.isNotEmpty) {
      return Hero(
        tag: 'product_image_${product.id}',
        child: Image.network(
          product.imageUrls[0],
          width: width,
          height: height,
          cacheWidth: 250, // Optimize memory by caching a smaller version
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(context, width, height),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final isDarkLoading = Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: width,
              height: height,
              color: isDarkLoading ? AppColors.surface : AppColors.cardLightMode,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                ),
              ),
            );
          },
        ),
      );
    }
    return _buildImagePlaceholder(context, width, height);
  }

  Widget _buildImagePlaceholder(BuildContext context, double width, double height) {
    IconData icon;
    Color color;
    switch (product.category) {
      case 'Vehicles': icon = Icons.directions_car; color = const Color(0xFF1565C0); break;
      case 'Properties': icon = Icons.home; color = const Color(0xFF2E7D32); break;
      case 'Electronics': icon = Icons.devices; color = const Color(0xFF6A1B9A); break;
      case 'Furniture & Décor': icon = Icons.chair; color = const Color(0xFF5D4037); break;
      case 'WaterCrafts': icon = Icons.directions_boat; color = const Color(0xFF0288D1); break;
      case 'Jewellery': icon = Icons.diamond; color = const Color(0xFFC62828); break;
      case 'Lifestyle': icon = Icons.shopping_bag; color = const Color(0xFFD81B60); break;
      case 'Market': icon = Icons.shopping_cart; color = const Color(0xFF388E3C); break;
      case 'Outdoor & Leisure': icon = Icons.landscape; color = const Color(0xFFF57C00); break;
      case 'Special Numbers': icon = Icons.looks_one; color = AppColors.gold; break;
      case 'Heavy Equipments': icon = Icons.construction; color = const Color(0xFF455A64); break;
      case 'Jobs Center': icon = Icons.work; color = const Color(0xFF00897B); break;
      case 'Super Ads': icon = Icons.star; color = AppColors.orange; break;
      default: icon = Icons.image; color = AppColors.textMuted;
    }
    return Container(
      width: width,
      height: height,
      color: color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.08),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.38,
          heightFactor: 0.38,
          child: FittedBox(child: Icon(icon, color: color.withValues(alpha: 0.4))),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Row(
        children: [
          Container(
            width: 4, height: 16,
            decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: theme.textTheme.titleLarge?.color, 
                    fontSize: 16, 
                    fontWeight: FontWeight.w700)),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionText!,
                  style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

// ─── Category Circle ──────────────────────────────────────────────────────────
class CategoryCircle extends StatelessWidget {
  final String name;
  final String icon;
  final double size;
  final VoidCallback? onTap;

  const CategoryCircle({super.key, required this.name, required this.icon, this.size = 65, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardTheme.color,
                border: Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.2)),
                boxShadow: isDark ? null : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: Center(child: Text(icon, style: TextStyle(fontSize: size * 0.42))),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: size + 10,
              child: Text(name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color, 
                      fontSize: 11, 
                      height: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ad Banner Placeholder ────────────────────────────────────────────────────
class AdBannerPlaceholder extends StatelessWidget {
  final String text;

  const AdBannerPlaceholder({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20, top: -20,
              child: Container(width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: AppColors.gold, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(16)),
                    child: const Text('AD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Contact Action Buttons ───────────────────────────────────────────────────
class ContactActionButtons extends StatelessWidget {
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final PrivacySettings? privacy;

  const ContactActionButtons({super.key, this.onWhatsApp, this.onCall, this.onChat, this.privacy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;

    final showCall = privacy == null || privacy!.allowCalls;
    final showWhatsApp = privacy == null || privacy!.phoneVisibility != 'nobody';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : AppColors.cardLightMode,
        border: Border(top: BorderSide(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Row(
        children: [
          if (showCall)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                label: Text(t['call_now'] ?? 'Call Now', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (showCall && onChat != null) const SizedBox(width: 10),
          if (showWhatsApp && onWhatsApp != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                label: Text(t['whatsapp'] ?? 'WhatsApp', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (showWhatsApp && onWhatsApp != null) const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.message_outlined, size: 18, color: Colors.white),
              label: Text(t['message'] ?? 'Message', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Widget ───────────────────────────────────────────────────────────
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold), strokeWidth: 2.5),
          const SizedBox(height: 12),
          Text(t['loading'] ?? 'Loading...', style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.textMuted.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(color: theme.textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13)),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// ─── Condition Badge ──────────────────────────────────────────────────────────
class _ConditionBadge extends StatelessWidget {
  final String condition;
  final bool small;

  const _ConditionBadge({required this.condition, this.small = false});

  Color get _color {
    switch (condition) {
      case 'Rent': return AppColors.primary;
      case 'Sale': return AppColors.orange;
      case 'Exchange': return const Color(0xFF7B1FA2);
      case 'Full Time': return AppColors.green;
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 5 : 7, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _color.withValues(alpha: 0.5))),
      child: Text(condition, style: TextStyle(color: _color, fontSize: small ? 9 : 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Social Media Section ─────────────────────────────────────────────────────
class SocialMediaSection extends StatefulWidget {
  const SocialMediaSection({super.key});

  @override
  State<SocialMediaSection> createState() => _SocialMediaSectionState();
}

class _SocialMediaSectionState extends State<SocialMediaSection> {
  late List<SocialMediaItem> _shuffledItems;

  @override
  void initState() {
    super.initState();
    _shuffledItems = List.from(_socialMediaItems)..shuffle();
  }

  static const List<SocialMediaItem> _socialMediaItems = [
    SocialMediaItem(
      name: 'TikTok',
      icon: FontAwesomeIcons.tiktok,
      url: 'https://www.tiktok.com/',
      color: Colors.black,
    ),
    SocialMediaItem(
      name: 'Instagram',
      icon: FontAwesomeIcons.instagram,
      url: 'https://www.instagram.com/',
      color: Color(0xFFE1306C),
    ),
    SocialMediaItem(
      name: 'Snapchat',
      icon: FontAwesomeIcons.snapchat,
      url: 'https://www.snapchat.com/',
      color: Color(0xFFFFFC00),
    ),
    SocialMediaItem(
      name: 'YouTube',
      icon: FontAwesomeIcons.youtube,
      url: 'https://www.youtube.com/',
      color: Color(0xFFFF0000),
    ),
    SocialMediaItem(
      name: 'X',
      icon: FontAwesomeIcons.xTwitter,
      url: 'https://twitter.com/',
      color: Colors.black,
    ),
  ];

  Future<void> _launchSocialMedia(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you following us?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _shuffledItems.map((item) => GestureDetector(
              onTap: () => _launchSocialMedia(item.url),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark 
                      ? AppColors.gold.withValues(alpha: 0.4) 
                      : AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: FaIcon(
                  item.icon,
                  size: 32,
                  color: isDark ? AppColors.gold : AppColors.primary,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class SocialMediaItem {
  final String name;
  final IconData icon;
  final String url;
  final Color color;

  const SocialMediaItem({
    required this.name,
    required this.icon,
    required this.url,
    required this.color,
  });
}
