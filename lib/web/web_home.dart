// web/web_home.dart — the website-style home page (web build only).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/product_provider.dart';
import '../providers/cms_provider.dart';
import 'web_shell.dart';
import 'web_product_card.dart';

/// Responsive column count for product grids on wide screens.
int webGridColumns(double width) {
  if (width < 480) return 1;
  if (width >= 1100) return 4;
  if (width >= 850) return 3;
  return 2;
}

class WebHomeBody extends StatefulWidget {
  final ValueChanged<ProductModel> onProductTap;
  final ValueChanged<String> onCategoryTap;
  final VoidCallback onSeeAllAds;
  const WebHomeBody({
    super.key,
    required this.onProductTap,
    required this.onCategoryTap,
    required this.onSeeAllAds,
  });

  @override
  State<WebHomeBody> createState() => _WebHomeBodyState();
}

class _WebHomeBodyState extends State<WebHomeBody> {
  RangeValues _priceRange = const RangeValues(0, 500000);
  final Set<String> _selectedConditions = <String>{};
  final Set<String> _expandedCategories = <String>{'Vehicles'};

  // Responsive breakpoints
  static const double _showLeftSidebarAt = 1000;
  static const double _showBothSidebarsAt = 1280;
  static const double _leftSidebarWidth = 240;
  static const double _rightSidebarWidth = 300;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.fetchProducts();
      provider.fetchFeaturedProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = context.select((ProductProvider p) => p.products);
    final featured = context.select((ProductProvider p) => p.featuredProducts);
    final isLoading = context.select((ProductProvider p) => p.isLoading);
    final centerContent = _buildCenterContent(
        context, products, featured, isLoading);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final showLeft = w >= _showLeftSidebarAt;
        final showRight = w >= _showBothSidebarsAt;

        if (!showLeft && !showRight) {
          // Narrow desktop / tablet: single column
          return centerContent;
        }

        // Desktop: 2 or 3 column layout (page scroll owns the scrolling)
        final children = <Widget>[];
        if (showLeft) {
          children.add(SizedBox(
            width: _leftSidebarWidth,
            child: _LeftSidebar(
              priceRange: _priceRange,
              onPriceChanged: (v) => setState(() => _priceRange = v),
              selectedConditions: _selectedConditions,
              onConditionToggle: (cond) => setState(() {
                _selectedConditions.contains(cond)
                    ? _selectedConditions.remove(cond)
                    : _selectedConditions.add(cond);
              }),
              expandedCategories: _expandedCategories,
              onCategoryToggle: (name) => setState(() {
                _expandedCategories.contains(name)
                    ? _expandedCategories.remove(name)
                    : _expandedCategories.add(name);
              }),
            ),
          ));
        }
        children.add(Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: showLeft ? 20 : 0,
              right: showRight ? 20 : 0,
            ),
            child: centerContent,
          ),
        ));
        if (showRight) {
          children.add(const SizedBox(
            width: _rightSidebarWidth,
            child: _RightSidebar(),
          ));
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }

  Widget _buildCenterContent(BuildContext context,
      List<ProductModel> products,
      List<ProductModel> featured,
      bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroCarousel(),
        const SizedBox(height: 28),
        const _SectionHeader(title: 'Browse by Category'),
        const SizedBox(height: 14),
        const _CategoryGrid(),
        const SizedBox(height: 32),
        _SectionHeader(
          title: 'Featured Listings',
          actionLabel: 'See all',
          onAction: widget.onSeeAllAds,
        ),
        const SizedBox(height: 14),
        if (isLoading && featured.isEmpty)
          const _GridLoader()
        else if (featured.isEmpty)
          _emptyState('No featured listings right now')
        else
          _ProductGrid(
            products: featured.take(8).toList(),
            onProductTap: widget.onProductTap,
          ),
        const SizedBox(height: 32),
        _SectionHeader(
          title: 'Recent Listings',
          actionLabel: 'See all',
          onAction: widget.onSeeAllAds,
        ),
        const SizedBox(height: 14),
        if (isLoading && products.isEmpty)
          const _GridLoader()
        else if (products.isEmpty)
          _emptyState('No listings yet — be the first to post one!')
        else
          _ProductGrid(
            products: products.take(8).toList(),
            onProductTap: widget.onProductTap,
          ),
      ],
    );
  }

  Widget _emptyState(String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO CAROUSEL
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _current = 0;
  int _count = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _sync() {
    final cms = context.read<CMSProvider>();
    final count = cms.banners.isNotEmpty ? cms.banners.length : 3;
    if (count != _count) {
      _count = count;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        final next = (_current + 1) % _count;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final cms = context.watch<CMSProvider>();
    final banners = cms.banners;
    final slides = banners.isNotEmpty
        ? banners.map((b) => {
              'title': b['title']?.toString() ?? '',
              'subtitle': b['subtitle']?.toString() ?? '',
              'image': b['imageUrl']?.toString() ?? '',
            }).toList()
        : [
            {
              'title': 'Buy & Sell Anything',
              'subtitle': 'Cars, properties, electronics, jobs & more across Pakistan.',
              'image': '',
            },
            {
              'title': 'Post Ads Free',
              'subtitle': 'Reach thousands of local buyers in minutes.',
              'image': '',
            },
            {
              'title': 'Safe & Verified Sellers',
              'subtitle': 'Meet at safe public places and deal securely.',
              'image': '',
            },
          ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _current = i),
              itemCount: slides.length,
              itemBuilder: (context, i) {
                final slide = slides[i];
                final image = slide['image'] as String;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (image.isNotEmpty)
                      Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _bannerFallback(),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _bannerFallback();
                        },
                      )
                    else
                      _bannerFallback(),
                    if (image.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 36),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('PAK SALE',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2)),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                slide['title'] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide['subtitle'] as String,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Dots
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _current ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _current
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY GRID
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    final cms = context.watch<CMSProvider>();
    final cats = cms.categories.isNotEmpty
        ? cms.categories.map((c) => {
              'name': c['name']?.toString() ?? '',
              'icon': c['icon']?.toString() ?? '',
            }).toList()
        : [
            {'name': 'Vehicles', 'icon': '🚗'},
            {'name': 'Properties', 'icon': '🏠'},
            {'name': 'Electronics', 'icon': '⚡'},
            {'name': 'Furniture & Décor', 'icon': '🪑'},
            {'name': 'WaterCrafts', 'icon': '⛵'},
            {'name': 'Jewellery', 'icon': '💎'},
            {'name': 'Lifestyle', 'icon': '🛍️'},
            {'name': 'Market', 'icon': '🛒'},
            {'name': 'Outdoor & Leisure', 'icon': '⛺'},
            {'name': 'Special Numbers', 'icon': '🔢'},
            {'name': 'Heavy Equipments', 'icon': '🏗️'},
            {'name': 'Jobs Center', 'icon': '💼'},
            {'name': 'Super Ads', 'icon': '⭐'},
          ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = (c.maxWidth / 160).floor().clamp(2, 8);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: cats.map((cat) {
            final name = cat['name']!;
            final icon = cat['icon']!;
            return _CategoryCard(
              name: name,
              icon: icon,
              onTap: () => context.push(
                  '/browse?category=${Uri.encodeQueryComponent(name)}'),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String name;
  final String icon;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(
              0, _hovered ? -3 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.gold
                  : (theme.brightness == Brightness.dark
                          ? AppColors.divider
                          : AppColors.dividerLightMode)
                      .withValues(alpha: 0.3),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18,
                  color: _hovered ? AppColors.gold : AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTIONS + GRIDS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 5,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}

class _GridLoader extends StatelessWidget {
  const _GridLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 3),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final ValueChanged<ProductModel> onProductTap;
  const _ProductGrid({required this.products, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = webGridColumns(c.maxWidth);
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
          children: products
              .map((p) => WebProductCard(
                    product: p,
                    onTap: () => onProductTap(p),
                  ))
              .toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEFT SIDEBAR — Filters & Quick Links (desktop only, >= 1000px)
// ─────────────────────────────────────────────────────────────────────────────

class _LeftSidebar extends StatelessWidget {
  final RangeValues priceRange;
  final ValueChanged<RangeValues> onPriceChanged;
  final Set<String> selectedConditions;
  final ValueChanged<String> onConditionToggle;
  final Set<String> expandedCategories;
  final ValueChanged<String> onCategoryToggle;

  const _LeftSidebar({
    required this.priceRange,
    required this.onPriceChanged,
    required this.selectedConditions,
    required this.onConditionToggle,
    required this.expandedCategories,
    required this.onCategoryToggle,
  });

  String _fmtPrice(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filters heading ──────────────────────────────────────────
          const _SidebarSectionTitle(title: 'Filters', icon: Icons.tune),
          const SizedBox(height: 14),

          // ── Price range ─────────────────────────────────────────────
          _CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('Price Range (Rs)'),
                const SizedBox(height: 6),
                RangeSlider(
                  values: priceRange,
                  min: 0,
                  max: 5000000,
                  divisions: 100,
                  activeColor: AppColors.gold,
                  inactiveColor: (isDark
                          ? AppColors.divider
                          : AppColors.dividerLightMode)
                      .withValues(alpha: 0.5),
                  labels: RangeLabels(
                    _fmtPrice(priceRange.start),
                    _fmtPrice(priceRange.end),
                  ),
                  onChanged: onPriceChanged,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rs ${_fmtPrice(priceRange.start)}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 12, color: AppColors.textMuted),
                      Expanded(
                        child: Text(
                          'Rs ${_fmtPrice(priceRange.end)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Condition chips ─────────────────────────────────────────
          _CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('Condition'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    'New',
                    'Used',
                    'Like New',
                    'Sale',
                    'Rent',
                    'Exchange'
                  ].map((c) {
                    final sel = selectedConditions.contains(c);
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => onConditionToggle(c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.gold.withValues(alpha: 0.2)
                                : theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? AppColors.gold
                                  : (isDark
                                          ? AppColors.divider
                                          : AppColors.dividerLightMode)
                                      .withValues(alpha: 0.3),
                              width: sel ? 1.2 : 1,
                            ),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: sel
                                  ? AppColors.gold
                                  : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Mini Category Tree ──────────────────────────────────────
          const _CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardTitle('Categories'),
                SizedBox(height: 6),
                _MiniCategoryTree(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Quick Links ─────────────────────────────────────────────
          const _SidebarSectionTitle(title: 'Quick Links', icon: Icons.link),
          const SizedBox(height: 14),
          _CardBox(
            child: Column(
              children: [
                _QuickLinkTile(
                  icon: Icons.local_offer_outlined,
                  label: 'Post Free Ad',
                  onTap: () => context.go(webTabPath(WebTab.postAd)),
                  highlight: true,
                ),
                const _Divider(),
                _QuickLinkTile(
                  icon: Icons.list_alt_outlined,
                  label: 'My Ads',
                  onTap: () => context.go(webTabPath(WebTab.account)),
                ),
                const _Divider(),
                _QuickLinkTile(
                  icon: Icons.safety_check_outlined,
                  label: 'Safe Meeting Guide',
                  onTap: () => context.push('/safe-meeting'),
                ),
                const _Divider(),
                _QuickLinkTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Verify Your Account',
                  onTap: () => context.go(webTabPath(WebTab.account)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SidebarSectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gold),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CardBox extends StatelessWidget {
  final Widget child;
  const _CardBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
                .withValues(alpha: 0.25)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String label;
  const _CardTitle(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(
        color: theme.textTheme.titleLarge?.color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;
  const _QuickLinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon,
                  size: 15,
                  color: highlight ? AppColors.gold : AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        highlight ? FontWeight.w700 : FontWeight.w500,
                    color: highlight
                        ? AppColors.gold
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: 1,
      color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
          .withValues(alpha: 0.2),
    );
  }
}

class _MiniCategoryTree extends StatelessWidget {
  const _MiniCategoryTree();

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Offers', '🏷️', <(String, String)>[]),
      ('Vehicles', '🚗', <(String, String)>[
        ('Cars', ''),
        ('Bikes & Motorcycles', ''),
        ('Trucks & Buses', ''),
        ('WaterCrafts', ''),
      ]),
      ('Properties', '🏠', <(String, String)>[
        ('Houses for Sale', ''),
        ('Plots & Land', ''),
        ('Rentals', ''),
        ('Commercial', ''),
      ]),
      ('Electronics', '⚡', <(String, String)>[
        ('Mobile Phones', ''),
        ('Computers & Laptops', ''),
        ('TV & Video', ''),
        ('Home Appliances', ''),
      ]),
      ('Furniture & Décor', '🪑', <(String, String)>[]),
      ('Jewellery', '💎', <(String, String)>[]),
      ('Jobs Center', '💼', <(String, String)>[]),
    ];
    return Column(
      children: categories.map((cat) {
        final (name, icon, sub) = cat;
        return _TreeTile(name: name, icon: icon, subCategories: sub);
      }).toList(),
    );
  }
}

class _TreeTile extends StatefulWidget {
  final String name;
  final String icon;
  final List<(String, String)> subCategories;
  const _TreeTile({
    required this.name,
    required this.icon,
    required this.subCategories,
  });

  @override
  State<_TreeTile> createState() => _TreeTileState();
}

class _TreeTileState extends State<_TreeTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSub = widget.subCategories.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: hasSub
                ? () => setState(() => _expanded = !_expanded)
                : () => context.push(
                    '/browse?category=${Uri.encodeQueryComponent(widget.name)}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasSub)
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded && hasSub)
          Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 4),
            child: Column(
              children: widget.subCategories.map((sub) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.push(
                        '/browse?category=${Uri.encodeQueryComponent(widget.name)}'
                        '&subCategory=${Uri.encodeQueryComponent(sub.$1)}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 5, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sub.$1,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RIGHT SIDEBAR — Super Ads, Trending, Sellers (desktop only, >= 1280px)
// ─────────────────────────────────────────────────────────────────────────────

class _RightSidebar extends StatelessWidget {
  const _RightSidebar();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Super Ads
          _SidebarSectionTitle(title: 'Super Ads', icon: Icons.star_rounded),
          SizedBox(height: 14),
          _SuperAdsCard(),
          SizedBox(height: 22),

          // Trending Searches
          _SidebarSectionTitle(
              title: 'Trending Searches', icon: Icons.local_fire_department),
          SizedBox(height: 14),
          _TrendingSearchesCard(),
          SizedBox(height: 22),

          // PS Updates
          _SidebarSectionTitle(title: 'PS Updates', icon: Icons.campaign),
          SizedBox(height: 14),
          _PSUpdatesCard(),
        ],
      ),
    );
  }
}

class _SuperAdsCard extends StatelessWidget {
  const _SuperAdsCard();

  @override
  Widget build(BuildContext context) {
    final featured = context.select((ProductProvider p) => p.featuredProducts);
    final list =
        featured.isEmpty ? SampleData.products.take(3).toList() : featured.take(3).toList();
    return _CardBox(
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            _SuperAdTile(product: list[i]),
            if (i != list.length - 1) const _Divider(),
          ],
        ],
      ),
    );
  }
}

class _SuperAdTile extends StatelessWidget {
  final ProductModel product;
  const _SuperAdTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push('/listing/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: product.imageUrls.isNotEmpty
                    ? Image.network(product.imageUrls[0], fit: BoxFit.cover)
                    : Container(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        child: const Icon(Icons.star, color: AppColors.gold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs ${product.price == 0 ? 'Contact' : product.price}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            '⭐ FEATURED',
                            style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 8,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.city.isNotEmpty
                              ? product.city
                              : product.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingSearchesCard extends StatelessWidget {
  const _TrendingSearchesCard();

  @override
  Widget build(BuildContext context) {
    final trendings = [
      'Honda Civic 2018',
      '1 Kanal House Sargodha',
      'iPhone 14 Pro',
      'Suzuki Cultus 2020',
      '5 Marla Plot',
      'Toyota Corolla Gli',
      'Used Laptop i7',
      'Gold Ring Design',
    ];
    return _CardBox(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < trendings.length; i++)
            _TrendTag(
              rank: i + 1,
              text: trendings[i],
            ),
        ],
      ),
    );
  }
}

class _TrendTag extends StatelessWidget {
  final int rank;
  final String text;
  const _TrendTag({required this.rank, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hot = rank <= 3;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.push(
            '/browse?q=${Uri.encodeQueryComponent(text)}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: hot
                ? AppColors.gold.withValues(alpha: 0.18)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hot
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : (isDark ? AppColors.divider : AppColors.dividerLightMode)
                      .withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$rank',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: hot ? AppColors.gold : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PSUpdatesCard extends StatelessWidget {
  const _PSUpdatesCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updates = [
      (
        '🎉 Eid Sale Started',
        'Post ads free and reach millions this Eid season. Limited time!',
        true,
      ),
      (
        '⭐ New: Verified Badge',
        'Get your account verified now and appear in search first.',
        true,
      ),
      (
        '🛡️ Safe Meeting Tips',
        'Always meet at public places and inspect items before payment.',
        false,
      ),
    ];
    return _CardBox(
      child: Column(
        children: [
          for (var i = 0; i < updates.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: (updates[i].$3
                              ? AppColors.gold
                              : AppColors.bluePersonal)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        updates[i].$3
                            ? Icons.campaign_outlined
                            : Icons.info_outline,
                        size: 14,
                        color: updates[i].$3
                            ? AppColors.gold
                            : AppColors.bluePersonal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          updates[i].$1,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          updates[i].$2,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i != updates.length - 1) const _Divider(),
          ],
        ],
      ),
    );
  }
}
