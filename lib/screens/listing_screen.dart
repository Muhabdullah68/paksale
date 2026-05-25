import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/product_provider.dart';
import '../services/language_provider.dart';
import '../widgets/common_widgets.dart';
import 'product_detail_screen.dart';
import 'search_filter_screen.dart';
import 'notifications_screen.dart';

class ListingScreen extends StatefulWidget {
  final ProductModel? product;
  final String? categoryTitle;

  const ListingScreen({super.key, this.product, this.categoryTitle});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  bool _isGridView = false;
  String _searchQuery = '';
  String? _selectedCondition;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedLocation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchProducts();
    });
  }

  void _fetchProducts({bool refresh = true}) {
    context.read<ProductProvider>().fetchProducts(
      category: widget.categoryTitle,
      refresh: refresh,
      condition: _selectedCondition,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      location: _selectedLocation,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchProducts(refresh: false);
    }
  }

  void _filterProducts() {
    _fetchProducts(refresh: true);
  }

  List<ProductModel> _getFilteredList(List<ProductModel> products) {
    var filtered = List<ProductModel>.from(products);

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
      filtered = filtered.where((p) => 
        p.location.contains(_selectedLocation!) || 
        p.city.contains(_selectedLocation!) || 
        p.village.contains(_selectedLocation!)
      ).toList();
    }

    return filtered;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productProvider = context.watch<ProductProvider>();
    final t = context.watch<LanguageProvider>().t;
    final filteredProducts = _getFilteredList(productProvider.products);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? AppColors.primaryDark : AppColors.primary,
            child: CustomSearchBar(
              onPrimaryBackground: true,
              hint: '${t['search_hint'] ?? "Search in PakistanSale..."} ${widget.categoryTitle ?? ""}',
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // ── Category chip + view-mode toggles ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? AppColors.primaryDark : AppColors.primary.withValues(alpha: 0.9),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.card : Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.divider : Colors.white30),
                    ),
                    child: Text(
                      widget.categoryTitle != null 
                        ? (t[widget.categoryTitle?.toLowerCase().replaceAll(' ', '_')] ?? widget.categoryTitle ?? '')
                        : (t['all_categories'] ?? 'All Categories'),
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
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: (isDark ? AppColors.divider : Colors.grey).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list,
                            size: 14,
                            color: _selectedCondition != null ? AppColors.gold : (isDark ? Colors.white : Colors.black87)),
                        const SizedBox(width: 4),
                        Text(
                          _selectedCondition != null ? (t['filtered'] ?? 'Filtered') : (t['filter'] ?? 'Filter'),
                          style: TextStyle(
                            color: _selectedCondition != null ? AppColors.gold : (isDark ? Colors.white : Colors.black87),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredProducts.length} ${t['results'] ?? "results"}',
                  style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Icon(Icons.sort, color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 18),
              ],
            ),
          ),

          Expanded(
            child: RepaintBoundary(
              child: productProvider.isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : productProvider.error != null
                      ? _buildErrorState(productProvider.error!)
                      : filteredProducts.isEmpty
                          ? _buildEmptyState()
                          : _isGridView
                              ? _buildGrid(filteredProducts, productProvider.isLoadingMore)
                              : _buildList(filteredProducts, productProvider.isLoadingMore),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────────
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchProducts(),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
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
                    size: 72, color: AppColors.textMuted.withValues(alpha: 0.35)),
                const SizedBox(height: 20),
                Text(
                  'No listings found',
                  style: TextStyle(
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters or search query',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13),
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
  Widget _buildGrid(List<ProductModel> products, bool isLoadingMore) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length + (isLoadingMore ? 2 : 0),
      itemBuilder: (ctx, i) {
        if (i >= products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }
        return ProductCard(
          product: products[i],
          isGridView: true,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: products[i]))),
        );
      },
    );
  }

  // ── List ────────────────────────────────────────────────────────────────────
  Widget _buildList(List<ProductModel> products, bool isLoadingMore) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: products.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i >= products.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }
        return ProductCard(
          product: products[i],
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ProductDetailScreen(product: products[i]))),
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : (isDark ? AppColors.card : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: active ? Colors.white : (isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
      ),
    );
  }
}
