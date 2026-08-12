import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/currency_provider.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _loadOrders() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    final uid = auth.firebaseUser!.uid;
    context.read<OrderProvider>().fetchBuyerOrders(uid);
    context.read<OrderProvider>().fetchSellerOrders(uid);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.orange;
      case 'confirmed': return AppColors.gold;
      case 'shipped': return Colors.blue;
      case 'delivered': return AppColors.green;
      case 'cancelled': return Colors.red;
      default: return AppColors.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty;
      case 'confirmed': return Icons.check_circle_outline;
      case 'shipped': return Icons.local_shipping;
      case 'delivered': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  Widget _buildOrderCard(OrderModel order) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = context.read<CurrencyProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60, height: 60,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: order.productImage.isNotEmpty
                        ? Image.network(order.productImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 28))
                        : const Icon(Icons.image, size: 28, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productTitle, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(currency.formatPrice(order.price), style: const TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor(order.status).withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_statusIcon(order.status), size: 12, color: _statusColor(order.status)),
                    const SizedBox(width: 4),
                    Text(order.status.toUpperCase(), style: TextStyle(color: _statusColor(order.status), fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(child: Text(order.sellerId == context.read<AuthProvider>().firebaseUser?.uid ? 'Buyer: ${order.buyerName}' : 'Seller: ${order.sellerName}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
              const Spacer(),
              const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
            if (order.deliveryLocation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Flexible(child: Text('Delivery: ${order.deliveryLocation}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
              ]),
            ],
            if (order.status == 'pending' && order.sellerId == context.read<AuthProvider>().firebaseUser?.uid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateOrderStatus(order.id, 'confirmed'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold, side: const BorderSide(color: AppColors.gold)),
                        child: const Text('Confirm', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _updateOrderStatus(order.id, 'cancelled'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            if (order.status == 'confirmed' && order.sellerId == context.read<AuthProvider>().firebaseUser?.uid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(order.id, 'delivered'),
                    icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                    label: const Text('Mark as Delivered', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, padding: const EdgeInsets.symmetric(vertical: 8)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await context.read<OrderProvider>().updateOrderStatus(orderId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order ${status}ed successfully'),
          backgroundColor: AppColors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('My Orders', style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Buying (${orderProvider.buyerOrders.length})'),
            Tab(text: 'Selling (${orderProvider.sellerOrders.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOrderList(orderProvider.buyerOrders, isDark),
          _buildOrderList(orderProvider.sellerOrders, isDark),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, bool isDark) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No orders yet', style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: orders.length,
        itemBuilder: (_, i) => _buildOrderCard(orders[i]),
      ),
    );
  }
}
