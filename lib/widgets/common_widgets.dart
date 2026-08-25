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
import '../services/share_service.dart';

/// Toggles [product] in the compare list with user feedback.
void toggleCompareWithFeedback(
    BuildContext context, ProductModel product, CompareProvider? provider) {
  if (provider == null) return;
  final t = context.read<LanguageProvider>().t;
  final result = provider.toggleCompare(product);
  if (!context.mounted) return;
  final (message, color) = switch (result) {
    CompareToggleResult.added => (
        t['compare_added'] ?? '✓ Added to compare',
        AppColors.gold,
      ),
    CompareToggleResult.removed => (
        t['compare_removed'] ?? 'Removed from compare',
        AppColors.textMuted,
      ),
    CompareToggleResult.limitReached => (
        t['compare_limit'] ?? 'Compare limit reached (max 3)',
        AppColors.orange,
      ),
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: color,
  ));
}

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

class AppLogo extends StatelessWidget {
  final double fontSize;
  const AppLogo({super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final appName = t['appName'] ?? 'Pak Sale';

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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.3 : 0.1),
              blurRadius: 16)
        ],
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
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: t['nav_home'] ?? 'Home'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_outlined),
              activeIcon: const Icon(Icons.grid_view),
              label: t['nav_categories'] ?? 'Categories'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              activeIcon: const Icon(Icons.add_circle, size: 28),
              label: t['nav_post_ad'] ?? 'Post Ad'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_outline),
              activeIcon: const Icon(Icons.favorite),
              label: t['nav_saved'] ?? 'Saved'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: t['nav_account'] ?? 'Account'),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final bool isGridView;
  final VoidCallback? onShare;
  final bool showShareButton;
  final bool showCompareButton;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isGridView = false,
    this.onShare,
    this.showShareButton = true,
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
    final compareProvider = context.watch<CompareProvider?>();
    final isFav = favoritesProvider?.isFavorite(product.id) ?? false;
    final isInCompare = compareProvider?.isInCompare(product.id) ?? false;

    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
                    .withValues(alpha: 0.2)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.horizontal(left: Radius.circular(12)),
                    child: _buildImage(context, 100, 100),
                  ),
                  if (p.isSold)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12)),
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text(t['sold'] ?? 'SOLD',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)),
                          ),
                        ),
                      ),
                    ),
                  if (p.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(4)),
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
                      Text(p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(
                        p.price == 0
                            ? (t['contact'] ?? 'Contact')
                            : currencyProvider.formatPrice(p.price),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 17,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 11, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(p.postedTime,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _ConditionBadge(condition: p.condition),
                          const SizedBox(width: 8),
                          Icon(Icons.location_on,
                              size: 11,
                              color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5) ??
                                  AppColors.textMuted),
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
                          Icon(Icons.remove_red_eye_outlined,
                              size: 11,
                              color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.5) ??
                                  AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text('${p.views}',
                              style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.5) ??
                                      AppColors.textMuted,
                                  fontSize: 10)),
                          const Spacer(),
                          if (showCompareButton)
                            _ActionChip(
                              icon: Icons.compare_arrows,
                              label: t['compare'] ?? 'Compare',
                              isActive: isInCompare,
                              onTap: () => toggleCompareWithFeedback(
                                  context, p, compareProvider),
                            ),
                          if (showCompareButton && showShareButton)
                            const SizedBox(width: 6),
                          if (showShareButton)
                            _ActionChip(
                              icon: Icons.share_outlined,
                              label: t['share'] ?? 'Share',
                              onTap: () {
                                if (onShare != null) {
                                  onShare!();
                                } else {
                                  ShareService.shareProduct(context, product);
                                }
                              },
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
                  onTap: () async {
                    if (favoritesProvider == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(t['sign_in_favorites'] ??
                            'Please sign in to save favorites'),
                        backgroundColor:
                            isDark ? AppColors.primaryDark : AppColors.primary,
                      ));
                      return;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await favoritesProvider.toggleFavorite(product);
                    if (!ok) {
                      messenger.showSnackBar(SnackBar(
                        content: Text(t['favorite_failed'] ??
                            "Couldn't update favorite"),
                        backgroundColor: Colors.redAccent,
                      ));
                    }
                  },
                  child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.redAccent : AppColors.textMuted,
                      size: 20),
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
    final compareProvider = context.watch<CompareProvider?>();
    final isFav = favoritesProvider?.isFavorite(product.id) ?? false;
    final isInCompare = compareProvider?.isInCompare(product.id) ?? false;

    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
                    .withValues(alpha: 0.2)),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.45,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildImage(context, double.infinity,
                          double.infinity,
                          isGrid: true),
                    ),
                    if (p.isSold)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(t['sold'] ?? 'SOLD',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                        ),
                      ),
                    if (p.isFeatured)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(t['featured_label'] ?? 'Featured',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (p.isBoosted)
                      Positioned(
                        top: p.isFeatured ? 28 : 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('🚀 Boosted',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () async {
                          if (favoritesProvider == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(t['sign_in_favorites'] ??
                                  'Please sign in to save favorites'),
                              backgroundColor:
                                  isDark ? AppColors.primaryDark : AppColors.primary,
                            ));
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await favoritesProvider.toggleFavorite(product);
                          if (!ok) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(t['favorite_failed'] ??
                                  "Couldn't update favorite"),
                              backgroundColor: Colors.redAccent,
                            ));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                              color: Colors.black26, shape: BoxShape.circle),
                          child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 15,
                              color: isFav ? Colors.redAccent : Colors.white),
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
                    Text(p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      p.price == 0
                          ? (t['contact'] ?? 'Contact')
                          : currencyProvider.formatPrice(p.price),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 9, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Text(p.postedTime,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 9)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 9,
                            color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.5) ??
                                AppColors.textMuted),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                              '${p.location}${p.city.isNotEmpty ? ', ${p.city}' : ''}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.5) ??
                                      AppColors.textMuted,
                                  fontSize: 9)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ConditionBadge(condition: p.condition, small: true),
                        const Spacer(),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 9,
                            color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.5) ??
                                AppColors.textMuted),
                        const SizedBox(width: 2),
                        Text('${p.views}',
                            style: TextStyle(
                                color: theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.5) ??
                                    AppColors.textMuted,
                                fontSize: 9)),
                      ],
                    ),
                    if (showCompareButton || showShareButton) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (showCompareButton)
                            Expanded(
                              child: _ActionChip(
                                icon: Icons.compare_arrows,
                                label: t['compare'] ?? 'Compare',
                                isActive: isInCompare,
                                dense: true,
                                onTap: () => toggleCompareWithFeedback(
                                    context, p, compareProvider),
                              ),
                            ),
                          if (showCompareButton && showShareButton)
                            const SizedBox(width: 4),
                          if (showShareButton)
                            Expanded(
                              child: _ActionChip(
                                icon: Icons.share_outlined,
                                label: t['share'] ?? 'Share',
                                dense: true,
                                onTap: () {
                                  if (onShare != null) {
                                    onShare!();
                                  } else {
                                    ShareService.shareProduct(
                                        context, product);
                                  }
                                },
                              ),
                            ),
                        ],
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

  Widget _buildImage(BuildContext context, double width, double height,
      {bool isGrid = false}) {
    if (product.imageUrls.isNotEmpty) {
      return Hero(
        tag: 'product_image_${product.id}',
        child: Image.network(
          product.imageUrls[0],
          width: width,
          height: height,
          cacheWidth: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(context, width, height),
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.gold),
                ),
              ),
            );
          },
        ),
      );
    }
    return _buildImagePlaceholder(context, width, height);
  }

  Widget _buildImagePlaceholder(
      BuildContext context, double width, double height) {
    IconData icon;
    Color color;
    switch (product.category) {
      case 'Vehicles':
        icon = Icons.directions_car;
        color = const Color(0xFF1565C0);
        break;
      case 'Properties':
        icon = Icons.home;
        color = const Color(0xFF2E7D32);
        break;
      case 'Electronics':
        icon = Icons.devices;
        color = const Color(0xFF6A1B9A);
        break;
      case 'Furniture & Décor':
        icon = Icons.chair;
        color = const Color(0xFF5D4037);
        break;
      case 'WaterCrafts':
        icon = Icons.directions_boat;
        color = const Color(0xFF0288D1);
        break;
      case 'Jewellery':
        icon = Icons.diamond;
        color = const Color(0xFFC62828);
        break;
      case 'Lifestyle':
        icon = Icons.shopping_bag;
        color = const Color(0xFFD81B60);
        break;
      case 'Market':
        icon = Icons.shopping_cart;
        color = const Color(0xFF388E3C);
        break;
      case 'Outdoor & Leisure':
        icon = Icons.landscape;
        color = const Color(0xFFF57C00);
        break;
      case 'Special Numbers':
        icon = Icons.looks_one;
        color = AppColors.gold;
        break;
      case 'Heavy Equipments':
        icon = Icons.construction;
        color = const Color(0xFF455A64);
        break;
      case 'Jobs Center':
        icon = Icons.work;
        color = const Color(0xFF00897B);
        break;
      case 'Super Ads':
        icon = Icons.star;
        color = AppColors.orange;
        break;
      default:
        icon = Icons.image;
        color = AppColors.textMuted;
    }
    return Container(
      width: width,
      height: height,
      color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.08),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.38,
          heightFactor: 0.38,
          child: FittedBox(
              child: Icon(icon, color: color.withValues(alpha: 0.4))),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool dense;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 7, vertical: 3);
    final iconSize = dense ? 9.0 : 10.0;
    final fontSize = dense ? 8.5 : 10.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: padding,
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold.withValues(alpha: 0.15) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: AppColors.gold.withValues(alpha: isActive ? 0.8 : 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: AppColors.gold),
              const SizedBox(width: 3),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.gold,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(2)),
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
                  style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

class CategoryCircle extends StatelessWidget {
  final String name;
  final String icon;
  final double size;
  final VoidCallback? onTap;

  const CategoryCircle(
      {super.key,
      required this.name,
      required this.icon,
      this.size = 65,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final adjustedSize = screenWidth < 360 ? size * 0.85 : size;
    final iconSize = adjustedSize * 0.42;
    final textSize = screenWidth < 360 ? 10.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: adjustedSize,
              height: adjustedSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardTheme.color,
                border: Border.all(
                    color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
                        .withValues(alpha: 0.2)),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
              ),
              child: Center(child: Text(icon, style: TextStyle(fontSize: iconSize))),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: adjustedSize + 10,
              child: Text(name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: textSize,
                      height: 1.2)),
            ),
          ],
        ),
      ),
    );
  }
}

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
              right: -20,
              top: -20,
              child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: AppColors.gold, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Text('AD',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
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

class ContactActionButtons extends StatelessWidget {
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final PrivacySettings? privacy;

  const ContactActionButtons(
      {super.key, this.onWhatsApp, this.onCall, this.onChat, this.privacy});

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
        border: Border(
            top: BorderSide(
                color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
                    .withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          if (showCall)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                label: Text(t['call_now'] ?? 'Call Now',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (showCall && onChat != null) const SizedBox(width: 10),
          if (showWhatsApp && onWhatsApp != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                label: Text(t['whatsapp'] ?? 'WhatsApp',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (showWhatsApp && onWhatsApp != null && onChat != null)
            const SizedBox(width: 10),
          if (onChat != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.message_outlined, size: 18, color: Colors.white),
                label: Text(t['message'] ?? 'Message',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
          const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              strokeWidth: 2.5),
          const SizedBox(height: 12),
          Text(t['loading'] ?? 'Loading...',
              style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.action});

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
            Icon(icon,
                size: 72, color: AppColors.textMuted.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                    fontSize: 13)),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  final String condition;
  final bool small;

  const _ConditionBadge({required this.condition, this.small = false});

  Color get _color {
    switch (condition) {
      case 'Rent':
        return AppColors.primary;
      case 'Sale':
        return AppColors.orange;
      case 'Exchange':
        return const Color(0xFF7B1FA2);
      case 'Full Time':
        return AppColors.green;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _color.withValues(alpha: 0.12);
    final pad = small
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
        : const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
    final radius = small ? 4.0 : 6.0;
    final fontSize = small ? 8.5 : 10.0;
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(condition,
          style: TextStyle(
              color: _color, fontSize: fontSize, fontWeight: FontWeight.w600)),
    );
  }
}

class SocialMediaFooter extends StatelessWidget {
  const SocialMediaFooter({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      (FontAwesomeIcons.tiktok, 'TikTok', 'https://www.tiktok.com/'),
      (FontAwesomeIcons.instagram, 'Instagram', 'https://www.instagram.com/'),
      (FontAwesomeIcons.snapchat, 'Snapchat', 'https://www.snapchat.com/'),
      (FontAwesomeIcons.youtube, 'YouTube', 'https://www.youtube.com/'),
      (FontAwesomeIcons.xTwitter, 'X', 'https://twitter.com/'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (icon, name, url) in items)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Tooltip(
                message: name,
                child: GestureDetector(
                  onTap: () => _launch(url),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.5),
                          width: 1.2),
                    ),
                    child: Center(
                      child: FaIcon(icon, size: 15, color: AppColors.gold),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
