import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/compare_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/product_provider.dart';
import '../providers/report_provider.dart';
import '../providers/order_provider.dart';
import '../repositories/user_repository.dart';
import '../services/language_provider.dart';
import '../services/currency_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../web/web_shell.dart';
import 'chat_screen.dart';
import 'compare_screen.dart';
import 'listing_screen.dart';
import 'seller_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final bool webEmbedded;
  const ProductDetailScreen(
      {super.key, required this.product, this.webEmbedded = false});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  PrivacySettings? _sellerPrivacy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().incrementViews(widget.product.id);
      _loadSellerPrivacy();
    });
  }

  Future<void> _loadSellerPrivacy() async {
    try {
      final seller = await UserRepository().getUserById(widget.product.sellerId);
      if (mounted) {
        setState(() {
          _sellerPrivacy = seller?.privacy;
        });
      }
    } catch (_) {
    }
  }

  void _launchCaller() async {
    if (_sellerPrivacy != null && !_sellerPrivacy!.allowCalls) {
      _showPrivacyChatRedirect('The seller prefers in-app communication. Send them a message instead?');
      return;
    }
    final url = Uri.parse('tel:${widget.product.sellerPhone}');
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Success
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  void _launchWhatsApp() async {
    if (_sellerPrivacy != null && _sellerPrivacy!.phoneVisibility == 'nobody') {
      _showPrivacyChatRedirect('The seller keeps their contact private. Send them a message instead?');
      return;
    }
    final phone = widget.product.whatsAppNumber.isNotEmpty 
        ? widget.product.whatsAppNumber 
        : widget.product.sellerPhone;
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=Hi, I am interested in your ad: ${widget.product.title}');
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Success
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  void _showPrivacyChatRedirect(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Protected'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startChat(context, context.read<ProductProvider>().products.firstWhere((p) => p.id == widget.product.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Send Message', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String status) async {
    try {
      await context.read<ProductProvider>().updateProductStatus(widget.product.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar( 
          content: Text('Product status updated to $status'),
          backgroundColor: AppColors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _startChat(BuildContext context, ProductModel product) async {
    final auth = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final t = context.read<LanguageProvider>().t;

    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t['login_prompt'] ?? 'Please sign in to message the seller'),
        backgroundColor: AppColors.orange,
      ));
      return;
    }

    if (auth.firebaseUser!.uid == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This is your own listing. You cannot chat with yourself.'),
        backgroundColor: AppColors.orange,
      ));
      return;
    }

    ConversationModel? conv = chatProvider.findConversation(
      auth.firebaseUser!.uid,
      product.sellerId,
      product.id,
    );

    if (conv == null) {
      final newConv = ConversationModel(
        id: '',
        participants: [auth.firebaseUser!.uid, product.sellerId],
        participantNames: {
          auth.firebaseUser!.uid: auth.userModel?.name ?? 'Buyer',
          product.sellerId: product.sellerName,
        },
        participantAvatars: {
          auth.firebaseUser!.uid: auth.userModel?.avatarUrl ?? '',
          product.sellerId: '',
        },
        lastMessage: 'Interested in ${product.title}',
        lastMessageAt: DateTime.now(),
        lastSenderId: auth.firebaseUser!.uid,
        unreadCount: {product.sellerId: 1},
        productId: product.id,
        productTitle: product.title,
        productImageUrl: product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
      );

      try {
        final id = await chatProvider.startConversation(newConv);
        conv = newConv.copyWith(id: id);
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error starting conversation: $e'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(conversation: conv!),
      ),
    );
  }

  void _showMarkAsSoldDialog(BuildContext context) {
    final locationCtrl = TextEditingController();
    final nicCtrl = TextEditingController();
    final isNicRequired = widget.product.price > 20000;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Sold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Sold Location',
                hintText: 'Enter where the product was sold',
              ),
            ),
            if (isNicRequired)
              TextField(
                controller: nicCtrl,
                decoration: const InputDecoration(
                  labelText: 'Buyer\'s NIC Number',
                  hintText: 'Mandatory for products > 20,000 Rs',
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (locationCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter sold location')));
                return;
              }
              if (isNicRequired && nicCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buyer\'s NIC is mandatory for items over 20,000 Rs')));
                return;
              }

              try {
                final updatedProduct = widget.product.copyWith(
                  isSold: true,
                  soldLocation: locationCtrl.text,
                  buyerNic: nicCtrl.text,
                  status: 'sold',
                );
                await context.read<ProductProvider>().updateProduct(updatedProduct, []);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Product marked as sold successfully'),
                    backgroundColor: AppColors.green,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Confirm Sold', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _descExpanded = false;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.product;
    final favoritesProvider = context.watch<FavoritesProvider?>();
    final compareProvider = context.watch<CompareProvider>();
    final cmpCount = compareProvider.compareList.length;
    final isFav = favoritesProvider?.isFavorite(p.id) ?? false;

    final t = context.watch<LanguageProvider>().t;

    final bodyContent = _buildBodyContent(context, theme, isDark, p);
    final bottomActions = _buildBottomActions(context, theme, isDark, p);

    if (kIsWeb) {
      final webContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bodyContent,
          bottomActions,
          const SizedBox(height: 16),
        ],
      );
      return widget.webEmbedded
          ? webContent
          : WebPage(
              breadcrumbs: [WebCrumb(p.category), WebCrumb(p.title)],
              content: webContent,
            );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: cmpCount > 0
          ? FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CompareScreen(
                    selectedProducts: compareProvider.compareList))),
        icon: const Icon(Icons.compare_arrows, color: Colors.white),
        label: Text('${t['compare'] ?? 'Compare'} ($cmpCount)',
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
            icon: const Icon(Icons.report_gmailerrorred_outlined, color: Colors.white),
            onPressed: () => _showReportDialog(context),
          ),
          IconButton(
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav ? Colors.red : Colors.white),
            onPressed: () {
              if (favoritesProvider != null) {
                favoritesProvider.toggleFavorite(p);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(!isFav
                      ? (t['added_to_favorites'] ?? 'Added to favorites ❤️')
                      : (t['removed_from_favorites'] ?? 'Removed from favorites')),
                  backgroundColor:
                  !isFav ? AppColors.gold : (isDark ? AppColors.primaryDark : AppColors.primary),
                  duration: const Duration(seconds: 1),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(t['sign_in_favorites_short'] ?? 'Please sign in to save favorites'),
                  backgroundColor: AppColors.orange,
                ));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(t['link_copied'] ?? 'Link copied to clipboard!'),
                    backgroundColor: AppColors.gold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 120),
            child: bodyContent,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: bottomActions,
            ),
          ),
        ],
      ),
    );
  }

  /// The main scrollable content column (gallery + details + seller + similar).
  Widget _buildBodyContent(
      BuildContext context, ThemeData theme, bool isDark, ProductModel p) {
    final currencyProvider = context.watch<CurrencyProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGallery(p, isDark),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.title,
                          style: TextStyle(
                              color: theme.textTheme.titleLarge?.color,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),

                      Row(children: [
                        _SellerTypeBadge(
                          type: p.sellerType,
                          isVerified: p.isVerifiedSeller,
                          sellerTier: p.sellerTier,
                        ),
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
                            Flexible(
                              child: Text(
                                p.price == 0 ? 'Contact' : currencyProvider.formatPrice(p.price),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: theme.textTheme.titleLarge?.color,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                            if (p.acceptsCOD) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                    color: AppColors.green,
                                    borderRadius: BorderRadius.circular(14)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.money,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('COD',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ],
                          ]),
                      const SizedBox(height: 8),

                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${p.city}, Pakistan',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                            content: Text('Link shared!'),
                            backgroundColor: AppColors.gold)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                          ),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                    Icons.share_outlined,
                                    size: 16,
                                    color: AppColors.gold),
                                SizedBox(width: 6),
                                Text(
                                    'Share',
                                    style: TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? AppColors.divider : AppColors.dividerLightMode, height: 1),

                if (p.description.isNotEmpty) ...[
                  const SectionHeader(title: 'Description'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.description,
                            style: TextStyle(
                                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode,
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
                  Divider(color: isDark ? AppColors.divider : AppColors.dividerLightMode, height: 24),
                ],

                if (p.specifications.isNotEmpty) ...[
                  const SectionHeader(title: 'Specifications'),
                  _buildSpecsTable(p.specifications, theme, isDark),
                  const SizedBox(height: 8),
                ],

                if (p.isAuction) ...[
                  const SectionHeader(title: 'Auction & Bidding'),
                  _buildAuctionCard(p, theme, isDark),
                  const SizedBox(height: 8),
                ],

                if (p.isJob) ...[
                  const SectionHeader(title: 'Job Information'),
                  _buildJobCard(p, theme, isDark),
                  const SizedBox(height: 8),
                ],

                const SectionHeader(title: 'Seller'),
                _buildSellerCard(p, theme, isDark),


                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: GestureDetector(
                    onTap: () => _showReportDialog(context),
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
                ),

                ContactActionButtons(
                  onCall: _launchCaller,
                  onWhatsApp: _launchWhatsApp,
                  onChat: () => _startChat(context, p),
                  privacy: _sellerPrivacy,
                ),
                const SizedBox(height: 8),

                SectionHeader(
                    title: 'Similar Products',
                    actionText: 'See All',
                    onAction: () {
                      if (kIsWeb) {
                        context.push(
                            '/browse?category=${Uri.encodeQueryComponent(p.category)}');
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ListingScreen(categoryTitle: p.category)));
                      }
                    }),
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    final similar = provider.products
                        .where((x) => x.category == p.category && x.id != p.id)
                        .take(3)
                        .toList();
                    
                    if (similar.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('No similar products found', 
                            style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13)),
                      );
                    }

                    return Column(
                      children: similar.map((prod) => ProductCard(
                        product: prod,
                        onTap: () {
                          if (kIsWeb) {
                            context.pushReplacement('/listing/${prod.id}');
                          } else {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: prod)));
                          }
                        },
                        onShare: () {},
                      )).toList(),
                    );
                  },
                ),
                const SocialMediaSection(),
                const SizedBox(height: 20),
      ],
    );
  }

  /// Bottom action bar (Mark as Sold / Approve / COD / contact buttons),
  /// pinned to the bottom on mobile, in the document flow on web.
  Widget _buildBottomActions(
      BuildContext context, ThemeData theme, bool isDark, ProductModel p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
                if (context.watch<AuthProvider>().isAuthenticated && 
                    context.watch<AuthProvider>().firebaseUser!.uid == widget.product.sellerId && 
                    !widget.product.isSold)
                  Container(
                    color: theme.cardTheme.color,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showMarkAsSoldDialog(context),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text('Mark as Sold', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                if (context.watch<AuthProvider>().userModel?.isAdmin == true && widget.product.status == 'pending')
                  Container(
                    color: theme.cardTheme.color,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(context, 'approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Approve', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(context, 'rejected'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Disapprove', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (p.acceptsCOD && !p.isSold &&
                    context.watch<AuthProvider>().isAuthenticated &&
                    context.watch<AuthProvider>().firebaseUser!.uid != p.sellerId)
                  Container(
                    color: theme.cardTheme.color,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPlaceOrderDialog(context),
                        icon: const Icon(Icons.money, color: Colors.white),
                        label: const Text('Place COD Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
      ],
    );
  }

  Widget _buildGallery(ProductModel p, bool isDark) {
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
          if (p.isBoosted) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('🚀 Boosted',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
      ),
      Container(
        height: 280,
        width: double.infinity,
        color: isDark ? AppColors.surface : AppColors.backgroundLightMode,
        child: p.imageUrls.isNotEmpty
            ? Hero(
          tag: 'product_image_${p.id}',
          child: Image.network(
            p.imageUrls[_selectedImageIndex < p.imageUrls.length ? _selectedImageIndex : 0],
            fit: BoxFit.cover,
            cacheWidth: 800, // Optimize memory for detail view
            errorBuilder: (ctx, _, __) => Icon(_catIcon(p.category),
                size: 100, color: AppColors.textMuted.withValues(alpha: 0.6)),
            loadingBuilder: (ctx, child, lp) {
              if (lp == null) return child;
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            },
          ),
        )
            : Center(
          child: Icon(_catIcon(p.category),
              size: 100, color: AppColors.textMuted.withValues(alpha: 0.6)),
        ),
      ),
      if (p.imageUrls.length > 1)
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: p.imageUrls.length,
            itemBuilder: (_, i) {
              final sel = _selectedImageIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedImageIndex = i),
                child: Container(
                  width: 64,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface : AppColors.cardLightMode,
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(p.imageUrls[i]),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: sel
                          ? AppColors.gold
                          : (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
    ]);
  }

  Widget _buildSpecsTable(Map<String, String> specs, ThemeData theme, bool isDark) {
    final entries = specs.entries.toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5))),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final i = e.key;
          final spec = e.value;
          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: i % 2 == 0 ? theme.colorScheme.surface : theme.cardTheme.color,
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
                      style: TextStyle(
                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 14))),
              Flexible(
                  child: Text(spec.value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w500))),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAuctionCard(ProductModel p, ThemeData theme, bool isDark) {
    final timeLeft = p.auctionEndTime?.difference(DateTime.now());
    final isEnded = timeLeft == null || timeLeft.isNegative;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Bid', style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 12)),
                  Text(context.read<CurrencyProvider>().formatPrice(p.currentBid ?? p.price), style: const TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Time Left', style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 12)),
                  Text(
                    isEnded ? 'Auction Ended' : '${timeLeft.inDays}d ${timeLeft.inHours % 24}h ${timeLeft.inMinutes % 60}m',
                    style: TextStyle(color: isEnded ? Colors.red : AppColors.green, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isEnded)
            ElevatedButton(
              onPressed: () => _showBidDialog(p),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Place a Bid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  void _showBidDialog(ProductModel p) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ctrl = TextEditingController();
    final currentBid = p.currentBid ?? p.price;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        title: const Text('Place Your Bid', style: TextStyle(color: AppColors.gold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Bid: ${context.read<CurrencyProvider>().formatPrice(currentBid)}', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLightMode)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLightMode),
              decoration: InputDecoration(
                hintText: 'Enter amount > ${currentBid.toStringAsFixed(0)}',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: isDark ? AppColors.surface : Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final bid = double.tryParse(ctrl.text);
              if (bid == null || bid <= currentBid) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid must be higher than current bid'), backgroundColor: AppColors.orange));
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed successfully!'), backgroundColor: AppColors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Confirm Bid', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(ProductModel p, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _JobRow(label: 'Company', value: p.companyName ?? 'N/A', icon: Icons.business),
          _JobRow(label: 'Job Type', value: p.jobType ?? 'N/A', icon: Icons.work_outline),
          _JobRow(label: 'Salary', value: p.salaryRange ?? 'Not disclosed', icon: Icons.payments_outlined),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _applyForJob(p),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Apply Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _applyForJob(ProductModel p) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to apply'), backgroundColor: AppColors.orange));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply for Position'),
        content: const Text('Your profile and CV will be sent to the employer. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application sent successfully!'), backgroundColor: AppColors.green));
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showPlaceOrderDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final t = context.read<LanguageProvider>().t;
    final nameCtrl = TextEditingController(text: auth.userModel?.name ?? '');
    final phoneCtrl = TextEditingController(text: auth.userModel?.phone ?? '');
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t['login_prompt'] ?? 'Please sign in to place an order'),
        backgroundColor: AppColors.orange,
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Place COD Order'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.shopping_bag_outlined, color: AppColors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.product.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                ]),
              ),
              const SizedBox(height: 8),
              Text('Total: ${context.read<CurrencyProvider>().formatPrice(widget.product.price)}', style: const TextStyle(color: AppColors.green, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Your Name', hintText: 'Enter your full name', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Contact Number', hintText: '+92 XXX XXXXXXX', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Delivery Address', hintText: 'Enter your full address', prefixIcon: Icon(Icons.location_on_outlined)),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Delivery address is required' : null,
              ),
              if (widget.product.codDeliveryLocation != null && widget.product.codDeliveryLocation!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.store_outlined, size: 16, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Seller delivers to: ${widget.product.codDeliveryLocation}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                  ]),
                ),
              ],
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx);
              await _placeOrder(nameCtrl.text.trim(), phoneCtrl.text.trim(), addressCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text('Confirm Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(String name, String phone, String address) async {
    final auth = context.read<AuthProvider>();
    final p = widget.product;
    final order = OrderModel(
      id: '',
      productId: p.id,
      productTitle: p.title,
      productImage: p.imageUrls.isNotEmpty ? p.imageUrls[0] : '',
      price: p.price,
      currency: p.currency,
      sellerId: p.sellerId,
      sellerName: p.sellerName,
      sellerPhone: p.codContactNumber ?? p.sellerPhone,
      buyerId: auth.firebaseUser!.uid,
      buyerName: name,
      buyerPhone: phone,
      buyerAddress: address,
      deliveryLocation: p.codDeliveryLocation ?? '',
      contactNumber: p.codContactNumber,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      await context.read<OrderProvider>().placeOrder(order);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('COD order placed successfully! The seller will contact you soon.'),
          backgroundColor: AppColors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
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
          title: const Text('Report Product'),
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
                  targetId: widget.product.id,
                  targetType: ReportType.product,
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


  Widget _buildSellerCard(ProductModel p, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SellerProfileScreen(
                sellerId: p.sellerId,
                sellerName: p.sellerName,
                sellerPhone: p.sellerPhone,
                sellerType: p.sellerType,
                location: p.location,
              ))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
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
                            style: TextStyle(
                                color: theme.textTheme.bodyLarge?.color,
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
          const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('View Profile',
                style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 2),
            Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 16),
          ]),
        ]),
      ),
    );
  }
}

class _SellerTypeBadge extends StatelessWidget {
  final String type;
  final bool isVerified;
  final String sellerTier;

  const _SellerTypeBadge({
    required this.type,
    this.isVerified = false,
    this.sellerTier = 'free',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == 'business') ...[
            const Icon(Icons.store, size: 14, color: AppColors.gold),
            const SizedBox(width: 4),
          ],
          Text(
            type == 'business' ? 'Business' : 'Personal',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
          if (isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 14, color: AppColors.gold),
          ],
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _JobRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimaryLightMode)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

