import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../models/product_model.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import '../services/language_provider.dart';
import '../services/currency_provider.dart';
import '../services/share_service.dart';
import '../widgets/common_widgets.dart' show toggleCompareWithFeedback;

class WebProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final bool showShareButton;

  const WebProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onShare,
    this.showShareButton = true,
  });

  @override
  State<WebProductCard> createState() => _WebProductCardState();
}

class _WebProductCardState extends State<WebProductCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.product;
    final currencyProvider = context.watch<CurrencyProvider>();
    final favoritesProvider = context.watch<FavoritesProvider?>();
    final compareProvider = context.watch<CompareProvider?>();
    final t = context.watch<LanguageProvider>().t;
    final isFav = favoritesProvider?.isFavorite(p.id) ?? false;
    final isInCompare = compareProvider?.isInCompare(p.id) ?? false;

    // Hover/elevation lives in [_HoverShell] so mouse enter/exit only
    // rebuilds the shell — not the image, badges or text below.
    return _HoverShell(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    if (p.isSold)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            t['sold'] ?? 'SOLD',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 2),
                          ),
                        ),
                      ),
                    if (p.isFeatured)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t['featured_label'] ?? 'Featured',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    if (p.isBoosted)
                      Positioned(
                        top: p.isFeatured ? 30 : 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '🚀 Boosted',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                        onTap: () {
                          if (favoritesProvider != null) {
                            favoritesProvider.toggleFavorite(p);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t['sign_in_favorites'] ??
                                    'Please sign in to save favorites'),
                                backgroundColor: AppColors.orange,
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav ? Colors.redAccent : Colors.white,
                          ),
                        ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.price == 0
                          ? (t['contact'] ?? 'Contact')
                          : currencyProvider.formatPrice(p.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(p.postedTime,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            p.city.isNotEmpty
                                ? '${p.location}, ${p.city}'
                                : p.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${p.views}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        const Spacer(),
                        if (widget.showShareButton) ...[
                          _WebActionChip(
                            icon: Icons.compare_arrows,
                            label: t['compare'] ?? 'Compare',
                            isActive: isInCompare,
                            onTap: () => toggleCompareWithFeedback(
                                context, p, compareProvider),
                          ),
                          const SizedBox(width: 6),
                          _WebActionChip(
                            icon: Icons.share_outlined,
                            label: t['share'] ?? 'Share',
                            onTap: () {
                              if (widget.onShare != null) {
                                widget.onShare!();
                              } else {
                                ShareService.shareProduct(
                                    context, widget.product);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildImage() {
    if (widget.product.imageUrls.isEmpty) {
      return _placeholder();
    }
    return CachedNetworkImage(
      imageUrl: widget.product.imageUrls.first,
      fit: BoxFit.cover,
      memCacheWidth: 500,
      errorWidget: (context, url, error) => _placeholder(),
      placeholder: (context, url) => Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surface
            : AppColors.cardLightMode,
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.gold),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    final icon = _categoryIcon();
    return Container(
      color: icon.$2.withValues(alpha: 0.12),
      child: Center(
        child: Icon(icon.$1, color: icon.$2.withValues(alpha: 0.4), size: 40),
      ),
    );
  }

  (IconData, Color) _categoryIcon() {
    switch (widget.product.category) {
      case 'Vehicles':
        return (Icons.directions_car, const Color(0xFF1565C0));
      case 'Properties':
        return (Icons.home, const Color(0xFF2E7D32));
      case 'Electronics':
        return (Icons.devices, const Color(0xFF6A1B9A));
      case 'Furniture & Décor':
        return (Icons.chair, const Color(0xFF5D4037));
      case 'WaterCrafts':
        return (Icons.directions_boat, const Color(0xFF0288D1));
      case 'Jewellery':
        return (Icons.diamond, const Color(0xFFC62828));
      case 'Lifestyle':
        return (Icons.shopping_bag, const Color(0xFFD81B60));
      case 'Market':
        return (Icons.shopping_cart, const Color(0xFF388E3C));
      case 'Outdoor & Leisure':
        return (Icons.landscape, const Color(0xFFF57C00));
      case 'Special Numbers':
        return (Icons.looks_one, AppColors.gold);
      case 'Heavy Equipments':
        return (Icons.construction, const Color(0xFF455A64));
      case 'Jobs Center':
        return (Icons.work, const Color(0xFF00897B));
      case 'Super Ads':
        return (Icons.star, AppColors.orange);
      default:
        return (Icons.image, AppColors.textMuted);
    }
  }
}

class _WebActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _WebActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color:
                    AppColors.gold.withValues(alpha: isActive ? 0.8 : 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: AppColors.gold),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Owns the hover state + card chrome (scale, border, shadow) so mouse
/// enter/exit never rebuilds the card contents passed as [child].
class _HoverShell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _HoverShell({required this.child, this.onTap});

  @override
  State<_HoverShell> createState() => _HoverShellState();
}

class _HoverShellState extends State<_HoverShell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? AppColors.gold.withValues(alpha: 0.6)
                    : (isDark
                            ? AppColors.divider
                            : AppColors.dividerLightMode)
                        .withValues(alpha: 0.25),
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
