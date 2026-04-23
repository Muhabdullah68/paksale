import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../main.dart';
import '../widgets/common_widgets.dart';
import '../widgets/app_drawer.dart';
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

  late final List<Widget> _screens;

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
    AppState().addListener(_onAppStateChanged);
    _screens = [
      _HomeBody(
        onProductTap: (p) => _navToProduct(p),
        onCompare: () => setState(() {}),
      ),
      const CategoriesScreen(),
      const PostAdScreen(),
      const FavoritesScreen(),
      const ChatScreen(),
      const AccountScreen(),
    ];
  }

  @override
  void dispose() {
    AppState().removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() => setState(() {});

  void _navToProduct(ProductModel p) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)))
        .then((_) => setState(() {}));
  }

  // ── Handle every possible drawer key ──────────────────────────────────────
  void _handleDrawerNavigation(String key) {
    switch (key) {
    // ── Tab switches ───────────────────────────────────────────────────────
      case 'home':
        setState(() => _currentNavIndex = _tabHome);
      case 'categories':
        setState(() => _currentNavIndex = _tabCategories);
      case 'post_ad':
        setState(() => _currentNavIndex = _tabPostAd);
      case 'favorites':
        setState(() => _currentNavIndex = _tabFavorites);
      case 'chat':
        setState(() => _currentNavIndex = _tabChat);
      case 'account':
        setState(() => _currentNavIndex = _tabAccount);

    // ── Screen pushes ──────────────────────────────────────────────────────
      case 'notifications':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      case 'search':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SearchFilterScreen()));
      case 'compare':
        if (AppState().compareList.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CompareScreen(selectedProducts: AppState().compareList),
            ),
          ).then((_) => setState(() {}));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No items in compare list yet'),
            backgroundColor: AppColors.primaryDark,
          ));
        }

    // ── These are handled fully inside the drawer via bottom sheets ────────
    // but fall through here gracefully just in case.
      case 'saved_filters':
      case 'language':
      case 'my_products':
      case 'winnings':
      case 'post_job':
      case 'my_cv':
      case 'favorite_jobs':
      case 'my_job_posts':
      case 'applied_jobs':
      // The drawer handles these with sheets — nothing to do in home_screen
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
    final cmpCount = AppState().compareList.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: AppDrawer(onItemTap: _handleDrawerNavigation),
      appBar: _currentNavIndex == _tabHome ? _buildAppBar() : null,
      floatingActionButton: cmpCount > 0
          ? FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        elevation: 4,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CompareScreen(selectedProducts: AppState().compareList),
          ),
        ).then((_) => setState(() {})),
        icon: const Icon(Icons.compare_arrows, color: Colors.white),
        label: Text(
          'Compare ($cmpCount)',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      )
          : null,
      body: IndexedStack(
        index: _currentNavIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── 6-tab bottom nav ───────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16)
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (i) => setState(() => _currentNavIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryDark,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Categories'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 28),
              activeIcon: Icon(Icons.add_circle, size: 28),
              label: 'Post Ad'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Saved'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account'),
        ],
      ),
    );
  }

  // ── App bar (Home tab only) ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            ),
            child: const Center(
              child: Text('Q',
                  style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomSearchBar(
              readOnly: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchFilterScreen())),
            ),
          ),
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.gold, shape: BoxShape.circle),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Home Body ─────────────────────────────────────────────────────────────────
class _HomeBody extends StatelessWidget {
  final Function(ProductModel) onProductTap;
  final VoidCallback onCompare;

  const _HomeBody({required this.onProductTap, required this.onCompare});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoriesRow(context),
          const SizedBox(height: 4),
          _buildMainCategories(context),
          const SizedBox(height: 8),
          const AdBannerPlaceholder(text: 'J SEVEN REAL ESTATE - Freehold For Expats'),
          _catSection(context, 'Furniture & Décor', [
            {'n': 'Furniture & Décor', 'i': '🪑'},
            {'n': 'Kitchen & Dining Room', 'i': '🍽️'},
            {'n': "Children's Room", 'i': '🧸'},
            {'n': 'Bedroom', 'i': '🛏️'},
            {'n': 'Office Furniture', 'i': '🖥️'},
            {'n': 'Living Room', 'i': '🛋️'},
          ]),
          const AdBannerPlaceholder(text: 'City Doha Furniture - ستي دوحة للأثاث'),
          _catSection(context, 'Electronics', [
            {'n': 'Mobile & Tablets', 'i': '📱'},
            {'n': 'Cameras & Equipment', 'i': '📷'},
            {'n': 'Video Games', 'i': '🎮'},
            {'n': 'Home Appliances', 'i': '📺'},
            {'n': 'Computers & Parts', 'i': '💻'},
            {'n': 'Services', 'i': '🔧'},
          ]),
          const AdBannerPlaceholder(text: 'Barcode Electronics - باركود للالكترونيات'),
          _catSection(context, 'More Categories', [
            {'n': 'Jobs Center', 'i': '💼'},
            {'n': 'Market', 'i': '🛒'},
            {'n': 'Jewellery', 'i': '💎'},
          ]),
          const AdBannerPlaceholder(text: 'iSTYLE - Experience The Best'),
          _catSection(context, 'Lifestyle', [
            {'n': 'Clothes', 'i': '👕'},
            {'n': 'Health & Beauty', 'i': '💄'},
            {'n': 'Shoes & Bags', 'i': '👟'},
            {'n': 'Kids', 'i': '🧸'},
            {'n': 'Sportswear', 'i': '⚽'},
            {'n': 'Pet Accessories', 'i': '🐾'},
          ]),
          const AdBannerPlaceholder(text: 'Liyan Jewellery - مجوهرات ليان'),
          _catSection(context, 'Outdoor & Leisure', [
            {'n': 'Camping', 'i': '⛺'},
            {'n': 'Musical Instruments', 'i': '🎸'},
            {'n': 'Wrist Watches', 'i': '⌚'},
            {'n': 'WaterCrafts', 'i': '⛵'},
          ]),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Recent Listings',
            actionText: 'See All',
            onAction: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ListingScreen())),
          ),
          ...SampleData.products.take(5).map((p) => ProductCard(
            product: p,
            onTap: () => onProductTap(p),
            onCompare: onCompare,
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStoriesRow(BuildContext context) {
    final stories = [
      {'l': 'QS Updates', 'f': true, 'cat': ''},
      {'l': 'Vehicles', 'f': false, 'cat': 'Vehicles'},
      {'l': 'Real Estate', 'f': false, 'cat': 'Properties'},
      {'l': 'Mobiles', 'f': false, 'cat': 'Mobile & Tablets'},
      {'l': 'Jobs', 'f': false, 'cat': 'Jobs Center'},
      {'l': 'Watches', 'f': false, 'cat': 'Wrist Watches'},
    ];
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
                    shape: BoxShape.circle, color: AppColors.card,
                    border: Border.all(
                        color: isFirst ? AppColors.gold : AppColors.primary,
                        width: 2.5),
                  ),
                  child: Center(
                    child: isFirst
                        ? const Text('QS', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14))
                        : const Icon(Icons.image, color: AppColors.textMuted, size: 22),
                  ),
                ),
                const SizedBox(height: 4),
                Text(s['l'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainCategories(BuildContext context) {
    final cats = [
      {'n': 'Vehicles', 'i': '🚗'}, {'n': 'Properties', 'i': '🏠'},
      {'n': 'WaterCrafts', 'i': '⛵'}, {'n': 'Special Numbers', 'i': '📟'},
      {'n': 'Heavy Equipments', 'i': '🏗️'}, {'n': 'Super Ads', 'i': '⭐'},
      {'n': 'Jobs Center', 'i': '💼'}, {'n': 'Market', 'i': '🛒'},
      {'n': 'Jewellery', 'i': '💎'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.88,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: cats.map((c) => CategoryCircle(
          name: c['n']!, icon: c['i']!, size: 70,
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