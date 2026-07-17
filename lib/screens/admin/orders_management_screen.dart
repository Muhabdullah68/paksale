import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/currency_provider.dart';
import '../../theme/app_theme.dart';

class AdminOrdersManagementScreen extends StatefulWidget {
  const AdminOrdersManagementScreen({super.key});

  @override
  State<AdminOrdersManagementScreen> createState() => _AdminOrdersManagementScreenState();
}

class _AdminOrdersManagementScreenState extends State<AdminOrdersManagementScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('COD Orders'),
        backgroundColor: AppColors.primary,
        actions: [
          DropdownButton<String>(
            value: _filter,
            dropdownColor: AppColors.primary,
            style: const TextStyle(color: Colors.white),
            underline: Container(),
            items: ['All', 'pending', 'confirmed', 'delivered', 'cancelled']
                .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _filter = v);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: context.read<OrderProvider>().getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }

          final docs = snapshot.data!.docs;
          final allOrders = docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

          final orders = _filter == 'All'
              ? allOrders
              : allOrders.where((o) => o.status == _filter).toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No COD orders found', style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: orders.length,
              itemBuilder: (_, i) => _buildOrderCard(orders[i], isDark, currency),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, bool isDark, CurrencyProvider currency) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
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
                      Text(order.productTitle, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
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
                  child: Text(order.status.toUpperCase(), style: TextStyle(color: _statusColor(order.status), fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text('Buyer: ${order.buyerName}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.person, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text('Seller: ${order.sellerName}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(child: Text('Buyer: ${order.buyerPhone}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            if (order.buyerAddress != null && order.buyerAddress!.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(child: Text(order.buyerAddress!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ]),
            if (order.deliveryLocation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.store_outlined, size: 12, color: AppColors.gold),
                const SizedBox(width: 4),
                Expanded(child: Text('Seller delivers to: ${order.deliveryLocation}', style: const TextStyle(color: AppColors.gold, fontSize: 11), overflow: TextOverflow.ellipsis)),
              ]),
            ],
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ]),
          ],
        ),
      ),
    );
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
}
