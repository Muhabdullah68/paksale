import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/language_provider.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final _keywordsController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  bool _isBasicSearchExpanded = false;
  int _selectedCondition = 0;
  int _selectedSeller = 0;
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';

  final List<String> _conditions = ['All', 'Sale', 'Rent', 'Exchange', 'Free'];
  final List<String> _sellerTypes = ['All', 'Personal', 'Business'];
  final List<String> _categories = [
    'All', 'Vehicles', 'Properties', 'Electronics',
    'Furniture & Décor', 'WaterCrafts', 'Jewellery', 'Lifestyle',
    'Market', 'Outdoor & Leisure', 'Special Numbers', 'Heavy Equipments',
    'Jobs Center', 'Super Ads'
  ];
  final List<String> _locations = [
    'All', 'Karachi', 'Lahore', 'Islamabad', 'Rawalpindi', 'Faisalabad', 'Multan', 'Peshawar', 'Quetta', 'Sialkot', 'Gujranwala'
  ];

  @override
  void dispose() {
    _keywordsController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final result = <String, dynamic>{
      'query': _keywordsController.text.trim().isEmpty ? null : _keywordsController.text.trim(),
      'condition': _conditions[_selectedCondition] == 'All'
          ? null
          : _conditions[_selectedCondition],
      'sellerType': _sellerTypes[_selectedSeller] == 'All'
          ? null
          : _sellerTypes[_selectedSeller],
      'category': _selectedCategory == 'All' ? null : _selectedCategory,
      'location': _selectedLocation == 'All' ? null : _selectedLocation,
      'minPrice': _minController.text.isNotEmpty
          ? double.tryParse(_minController.text)
          : null,
      'maxPrice': _maxController.text.isNotEmpty
          ? double.tryParse(_maxController.text)
          : null,
    };
    Navigator.pop(context, result);
  }


  void _resetAll() {
    setState(() {
      _minController.clear();
      _maxController.clear();
      _selectedCondition = 0;
      _selectedSeller = 0;
      _selectedCategory = 'All';
      _selectedLocation = 'All';
      _isBasicSearchExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(t['search_filter'] ?? 'Search & Filter', style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: Text(t['reset_all'] ?? 'Reset All', style: const TextStyle(color: AppColors.orange, fontSize: 14)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic search expandable
                  GestureDetector(
                    onTap: () => setState(() => _isBasicSearchExpanded = !_isBasicSearchExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: isDark ? AppColors.divider : AppColors.dividerLightMode, width: 0.5))),
                      child: Row(
                        children: [
                          Text(t['basic_search'] ?? 'Basic Search',
                              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Icon(_isBasicSearchExpanded ? Icons.expand_less : Icons.chevron_right,
                              color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                        ],
                      ),
                    ),
                  ),
                  if (_isBasicSearchExpanded) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keywordsController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: t['keywords_hint'] ?? 'Keywords...',
                        prefixIcon: Icon(Icons.search, color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                        hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                        filled: true,
                        fillColor: theme.cardTheme.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 20),
                  // Category
                  _buildSectionTitle(t['category'] ?? 'Category', context),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: theme.cardTheme.color,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                    underline: Container(height: 1, color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(t[c.toLowerCase().replaceAll(' ', '_')] ?? c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? 'All'),
                  ),
                  const SizedBox(height: 24),
                  // Price range
                  _buildSectionTitle(t['price'] ?? 'Price', context),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: t['min_price'] ?? 'Min Rs.',
                            hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                            filled: true,
                            fillColor: theme.cardTheme.color,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.arrow_forward, color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _maxController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: t['max_price'] ?? 'Max Rs.',
                            hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                            filled: true,
                            fillColor: theme.cardTheme.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Quick price chips
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['0–1K', '1K–5K', '5K–50K', '50K–200K', '200K+'].map((r) {
                      return GestureDetector(
                        onTap: () {
                          final parts = r.replaceAll('K', '000').replaceAll('+', '').split('–');
                          _minController.text = parts[0].replaceAll('0000', '0');
                          if (parts.length > 1) _maxController.text = parts[1].replaceAll('0000', '0');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                          ),
                          child: Text(r, style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Condition
                  _buildSectionTitle(t['condition'] ?? 'Condition', context),
                  const SizedBox(height: 10),
                  _buildChips(_conditions, _selectedCondition, (i) => setState(() => _selectedCondition = i), context),
                  const SizedBox(height: 24),
                  // Seller type
                  _buildSectionTitle(t['seller_type'] ?? 'Seller Type', context),
                  const SizedBox(height: 10),
                  _buildChips(_sellerTypes, _selectedSeller, (i) => setState(() => _selectedSeller = i), context),
                  const SizedBox(height: 24),
                  // Location
                  _buildSectionTitle(t['location'] ?? 'Location', context),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedLocation,
                    isExpanded: true,
                    dropdownColor: theme.cardTheme.color,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                    underline: Container(height: 1, color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                    items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(t[l.toLowerCase().replaceAll(' ', '_')] ?? l))).toList(),
                    onChanged: (v) => setState(() => _selectedLocation = v ?? 'All'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(t['apply_search'] ?? 'Apply & Search',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final theme = Theme.of(context);
    return Text(title,
        style: TextStyle(
            color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w500));
  }

  Widget _buildChips(List<String> items, int selected, ValueChanged<int> onSelect, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((e) {
        final isSelected = selected == e.key;
        final label = t[e.value.toLowerCase()] ?? e.value;
        return GestureDetector(
          onTap: () => onSelect(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : theme.cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.gold : (isDark ? AppColors.divider : AppColors.dividerLightMode)),
            ),
            child: Text(label,
                style: TextStyle(
                    color: isSelected ? AppColors.gold : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ),
        );
      }).toList(),
    );
  }
}
