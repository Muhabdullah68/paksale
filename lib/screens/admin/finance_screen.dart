import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  String _timeframe = 'Monthly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance & Revenue'),
        backgroundColor: AppColors.primary,
        actions: [
          DropdownButton<String>(
            value: _timeframe,
            dropdownColor: AppColors.primary,
            style: const TextStyle(color: Colors.white),
            underline: Container(),
            items: ['Daily', 'Weekly', 'Monthly']
                .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _timeframe = v);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildRevenueBreakdown(isDark),
            const SizedBox(height: 24),
            _buildRecentTransactions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Revenue',
            value: 'Rs. 1,250,000',
            icon: Icons.payments_outlined,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'AdMob Earnings',
            value: 'Rs. 45,000',
            icon: Icons.ads_click,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBreakdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Revenue Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.divider : Colors.black12),
          ),
          child: Column(
            children: [
              _buildBarRow('Product Sales', 0.75, Colors.green),
              const SizedBox(height: 12),
              _buildBarRow('Subscriptions', 0.20, Colors.blue),
              const SizedBox(height: 12),
              _buildBarRow('Featured Ads', 0.05, AppColors.gold),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarRow(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('${(percentage * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withValues(alpha: 0.1),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Amount')),
              DataColumn(label: Text('Status')),
            ],
            rows: [
              _buildDataRow('2026-05-24', 'Product Sale', 'Rs. 5,000', 'Completed'),
              _buildDataRow('2026-05-24', 'Subscription', 'Rs. 1,500', 'Completed'),
              _buildDataRow('2026-05-23', 'Featured Ad', 'Rs. 500', 'Completed'),
              _buildDataRow('2026-05-23', 'Product Sale', 'Rs. 12,000', 'Pending'),
              _buildDataRow('2026-05-22', 'Subscription', 'Rs. 1,500', 'Completed'),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(String date, String type, String amount, String status) {
    return DataRow(cells: [
      DataCell(Text(date)),
      DataCell(Text(type)),
      DataCell(Text(amount, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(status,
          style: TextStyle(color: status == 'Completed' ? Colors.green : Colors.orange))),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.divider : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
