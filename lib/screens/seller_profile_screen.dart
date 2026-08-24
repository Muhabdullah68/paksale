import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../repositories/user_repository.dart';
import '../services/share_service.dart';
import '../widgets/common_widgets.dart';
import 'product_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String sellerPhone;
  final String sellerType;
  final String location;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerType,
    required this.location,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  PrivacySettings? _privacy;

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
  }

  Future<void> _loadPrivacy() async {
    try {
      final seller = await UserRepository().getUserById(widget.sellerId);
      if (mounted) setState(() { _privacy = seller?.privacy; });
    } catch (_) {
    }
  }

  List<ProductModel> _sellerListings() => SampleData.products
      .where((p) => p.sellerName == widget.sellerName)
      .toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listings = _sellerListings();
    final displayListings =
    listings.isNotEmpty ? listings : SampleData.products.take(4).toList();
    final isBusiness = widget.sellerType.toLowerCase() == 'business';
    final allowCall = _privacy == null || _privacy!.allowCalls;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_gmailerrorred_outlined, color: Colors.white),
            onPressed: () => _showReportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => ShareService.shareText(
              context,
              '${widget.sellerName} on Pak Sale\n${ShareService.profileUrl(widget.sellerId)}',
              title: widget.sellerName,
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [AppColors.primary, AppColors.primaryDark] 
                    : [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
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
                    color: theme.cardTheme.color,
                    border: Border.all(color: AppColors.gold, width: 2.5),
                  ),
                  child: Center(
                      child: Text(
                        widget.sellerName.isNotEmpty
                            ? widget.sellerName[0].toUpperCase()
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
                  Flexible(
                    child: Text(widget.sellerName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
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
                        ? AppColors.gold.withValues(alpha: 0.2)
                        : AppColors.bluePersonal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isBusiness
                            ? AppColors.gold.withValues(alpha: 0.5)
                            : AppColors.bluePersonal.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    isBusiness ? '🏢 Business Seller' : '👤 Personal Seller',
                    style: TextStyle(
                        color: isBusiness ? AppColors.gold : AppColors.bluePersonal,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                // Location
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(widget.location,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 20),
                // Stats row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
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
                  if (allowCall)
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
                  if (allowCall) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please start chat from one of the seller\'s ads')),
                        );
                      },
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
    if (_privacy != null && !_privacy!.allowCalls) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Privacy Protected'),
          content: const Text('The seller prefers in-app communication. Please use the chat feature from their listing.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        title: Text('Call Seller',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text('Call ${widget.sellerName} at\n${widget.sellerPhone}',
            style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final url = Uri.parse('tel:${widget.sellerPhone}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Could not launch dialer'),
                      backgroundColor: Colors.red));
                }
              }
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

  void _showReportDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please login to report'),
        backgroundColor: AppColors.orange,
      ));
      return;
    }

    ReportReason selectedReason = ReportReason.scam;
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Seller'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
                  title: Text(reason.name.toUpperCase()),
                  value: reason,
                  // ignore: deprecated_member_use
                  groupValue: selectedReason,
                  // ignore: deprecated_member_use
                  onChanged: (v) => setDialogState(() => selectedReason = v!),
                )),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(hintText: 'Describe the issue...'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final report = ReportModel(
                  id: '',
                  reporterId: auth.firebaseUser!.uid,
                  targetId: widget.sellerId,
                  targetType: ReportType.user,
                  reason: selectedReason,
                  description: descCtrl.text.trim(),
                  timestamp: DateTime.now(),
                );
                await context.read<ReportProvider>().submitReport(report);
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Report submitted successfully'),
                  backgroundColor: AppColors.green,
                ));
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(color: isDark ? AppColors.textMuted : Colors.white.withValues(alpha: 0.7), fontSize: 10)),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(width: 1, height: 28, color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.4));
  }
}

