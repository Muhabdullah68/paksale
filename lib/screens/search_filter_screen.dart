import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
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
    'All', 'Vehicles', 'Properties', 'Mobile Phones',
    'Electronics', 'Computers & Parts', 'Furniture', 'Jewellery', 'Jobs Center'
  ];
  final List<String> _locations = [
    'All', 'Doha', 'Al Rayyan', 'Lusail', 'Al Khor', 'Al Wakrah', 'West Bay'
  ];

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final result = <String, dynamic>{
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Search & Filter', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: const Text('Reset All', style: TextStyle(color: AppColors.orange, fontSize: 14)),
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
                      decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5))),
                      child: Row(
                        children: [
                          const Text('Basic Search',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Icon(_isBasicSearchExpanded ? Icons.expand_less : Icons.chevron_right,
                              color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  if (_isBasicSearchExpanded) ...[
                    const SizedBox(height: 12),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Keywords...',
                        prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.card,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 20),
                  // Category
                  _buildSectionTitle('Category'),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    underline: Container(height: 1, color: AppColors.divider),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? 'All'),
                  ),
                  const SizedBox(height: 24),
                  // Price range
                  _buildSectionTitle('Price'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'Min Q.R',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.card,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.arrow_forward, color: AppColors.textMuted),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _maxController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'Max Q.R',
                            hintStyle: TextStyle(color: AppColors.textMuted),
                            filled: true,
                            fillColor: AppColors.card,
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
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(r, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Condition
                  _buildSectionTitle('Condition'),
                  const SizedBox(height: 10),
                  _buildChips(_conditions, _selectedCondition, (i) => setState(() => _selectedCondition = i)),
                  const SizedBox(height: 24),
                  // Seller type
                  _buildSectionTitle('Seller Type'),
                  const SizedBox(height: 10),
                  _buildChips(_sellerTypes, _selectedSeller, (i) => setState(() => _selectedSeller = i)),
                  const SizedBox(height: 24),
                  // Location
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedLocation,
                    isExpanded: true,
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    underline: Container(height: 1, color: AppColors.divider),
                    items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
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
              child: const Text('Apply & Search',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500));
  }

  Widget _buildChips(List<String> items, int selected, ValueChanged<int> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((e) {
        final isSelected = selected == e.key;
        return GestureDetector(
          onTap: () => onSelect(e.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.gold : AppColors.divider),
            ),
            child: Text(e.value,
                style: TextStyle(
                    color: isSelected ? AppColors.gold : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ),
        );
      }).toList(),
    );
  }
}