import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';
import '../main.dart';
import 'product_detail_screen.dart';
import 'chat_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  final String sellerName;
  final String sellerPhone;
  final String sellerType;
  final String location;

  const SellerProfileScreen({
    super.key,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerType,
    required this.location,
  });

  List<ProductModel> _sellerListings() => SampleData.products
      .where((p) => p.sellerName == sellerName)
      .toList();

  @override
  Widget build(BuildContext context) {
    final listings = _sellerListings();
    // Use all products as demos if none matched (mock data)
    final displayListings =
    listings.isNotEmpty ? listings : SampleData.products.take(4).toList();
    final isBusiness = sellerType.toLowerCase() == 'business';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profile link copied!'),
                  backgroundColor: AppColors.gold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Profile header ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.card,
                    border: Border.all(color: AppColors.gold, width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      sellerName.isNotEmpty
                          ? sellerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 34,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Name + verified
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(sellerName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified,
                      color: AppColors.gold, size: 18),
                ]),
                const SizedBox(height: 4),
                // Type badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBusiness
                        ? AppColors.gold.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isBusiness
                            ? AppColors.gold.withOpacity(0.5)
                            : Colors.blue.withOpacity(0.5)),
                  ),
                  child: Text(
                    isBusiness ? '🏢 Business Seller' : '👤 Personal Seller',
                    style: TextStyle(
                        color: isBusiness ? AppColors.gold : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(location,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ]),
                const SizedBox(height: 20),
                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(value: '${displayListings.length}', label: 'Listings'),
                      _Divider(),
                      _Stat(
                          value:
                          '${displayListings.fold(0, (s, p) => s + p.views)}',
                          label: 'Total Views'),
                      _Divider(),
                      const _Stat(value: '4.8 ⭐', label: 'Rating'),
                      _Divider(),
                      const _Stat(value: '2 yrs', label: 'Member'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contact buttons
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCallDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.phone,
                          color: Colors.white, size: 16),
                      label: const Text('Call',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConversationScreen(chat: {
                            'name': sellerName,
                            'avatar': '👤',
                            'isOnline': true,
                            'lastMessage': 'Hello, I have a question.',
                            'time': 'now',
                            'unread': 0,
                          }),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.chat,
                          color: Colors.white, size: 16),
                      label: const Text('Chat',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          // ── Seller's listings ────────────────────────────────────────────
          SectionHeader(
            title: "Seller's Listings",
            actionText: '${displayListings.length} ads',
          ),
          ...displayListings.map((p) => ProductCard(
            product: p,
            showCompareButton: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: p)),
            ),
          )),
        ],
      ),
    );
  }

  void _showCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Call Seller',
            style: TextStyle(color: Colors.white)),
        content: Text('Call $sellerName at\n$sellerPhone',
            style: const TextStyle(
                color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Calling $sellerPhone…'),
                  backgroundColor: AppColors.orange));
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Call',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: AppColors.divider.withOpacity(0.4));
}