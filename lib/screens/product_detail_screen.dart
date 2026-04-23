import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../main.dart';
import '../widgets/common_widgets.dart';
import 'compare_screen.dart';
import 'chat_screen.dart';
import 'seller_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    AppState().addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppState().removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    setState(() {});
  }

  bool get _isFav => AppState().isFavorite(widget.product.id);
  bool get _inCompare => AppState().isInCompare(widget.product.id);

  String _fmt(double p) => p.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  IconData _catIcon(String cat) {
    switch (cat) {
      case 'Vehicles': return Icons.directions_car;
      case 'Properties': return Icons.home;
      case 'Mobile & Tablets': return Icons.phone_iphone;
      case 'Computers & Parts': return Icons.laptop;
      case 'Home Appliances': return Icons.tv;
      case 'Video Games': return Icons.videogame_asset;
      case 'Wrist Watches': return Icons.watch;
      case 'Furniture & Décor': return Icons.chair;
      case 'Jobs Center': return Icons.work;
      case 'Jewellery': return Icons.diamond;
      default: return Icons.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final cmpCount = AppState().compareList.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: cmpCount > 0
          ? FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CompareScreen(
                    selectedProducts: AppState().compareList))),
        icon: const Icon(Icons.compare_arrows, color: Colors.white),
        label: Text('Compare ($cmpCount)',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      )
          : null,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border,
                color: _isFav ? Colors.redAccent : Colors.white),
            onPressed: () {
              AppState().toggleFavorite(p);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_isFav
                    ? 'Added to favorites ❤️'
                    : 'Removed from favorites'),
                backgroundColor:
                _isFav ? AppColors.gold : AppColors.primaryDark,
                duration: const Duration(seconds: 1),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: AppColors.gold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGallery(p),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),

                      Row(children: [
                        _SellerTypeBadge(type: p.sellerType),
                        const Spacer(),
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${p.views}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(p.postedTime,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ]),
                      const SizedBox(height: 10),

                      Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              p.price == 0 ? 'Contact' : _fmt(p.price),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (p.price > 0) ...[
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(p.currency,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14)),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(14)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.shopping_cart,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(p.condition,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          ]),
                      const SizedBox(height: 8),

                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(p.location,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ]),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () {
                          final ok = AppState().toggleCompare(p);
                          if (!ok && !_inCompare) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                    Text('Max 3 items for comparison'),
                                    backgroundColor: AppColors.orange));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_inCompare
                                    ? 'Added to compare list'
                                    : 'Removed from compare'),
                                backgroundColor: AppColors.gold,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _inCompare
                                ? AppColors.gold.withOpacity(0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _inCompare
                                    ? AppColors.gold
                                    : AppColors.divider),
                          ),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    _inCompare
                                        ? Icons.check_circle
                                        : Icons.compare_arrows,
                                    size: 16,
                                    color: _inCompare
                                        ? AppColors.gold
                                        : AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                    _inCompare
                                        ? 'In Compare List'
                                        : '+ Add to Compare',
                                    style: TextStyle(
                                        color: _inCompare
                                            ? AppColors.gold
                                            : AppColors.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),

                if (p.description.isNotEmpty) ...[
                  const SectionHeader(title: 'Description'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.description,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.6),
                            maxLines: _descExpanded ? null : 3,
                            overflow: _descExpanded
                                ? null
                                : TextOverflow.ellipsis,
                          ),
                          GestureDetector(
                            onTap: () => setState(
                                    () => _descExpanded = !_descExpanded),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                  _descExpanded ? 'Show Less' : 'Read More',
                                  style: const TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                          ),
                        ]),
                  ),
                  const Divider(color: AppColors.divider, height: 24),
                ],

                if (p.specifications.isNotEmpty) ...[
                  const SectionHeader(title: 'Specifications'),
                  _buildSpecsTable(p.specifications),
                  const SizedBox(height: 8),
                ],

                const SectionHeader(title: 'Seller'),
                _buildSellerCard(p),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(children: [
                    GestureDetector(
                      onTap: _showReportDialog,
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber,
                                color: AppColors.orange, size: 16),
                            SizedBox(width: 6),
                            Text('Report This Item',
                                style: TextStyle(
                                    color: AppColors.orange, fontSize: 13)),
                          ]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                          content: Text('Link shared!'),
                          backgroundColor: AppColors.gold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('Share',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),

                SectionHeader(
                    title: 'Similar Products',
                    actionText: 'See All',
                    onAction: () => Navigator.pop(context)),
                ...SampleData.products
                    .where((x) =>
                x.category == p.category && x.id != p.id)
                    .take(3)
                    .map((prod) => ProductCard(
                  product: prod,
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(product: prod))),
                  onCompare: () {},
                )),
                const SizedBox(height: 20),
              ],
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ContactActionButtons(
              onCall: () => _showCallDialog(p),
              onWhatsApp: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Opening WhatsApp with ${p.sellerPhone}'),
                      backgroundColor: AppColors.green)),
              onChat: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConversationScreen(chat: {
                    'name': p.sellerName,
                    'avatar': '👤',
                    'isOnline': true,
                    'lastMessage':
                    'Hi, is "${p.title.length > 30 ? p.title.substring(0, 30) : p.title}…" still available?',
                    'time': 'now',
                    'unread': 0,
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(ProductModel p) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('${p.views}',
              style:
              const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.remove_red_eye_outlined,
              color: AppColors.textMuted, size: 16),
          const Spacer(),
          if (p.isFeatured)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('⭐ Featured',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
      Container(
        height: 280,
        width: double.infinity,
        color: AppColors.surface,
        child: Center(
          child: Icon(_catIcon(p.category),
              size: 100, color: AppColors.textMuted.withOpacity(0.6)),
        ),
      ),
      Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (_, i) {
            final sel = _selectedImageIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedImageIndex = i),
              child: Container(
                width: 64,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel
                        ? AppColors.gold
                        : AppColors.divider.withOpacity(0.4),
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Icon(_catIcon(p.category),
                      size: 28, color: AppColors.textMuted),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildSpecsTable(Map<String, String> specs) {
    final entries = specs.entries.toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider.withOpacity(0.5))),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final i = e.key;
          final spec = e.value;
          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: i % 2 == 0 ? AppColors.surface : AppColors.card,
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(10))
                  : i == entries.length - 1
                  ? const BorderRadius.vertical(
                  bottom: Radius.circular(10))
                  : BorderRadius.zero,
            ),
            child: Row(children: [
              Expanded(
                  child: Text(spec.key,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14))),
              Text(spec.value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSellerCard(ProductModel p) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SellerProfileScreen(
                sellerName: p.sellerName,
                sellerPhone: p.sellerPhone,
                sellerType: p.sellerType,
                location: p.location,
              ))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider.withOpacity(0.4)),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                p.sellerName.isNotEmpty ? p.sellerName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(p.sellerName,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (p.isVerifiedSeller) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            color: AppColors.gold, size: 15),
                      ],
                    ]),
                    Text(p.sellerType,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    Text(p.location,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('View Profile',
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 16),
          ]),
        ]),
      ),
    );
  }

  void _showCallDialog(ProductModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Call Seller',
            style: TextStyle(color: Colors.white)),
        content: Text('Call ${p.sellerName} at\n${p.sellerPhone}',
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
                  content: Text('Calling ${p.sellerPhone}…'),
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

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDark,
        title: const Text('Report Listing',
            style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Why are you reporting?',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...['Scam / Fraud', 'Wrong Category', 'Inappropriate Content',
            'Duplicate Ad', 'Other']
              .map((r) => ListTile(
            leading: const Icon(Icons.radio_button_unchecked,
                color: AppColors.textMuted, size: 18),
            title: Text(r,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
            dense: true,
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                      Text('Report submitted. Thank you!'),
                      backgroundColor: AppColors.green));
            },
          )),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
        ],
      ),
    );
  }
}

class _SellerTypeBadge extends StatelessWidget {
  final String type;
  const _SellerTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isBusiness = type.toLowerCase() == 'business';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isBusiness ? AppColors.gold : Colors.blue).withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: (isBusiness ? AppColors.gold : Colors.blue)
                .withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isBusiness ? Icons.business : Icons.person,
            size: 12,
            color: isBusiness ? AppColors.gold : Colors.blue),
        const SizedBox(width: 4),
        Text(type,
            style: TextStyle(
                color: isBusiness ? AppColors.gold : Colors.blue,
                fontSize: 12)),
      ]),
    );
  }
}