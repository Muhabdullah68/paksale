// screens/compare_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/compare_provider.dart';

class CompareScreen extends StatefulWidget {
  final List<ProductModel> selectedProducts;

  const CompareScreen({super.key, required this.selectedProducts});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  // We keep our own local copy that is the single source of truth for this
  // screen. Mutations go to AppState AND update _products together inside
  // setState, so the UI is always consistent without needing a listener.
  late List<ProductModel> _products;

  @override
  void initState() {
    super.initState();
    // FIX: AppState is a plain singleton — it has NO addListener / removeListener.
    // The old code called AppState().addListener() which does not exist and
    // caused a crash. Removed entirely. We manage state locally instead.
    _products = List.from(widget.selectedProducts);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  // Safe pop: only pops if this route is still on the stack.
  void _safePop() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _removeProduct(int index) {
    if (index < 0 || index >= _products.length) return;
    final id = _products[index].id;
    context.read<CompareProvider>().removeFromCompare(id);
    setState(() {
      _products.removeAt(index);
    });
    if (_products.isEmpty) _safePop();
  }

  // FIX: The old "Clear All" in the AppBar called AppState().clearCompare()
  // and then relied on the (non-existent) listener to pop — so nothing
  // popped the route and the screen sat over a cleared list.  The bottom-bar
  // "Clear All" called both clearCompare() AND Navigator.pop(), which caused
  // a double-pop when the listener also tried to pop. Both buttons now use
  // the same safe helper below.
  void _clearAll() {
    context.read<CompareProvider>().clearCompare();
    setState(() {
      _products.clear();
    });
    _safePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _safePop,
        ),
        title: const Text('Compare Products',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            // FIX: previously called clearCompare() only — did not pop.
            onPressed: _clearAll,
            child: const Text('Clear All',
                style: TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
      body: _products.isEmpty
          ? const Center(
        child: Text('No products to compare',
            style: TextStyle(color: AppColors.textMuted)),
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 140,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Product',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Use indexed loop so the index stays valid even
                  // after a product is removed mid-session.
                  for (int i = 0; i < _products.length; i++)
                    _ProductHeader(
                      product: _products[i],
                      onRemove: () => _removeProduct(i),
                    ),
                ],
              ),
              Divider(height: 1, color: isDark ? AppColors.divider : AppColors.dividerLightMode),

              // Comparison rows
              _ComparisonRow(
                label: 'Price',
                values: _products
                    .map((p) =>
                '${_formatPrice(p.price)} ${p.currency}')
                    .toList(),
              ),
              _ComparisonRow(
                label: 'Condition',
                values: _products.map((p) => p.condition).toList(),
              ),
              _ComparisonRow(
                label: 'Seller Type',
                values:
                _products.map((p) => p.sellerType).toList(),
              ),
              _ComparisonRow(
                label: 'Location',
                values: _products.map((p) => p.location).toList(),
              ),
              _ComparisonRow(
                label: 'Views',
                values:
                _products.map((p) => '${p.views}').toList(),
              ),
              Divider(height: 1, color: isDark ? AppColors.divider : AppColors.dividerLightMode),

              // Specifications section header
              Container(
                width: 140,
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Specifications',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ..._getAllSpecs().map((spec) => _ComparisonRow(
                label: spec['label'] as String,
                values: spec['values'] as List<String>,
              )),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.primaryDark : AppColors.backgroundLightMode,
          border: Border(
              top: BorderSide(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                // FIX: both buttons now call the same _clearAll() which
                // clears state, updates AppState, and pops exactly once.
                onPressed: _clearAll,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.clear_all,
                    color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                label: Text('Clear All',
                    style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comparison saved!'),
                      backgroundColor: AppColors.gold,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.bookmark_outline,
                    color: Colors.white),
                label: const Text('Save Comparison',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Data helpers ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _getAllSpecs() {
    final allKeys = <String>{};
    for (final product in _products) {
      allKeys.addAll(product.specifications.keys);
    }
    return allKeys.map((key) {
      return {
        'label': key,
        'values':
        _products.map((p) => p.specifications[key] ?? 'N/A').toList(),
      };
    }).toList();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
  }
}

// ── Product header card ───────────────────────────────────────────────────────
class _ProductHeader extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;

  const _ProductHeader(
      {required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 140,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Icon(
                    product.category == 'Mobile Phones'
                        ? Icons.phone_android
                        : Icons.shopping_bag,
                    size: 40,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border:
                      Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Comparison row ────────────────────────────────────────────────────────────
class _ComparisonRow extends StatelessWidget {
  final String label;
  final List<String> values;

  const _ComparisonRow(
      {required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.3), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 140,
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              label,
              style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          ...values.map(
                (value) => Container(
              width: 140,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

