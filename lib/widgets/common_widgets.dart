import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../main.dart';

// ─── App Logo ──────────────────────────────────────────────────────────────────
class AppLogo extends StatelessWidget {
  final double fontSize;
  const AppLogo({super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Qatar',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          TextSpan(
            text: 'Sale',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: AppColors.gold),
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

  const CustomSearchBar({
    super.key,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.controller,
    this.hint = 'Search in QatarSale...',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 42, maxHeight: 52),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        child: readOnly
            ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.white60, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
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
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Colors.white60, size: 18),
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
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16)],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 22,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view), label: 'Categories'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 28), activeIcon: Icon(Icons.add_circle, size: 28), label: 'Post Ad'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────
class ProductCard extends StatefulWidget {
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
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
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

  bool get _isFav => AppState().isFavorite(widget.product.id);
  bool get _inCompare => AppState().isInCompare(widget.product.id);

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return widget.isGridView ? _buildGrid() : _buildList();
  }

  Widget _buildList() {
    final p = widget.product;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider.withOpacity(0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: _buildImagePlaceholder(100, 100),
                ),
                if (p.isSold)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Text('SOLD',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
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
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            p.price == 0 ? 'Contact' : _formatPrice(p.price),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(p.price == 0 ? '' : p.currency,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _ConditionBadge(condition: p.condition),
                        const Spacer(),
                        const Icon(Icons.location_on, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(p.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${p.views}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(p.postedTime, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ),
                        const Spacer(),
                        if (widget.showCompareButton)
                          GestureDetector(
                            onTap: widget.onCompare,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _inCompare ? AppColors.gold.withOpacity(0.2) : AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                              ),
                              child: Text(_inCompare ? '✓ Compare' : '+ Compare',
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
                  AppState().toggleFavorite(widget.product);
                },
                child: Icon(_isFav ? Icons.favorite : Icons.favorite_border,
                    color: _isFav ? Colors.redAccent : AppColors.textMuted, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final p = widget.product;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider.withOpacity(0.4)),
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
                    child: _buildImagePlaceholder(double.infinity, double.infinity),
                  ),
                  if (p.isFeatured)
                    Positioned(
                      top: 6, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                        child: const Text('Featured', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    top: 6, right: 6,
                    child: GestureDetector(
                      onTap: () {
                        AppState().toggleFavorite(widget.product);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                        child: Icon(_isFav ? Icons.favorite : Icons.favorite_border,
                            size: 14, color: _isFav ? Colors.redAccent : Colors.white),
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
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    p.price == 0 ? 'Contact' : '${_formatPrice(p.price)} ${p.currency}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _ConditionBadge(condition: p.condition, small: true),
                      const Spacer(),
                      Flexible(
                        child: Text(p.postedTime, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                      ),
                    ],
                  ),
                  if (widget.showCompareButton) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onCompare,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: _inCompare ? AppColors.gold.withOpacity(0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                        ),
                        child: Text(_inCompare ? '✓ Added' : '+ Compare',
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
    );
  }

  Widget _buildImagePlaceholder(double width, double height) {
    IconData icon;
    Color color;
    switch (widget.product.category) {
      case 'Vehicles': icon = Icons.directions_car; color = const Color(0xFF1565C0); break;
      case 'Properties': icon = Icons.home; color = const Color(0xFF2E7D32); break;
      case 'Mobile Phones': icon = Icons.phone_iphone; color = const Color(0xFF00838F); break;
      case 'Electronics': icon = Icons.devices; color = const Color(0xFF6A1B9A); break;
      case 'Computers & Parts': icon = Icons.laptop; color = AppColors.primary; break;
      case 'Furniture': icon = Icons.chair; color = AppColors.primary; break;
      case 'Jobs Center': icon = Icons.work; color = AppColors.primary; break;
      case 'Jewellery': icon = Icons.diamond; color = const Color(0xFFC62828); break;
      default: icon = Icons.image; color = AppColors.primary;
    }
    return Container(
      width: width,
      height: height,
      color: color.withOpacity(0.12),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.38,
          heightFactor: 0.38,
          child: FittedBox(child: Icon(icon, color: color.withOpacity(0.4))),
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
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              border: Border.all(color: AppColors.divider.withOpacity(0.6)),
            ),
            child: Center(child: Text(icon, style: TextStyle(fontSize: size * 0.42))),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: size + 10,
            child: Text(name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, height: 1.2)),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle)),
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
    );
  }
}

// ─── Contact Action Buttons ───────────────────────────────────────────────────
class ContactActionButtons extends StatelessWidget {
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  const ContactActionButtons({super.key, this.onWhatsApp, this.onCall, this.onChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(top: BorderSide(color: AppColors.divider.withOpacity(0.5))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCall,
              icon: const Icon(Icons.phone, size: 18, color: Colors.white),
              label: const Text('Call Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onWhatsApp,
              icon: const Icon(Icons.chat, size: 18, color: Colors.white),
              label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (onChat != null) ...[
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider)),
              child: IconButton(onPressed: onChat, icon: const Icon(Icons.message_outlined, color: AppColors.gold, size: 22)),
            ),
          ],
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold), strokeWidth: 2.5),
          SizedBox(height: 12),
          Text('Loading...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.textMuted.withOpacity(0.35)),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
          color: _color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _color.withOpacity(0.5))),
      child: Text(condition, style: TextStyle(color: _color, fontSize: small ? 9 : 10, fontWeight: FontWeight.w600)),
    );
  }
}