import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_theme.dart';
import '../product_detail_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchAllProductsForAdmin(
          status: _selectedStatus == 'All' ? null : _selectedStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: AppColors.primary,
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            dropdownColor: AppColors.primary,
            style: const TextStyle(color: Colors.white),
            underline: Container(),
            items: ['pending', 'approved', 'rejected', 'All']
                .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedStatus = v);
                _fetchProducts();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : productProvider.allProducts.isEmpty
              ? const Center(child: Text('No products found'))
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      columns: const [
                        DataColumn(label: Text('Image')),
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Location')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Action')),
                      ],
                      rows: productProvider.allProducts.map((p) {
                        return DataRow(cells: [
                          DataCell(
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: p.imageUrls.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(p.imageUrls.first),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: p.imageUrls.isEmpty
                                  ? const Icon(Icons.image, size: 20)
                                  : null,
                            ),
                          ),
                          DataCell(SizedBox(
                              width: 150,
                              child: Text(p.title,
                                  maxLines: 1, overflow: TextOverflow.ellipsis))),
                          DataCell(Text('${p.price} ${p.currency}')),
                          DataCell(Text(p.location)),
                          DataCell(_buildStatusBadge(p.status)),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: AppColors.gold, size: 20),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailScreen(product: p)),
                                ),
                              ),
                              if (p.status == 'pending') ...[
                                IconButton(
                                  icon: const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20),
                                  onPressed: () => _updateStatus(p.id, 'approved'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _updateStatus(p.id, 'rejected'),
                                ),
                              ],
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _updateStatus(String id, String status) async {
    try {
      await context.read<ProductProvider>().updateProductStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product $status successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
