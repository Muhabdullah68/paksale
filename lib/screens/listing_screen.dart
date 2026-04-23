import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../main.dart';
import '../widgets/common_widgets.dart';
import 'product_detail_screen.dart';
import 'search_filter_screen.dart';

class ListingScreen extends StatefulWidget {
  final ProductModel? product;
  final String? categoryTitle;

  const ListingScreen({super.key, this.product, this.categoryTitle});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  bool _isGridView = false;
  List<ProductModel> _filteredProducts = [];
  String _searchQuery = '';
  String? _selectedCondition;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _filterProducts();
  }

  void _filterProducts() {
    var filtered = List<ProductModel>.from(SampleData.products);

    if (widget.categoryTitle != null && widget.categoryTitle!.isNotEmpty) {
      filtered = filtered
          .where((p) =>
      p.category == widget.categoryTitle ||
          p.title.toLowerCase().contains(widget.categoryTitle!.toLowerCase()) ||
          p.subCategory == widget.categoryTitle)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
      p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q))
          .toList();
    }

    if (_selectedCondition != null && _selectedCondition!.isNotEmpty) {
      filtered = filtered.where((p) => p.condition == _selectedCondition).toList();
    }
    if (_minPrice != null) {
      filtered = filtered.where((p) => p.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      filtered = filtered.where((p) => p.price <= _maxPrice!).toList();
    }
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filtered = filtered.where((p) => p.location.contains(_selectedLocation!)).toList();
    }

    setState(() => _filteredProducts = filtered);
  }

  Future<void> _navigateToFilter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedCondition = result['condition'] as String?;
        _minPrice = result['minPrice'] as double?;
        _maxPrice = result['maxPrice'] as double?;
        _selectedLocation = result['location'] as String?;
      });
      _filterProducts();
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCondition = null;
      _minPrice = null;
      _maxPrice = null;
      _selectedLocation = null;
    });
    _filterProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // KEY FIX: true (default) means the scaffold shrinks when the keyboard
      // opens. The Expanded list / empty-state scrolls instead of overflowing.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.primaryDark,
            child: CustomSearchBar(
              hint: 'Search in ${widget.categoryTitle ?? "all categories"}...',
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _filterProducts();
              },
            ),
          ),

          // ── Category chip + view-mode toggles ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.primaryDark,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      widget.categoryTitle ?? 'All Categories',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ),
                const Spacer(),
                _ViewToggle(
                  icon: Icons.view_list,
                  active: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
                const SizedBox(width: 6),
                _ViewToggle(
                  icon: Icons.grid_view,
                  active: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
              ],
            ),
          ),

          // ── Filter / results row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _navigateToFilter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list,
                            size: 14,
                            color: _selectedCondition != null ? AppColors.gold : Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _selectedCondition != null ? 'Filtered' : 'Filter',
                          style: TextStyle(
                            color: _selectedCondition != null ? AppColors.gold : Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredProducts.length} results',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.sort, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),

          // ── Content area (Expanded = takes all remaining height) ────────────
          // Using Expanded here is the critical fix:
          //   - The Column above has fixed-height rows.
          //   - Expanded lets this section fill whatever is left.
          //   - When the keyboard opens, "whatever is left" shrinks and
          //     the scrollable inside adjusts instead of overflowing.
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyState()
                : _isGridView
                ? _buildGrid()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  // Wrapped in SingleChildScrollView + ConstrainedBox so it can scroll when the
  // keyboard is open, preventing any RenderFlex overflow.
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // Fills the visible area so content appears centred;
          // becomes scrollable when space shrinks (keyboard open).
          minHeight: MediaQuery.of(context).size.height * 0.38,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: 72, color: AppColors.textMuted.withOpacity(0.35)),
                const SizedBox(height: 20),
                const Text(
                  'No listings found',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your filters or search query',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _clearFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Clear Filters',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Grid ────────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, i) => ProductCard(
        product: _filteredProducts[i],
        isGridView: true,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: _filteredProducts[i]))),
        onCompare: () {
          AppState().toggleCompare(_filteredProducts[i]);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppState().isInCompare(_filteredProducts[i].id)
                ? 'Added to compare'
                : 'Removed from compare'),
            backgroundColor: AppColors.gold,
            duration: const Duration(seconds: 1),
          ));
        },
      ),
    );
  }

  // ── List ────────────────────────────────────────────────────────────────────
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, i) => ProductCard(
        product: _filteredProducts[i],
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: _filteredProducts[i]))),
        onCompare: () {
          AppState().toggleCompare(_filteredProducts[i]);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppState().isInCompare(_filteredProducts[i].id)
                ? 'Added to compare'
                : 'Removed from compare'),
            backgroundColor: AppColors.gold,
            duration: const Duration(seconds: 1),
          ));
        },
      ),
    );
  }
}

// ── Small helper widget ────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ViewToggle({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : AppColors.card,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: active ? Colors.white : AppColors.textMuted),
      ),
    );
  }
}