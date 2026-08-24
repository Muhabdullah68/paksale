import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/compare_provider.dart';
import '../providers/product_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/cms_provider.dart';
import '../services/language_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/app_drawer.dart';
import '../web/web_shell.dart';
import '../web/web_home.dart';
import 'categories_screen.dart';
import 'listing_screen.dart';
import 'post_ad_screen.dart';
import 'favorites_screen.dart';
import 'account_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';
import 'compare_screen.dart';
import 'chat_screen.dart';
import 'search_filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bottom nav tab indices
  static const int _tabHome = 0;
  static const int _tabCategories = 1;
  static const int _tabPostAd = 2;
  static const int _tabFavorites = 3;
  static const int _tabChat = 4;
  static const int _tabAccount = 5;

  @override
  void initState() {
    super.initState();
  }

  void _navToProduct(ProductModel p) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)));
  }

  // ── Handle every possible drawer key ──────────────────────────────────────
  void _handleDrawerNavigation(String key) {
    switch (key) {
    // ── Tab switches ───────────────────────────────────────────────────────
      case 'home':
        setState(() => _currentNavIndex = _tabHome);
        break;
      case 'categories':
        setState(() => _currentNavIndex = _tabCategories);
        break;
      case 'post_ad':
        setState(() => _currentNavIndex = _tabPostAd);
        break;
      case 'favorites':
        setState(() => _currentNavIndex = _tabFavorites);
        break;
      case 'chat':
        setState(() => _currentNavIndex = _tabChat);
        break;
      case 'account':
        setState(() => _currentNavIndex = _tabAccount);
        break;

    // ── Screen pushes ──────────────────────────────────────────────────────
      case 'notifications':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        break;
      case 'search':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SearchFilterScreen()));
        break;
      case 'compare':
        final compareProvider = context.read<CompareProvider>();
        final t = context.read<LanguageProvider>().t;
        if (compareProvider.compareList.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CompareScreen(selectedProducts: compareProvider.compareList),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t['compare_empty'] ?? 'No items in compare list yet'),
            backgroundColor: AppColors.primaryDark,
          ));
        }
        break;

    // ── These are handled fully inside the drawer via bottom sheets ────────
      case 'saved_filters':
      case 'language':
      case 'my_products':
      case 'winnings':
      case 'post_job':
      case 'my_cv':
      case 'favorite_jobs':
      case 'my_job_posts':
      case 'applied_jobs':
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$key coming soon!'),
          backgroundColor: AppColors.gold,
          duration: const Duration(seconds: 1),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageProvider>().t;
    final compareProvider = context.watch<CompareProvider>();
    final cmsProvider = context.watch<CMSProvider>();
    final cmpCount = compareProvider.compareList.length;

    // Check for policy updates
    if (cmsProvider.needsPolicyReacceptance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPolicyUpdateDialog(context, t);
      });
    }

    if (kIsWeb) {
      return _buildWeb(context, t);
    }

    return PopScope(
      canPop: _currentNavIndex == _tabHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentNavIndex != _tabHome) {
          setState(() => _currentNavIndex = _tabHome);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: AppDrawer(onItemTap: _handleDrawerNavigation),
        appBar: _currentNavIndex == _tabHome ? _buildAppBar() : null,
        floatingActionButton: _currentNavIndex != _tabHome && cmpCount > 0
            ? FloatingActionButton.extended(
          backgroundColor: AppColors.gold,
          elevation: 4,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CompareScreen(selectedProducts: compareProvider.compareList),
            ),
          ),
          icon: const Icon(Icons.compare_arrows, color: Colors.white),
          label: Text(
            '${t['compare'] ?? 'Compare'} ($cmpCount)',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        )
            : null,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _HomeBody(
              onProductTap: (p) => _navToProduct(p),
            ),
            const CategoriesScreen(),
            const PostAdScreen(),
            const FavoritesScreen(),
            const ChatScreen(),
            const AccountScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Web shell layout ────────────────────────────────────────────────────
  Widget _buildWeb(BuildContext context, Map<String, String> t) {
    final webNav = context.watch<WebNav>();
    if (webNav.tab != _currentNavIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentNavIndex = webNav.tab);
      });
    }
    return WebPage(
      content: IndexedStack(
        index: _currentNavIndex,
        children: [
          WebHomeBody(
            onProductTap: (p) => _navToProduct(p),
            onCategoryTap: (name) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ListingScreen(categoryTitle: name),
              ),
            ),
            onSeeAllAds: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ListingScreen()),
            ),
          ),
          const CategoriesScreen(webEmbedded: true),
          const PostAdScreen(webEmbedded: true),
          const FavoritesScreen(webEmbedded: true),
          const ChatScreen(webEmbedded: true),
          const AccountScreen(webEmbedded: true),
        ],
      ),
    );
  }

  void _showPolicyUpdateDialog(BuildContext context, Map<String, String> t) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(t['policy_update_title'] ?? 'Policy Update'),
        content: Text(t['policy_update_msg'] ?? 'Our Terms of Service or Privacy Policy have been updated. Please review and accept to continue using the app.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
              Navigator.pop(ctx);
            },
            child: Text(t['view_policies'] ?? 'View Policies'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CMSProvider>().acceptPolicies();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text(t['accept'] ?? 'Accept', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 6-tab bottom nav ───────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 16)
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: t['nav_home'] ?? 'Home'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.grid_view_outlined),
              activeIcon: const Icon(Icons.grid_view),
              label: t['nav_categories'] ?? 'Categories'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline, size: 28),
              activeIcon: const Icon(Icons.add_circle, size: 28),
              label: t['nav_post_ad'] ?? 'Post Ad'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_outline),
              activeIcon: const Icon(Icons.favorite),
              label: t['nav_saved'] ?? 'Saved'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: t['nav_chat'] ?? 'Chat'),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: t['nav_account'] ?? 'Account'),
        ],
      ),
    );
  }

  // ── App bar (Home tab only) ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final t = context.watch<LanguageProvider>().t;
    final unread = context.select<NotificationProvider, int>(
        (p) => p.unreadCount);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adjust sizes for small screens
    final double logoSize = screenWidth < 360 ? 34 : 38;
    final double appLogoIconSize = screenWidth < 360 ? 22 : 24;
    final double menuPadding = screenWidth < 360 ? 8 : 12;
    final double spaceAfterLogo = screenWidth < 360 ? 8 : 10;
    final double hintFontSize = screenWidth < 360 ? 12 : 13;

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            padding: EdgeInsets.symmetric(horizontal: menuPadding),
            tooltip: t['menu'] ?? 'Menu',
          ),
          Container(
            width: logoSize, height: logoSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: AppLogoIcon(size: appLogoIconSize),
            ),
          ),
          SizedBox(width: spaceAfterLogo),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: t['search_hint'] ?? 'Search in PakistanSale...',
                hintStyle: TextStyle(color: Colors.white70, fontSize: hintFontSize),
                prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
        ]),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () => _handleDrawerNavigation('notifications'),
              ),
              if (unread > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: AppColors.gold, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text('$unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                  ),
                ),
            ],
          ),
        ],
      ),
    );  }
}

// ── Home Body ─────────────────────────────────────────────────────────────────
class _HomeBody extends StatefulWidget {
  final Function(ProductModel) onProductTap;

  const _HomeBody({required this.onProductTap});

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    final products = context.select((ProductProvider p) => p.products);
    final isLoading = context.select((ProductProvider p) => p.isLoading);
    final error = context.select((ProductProvider p) => p.error);

    return SingleChildScrollView(
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoriesRow(context),
            const SizedBox(height: 4),
            _buildMainCategories(context),
            const SizedBox(height: 8),
            _buildDynamicBanners(context),
            _catSection(context, 'Real Estate & Living', [
              {'n': 'Properties', 'i': '🏠'},
              {'n': 'Furniture & Décor', 'i': '🪑'},
              {'n': 'Market', 'i': '🛒'},
            ]),
            const AdBannerPlaceholder(text: 'City Doha Furniture - ستي دوحة للأثاث'),
            _catSection(context, 'Electronics & Tech', [
              {'n': 'Electronics', 'i': '⚡'},
              {'n': 'Computers & Parts', 'i': '💻'},
              {'n': 'Mobile & Tablets', 'i': '📱'},
            ]),
            const AdBannerPlaceholder(text: 'Barcode Electronics - باركود للالكترونيات'),
            _catSection(context, 'Leisure & Luxury', [
              {'n': 'WaterCrafts', 'i': '⛵'},
              {'n': 'Jewellery', 'i': '💎'},
              {'n': 'Outdoor & Leisure', 'i': '⛺'},
            ]),
            const AdBannerPlaceholder(text: 'iSTYLE - Experience The Best'),
            _catSection(context, 'Services & Others', [
              {'n': 'Jobs Center', 'i': '💼'},
              {'n': 'Special Numbers', 'i': '🔢'},
              {'n': 'Heavy Equipments', 'i': '🏗️'},
              {'n': 'Super Ads', 'i': '⭐'},
            ]),
            const SizedBox(height: 16),
            SectionHeader(
              title: t['recent'] ?? 'Recent Listings',
              actionText: t['see_all'] ?? 'See All',
              onAction: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ListingScreen())),
            ),
            if (isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppColors.gold),
              ))
            else if (error != null)
              _buildErrorState(context, error)
            else if (products.isEmpty)
              // Fallback to sample data if Firebase is empty/not configured
              ...SampleData.products.take(5).map((p) => ProductCard(
                product: p,
                onTap: () => widget.onProductTap(p),
              ))
            else
              ...products.take(5).map((p) => ProductCard(
                product: p,
                onTap: () => widget.onProductTap(p),
              )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicBanners(BuildContext context) {
    final banners = context.watch<CMSProvider>().banners;
    if (banners.isEmpty) {
      return const AdBannerPlaceholder(text: 'J SEVEN REAL ESTATE - Freehold For Expats');
    }

    return SizedBox(
      height: 120,
      child: PageView.builder(
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final b = banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(b['imageUrl']),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final t = context.watch<LanguageProvider>().t;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(t['error_loading'] ?? 'Error loading products',
                style: TextStyle(color: Theme.of(context).textTheme.titleMedium?.color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<ProductProvider>().fetchProducts(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              child: Text(t['retry'] ?? 'Retry', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesRow(BuildContext context) {
    final stories = [
      {'l': 'PS Updates', 'f': true, 'cat': ''},
      {'l': 'Offers', 'f': false, 'cat': 'Offers'},
      {'l': 'Vehicles', 'f': false, 'cat': 'Vehicles'},
      {'l': 'Real Estate', 'f': false, 'cat': 'Properties'},
      {'l': 'Electronics', 'f': false, 'cat': 'Electronics'},
      {'l': 'Furniture', 'f': false, 'cat': 'Furniture & Décor'},
      {'l': 'Jewellery', 'f': false, 'cat': 'Jewellery'},
      {'l': 'Jobs', 'f': false, 'cat': 'Jobs Center'},
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 98,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: stories.length,
        itemBuilder: (_, i) {
          final s = stories[i];
          final isFirst = s['f'] as bool;
          return GestureDetector(
            onTap: () {
              if (!isFirst) {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ListingScreen(categoryTitle: s['cat'] as String)));
              }
            },
            child: Container(
              width: 68,
              margin: const EdgeInsets.only(right: 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Theme.of(context).cardTheme.color,
                    border: Border.all(
                        color: isFirst ? AppColors.gold : AppColors.primary,
                        width: 2.5),
                  ),
                  child: Center(
                    child: isFirst
                        ? const Text('PS', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14))
                        : Icon(Icons.image, color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 22),
                  ),
                ),
                const SizedBox(height: 4),
                Text(s['l'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 10)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainCategories(BuildContext context) {
    final cmsProvider = context.watch<CMSProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    
    List<Map<String, String>> cats;
    if (cmsProvider.categories.isNotEmpty) {
      // Get categories from Firestore, ensure Offers is first
      final firestoreCats = cmsProvider.categories.map((c) => {'n': c['name'].toString(), 'i': c['icon'].toString()}).toList();
      // Check if Offers is already present
      final offersIndex = firestoreCats.indexWhere((c) => c['n'] == 'Offers');
      if (offersIndex != -1) {
        // Move it to first place
        final offersCat = firestoreCats.removeAt(offersIndex);
        firestoreCats.insert(0, offersCat);
      } else {
        // Add Offers at first place
        firestoreCats.insert(0, {'n': 'Offers', 'i': '🏷️'});
      }
      cats = firestoreCats;
    } else {
      // Fallback list already has Offers first
      cats = [
        {'n': 'Offers', 'i': '🏷️'},
        {'n': 'Vehicles', 'i': '🚗'}, {'n': 'Properties', 'i': '🏠'},
        {'n': 'Electronics', 'i': '⚡'}, {'n': 'Furniture & Décor', 'i': '🪑'},
        {'n': 'WaterCrafts', 'i': '⛵'}, {'n': 'Jewellery', 'i': '💎'},
        {'n': 'Lifestyle', 'i': '🛍️'}, {'n': 'Market', 'i': '🛒'},
        {'n': 'Outdoor & Leisure', 'i': '⛺'},
      ];
    }
    
    // Adjust grid parameters for different screen sizes
    final double categorySize = screenWidth < 360 ? 60 : 70;
    final double childAspectRatio = screenWidth < 360 ? 1.1 : 1.15;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: 4,
        crossAxisSpacing: 8,
        children: cats.map((c) => CategoryCircle(
          name: c['n']!, icon: c['i']!, size: categorySize,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ListingScreen(categoryTitle: c['n']))),
        )).toList(),
      ),
    );
  }

  Widget _catSection(BuildContext context, String title, List<Map<String, String>> cats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionText: 'See All',
          onAction: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
        ),
        SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => CategoryCircle(
              name: cats[i]['n']!, icon: cats[i]['i']!, size: 65,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ListingScreen(categoryTitle: cats[i]['n']))),
            ),
          ),
        ),
      ],
    );
  }
}
