import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/cms_provider.dart';
import '../widgets/common_widgets.dart';
import '../services/language_provider.dart';
import '../services/theme_provider.dart';
import '../services/currency_provider.dart';
import 'listing_screen.dart';
import 'categories_screen.dart';
import 'post_ad_screen.dart';
import 'product_detail_screen.dart';
import 'admin/admin_dashboard.dart';
import 'help_screen.dart';
import 'orders_screen.dart';


// ─── Main Account Screen ──────────────────────────────────────────────────────
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<ProductProvider>().fetchUserProducts(auth.firebaseUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, String> get _t => context.read<LanguageProvider>().t;
  bool get _isArLang => context.read<LanguageProvider>().isArabic;

  // ── Auth ─────────────────────────────────────────────────────────────────
  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AuthSheet(isRegister: false),
    );
  }

  void _showRegisterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AuthSheet(isRegister: true),
    );
  }

  void _logout() {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = _t;
    final isAr = _isArLang;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        title: Text(t['logout'] ?? 'Logout',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text(isAr
            ? 'هل أنت متأكد من تسجيل الخروج؟'
            : 'Are you sure you want to logout?',
            style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t['cancel'] ?? 'Cancel',
                style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductProvider>().clearUserProducts();
              auth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isAr
                    ? 'تم تسجيل الخروج بنجاح'
                    : 'Logged out successfully'),
                backgroundColor: AppColors.gold,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: Text(t['logout'] ?? 'Logout',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isAuthenticated;
    final theme = Theme.of(context);
    final t = context.watch<LanguageProvider>().t;
    final isAr = context.watch<LanguageProvider>().isArabic;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const AppLogo(),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => _showQuickSettings(t),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoggedIn ? _buildLoggedIn(auth.userModel, t, isAr) : _buildGuest(t),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  GUEST VIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGuest(Map<String, String> t) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
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
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.cardTheme.color,
                    border: Border.all(color: AppColors.gold, width: 2.5),
                  ),
                  child: Center(
                    child: Icon(Icons.person_outline,
                        size: 48, color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
                  ),
                ),
                const SizedBox(height: 16),
                Text(t['welcome'] ?? 'Welcome to Pak Sale',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(t['login_prompt'] ?? 'Login to manage your account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showLoginSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        child: Text(t['login'] ?? 'Login',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _showRegisterSheet,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ),
                        child: Text(t['register'] ?? 'Register',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // BROWSE section
          _buildSection(t['browse'] ?? 'BROWSE', [
            _MenuRow(
              icon: Icons.search,
              label: t['search_listings'] ?? 'Search Listings',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ListingScreen())),
            ),
            _MenuRow(
              icon: Icons.grid_view_outlined,
              label: t['all_categories'] ?? 'All Categories',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CategoriesScreen())),
            ),
            _MenuRow(
              icon: Icons.local_offer_outlined,
              label: t['featured_ads'] ?? 'Featured Ads',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ListingScreen(
                          categoryTitle: 'Featured'))),
            ),
          ], t),

          // JOB CENTER section
          _buildSection(t['job_center'] ?? 'JOB CENTER', [
            _MenuRow(
              icon: Icons.work_outline,
              label: t['browse_jobs'] ?? 'Browse Jobs',
              badge: 'New',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ListingScreen(
                          categoryTitle: 'Jobs Center'))),
            ),
            _MenuRow(
              icon: Icons.description_outlined,
              label: t['upload_cv'] ?? 'Upload CV',
              badge: 'New',
              onTap: () => _showCvUploadSheet(),
            ),
          ], t),

          // INFORMATION section
          _buildSection(t['information'] ?? 'INFORMATION', [
            _MenuRow(
              icon: Icons.language,
              label: t['language'] ?? 'Language',
              trailing: Text(
                lang.isUrdu ? 'اردو' : (lang.isArabic ? 'العربية' : 'English'),
                style: const TextStyle(
                    color: AppColors.gold, fontSize: 13),
              ),
              onTap: () => _showLanguagePicker(),
            ),
            _MenuRow(
              icon: Icons.help_outline,
              label: t['help_support'] ?? 'Help & Support',
              onTap: () => _showHelpSheet(),
            ),
            _MenuRow(
              icon: Icons.info_outline,
              label: t['about'] ?? 'About Pak Sale',
              onTap: () => _showInfoDialog(
                t['about'] ?? 'About Pak Sale',
                t['about_content'] ?? '',
              ),
            ),
            _MenuRow(
              icon: Icons.policy_outlined,
              label: t['privacy_policy'] ?? 'Privacy Policy',
              onTap: () => _showInfoDialog(
                t['privacy_policy'] ?? 'Privacy Policy',
                context.read<CMSProvider>().privacyContent.isNotEmpty
                    ? context.read<CMSProvider>().privacyContent
                    : (t['privacy_content'] ?? ''),
              ),
            ),
            _MenuRow(
              icon: Icons.gavel_outlined,
              label: t['terms'] ?? 'Terms of Service',
              onTap: () => _showInfoDialog(
                t['terms'] ?? 'Terms of Service',
                context.read<CMSProvider>().termsContent.isNotEmpty
                    ? context.read<CMSProvider>().termsContent
                    : (t['terms_content'] ?? ''),
              ),
            ),
          ], t),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGGED-IN VIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoggedIn(UserModel? user, Map<String, String> t, bool isAr) {
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              t['loading_profile'] ?? 'Loading Profile...',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    
    return NestedScrollView(
      headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
        SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(ctx),
          sliver: SliverToBoxAdapter(child: _buildProfileHeader(user, t)),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.gold,
              indicatorWeight: 3,
              labelColor: AppColors.gold,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: t['my_ads'] ?? 'My Ads'),
                Tab(text: t['favorites'] ?? 'Favorites'),
                Tab(text: t['settings'] ?? 'Settings'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyAdsTab(t: t),
          _FavoritesTab(t: t),
          _SettingsTab(
            user: user,
            onLogout: _logout,
            t: t,
            onLanguageChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, Map<String, String> t) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final productProvider = context.watch<ProductProvider>();
    final userAds = productProvider.getMyAds(user.id);
    
    final activeAdsCount = userAds.where((p) => p.status == 'approved' && !p.isSold).length;
    final soldAdsCount = userAds.where((p) => p.isSold).length;
    final boostedAdsCount = userAds.where((p) => p.isBoosted).length;
    final totalViews = userAds.fold(0, (sum, p) => sum + p.views);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
          Row(
            children: [
              // Avatar + edit button
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.surface : AppColors.cardLightMode,
                      border: Border.all(color: AppColors.gold, width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _showEditProfileSheet(user),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark ? AppColors.primaryDark : Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified,
                              color: AppColors.gold, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user.email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(user.phone,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatItem(
                      label: t['active_ads'] ?? 'Active Ads',
                      value: '$activeAdsCount'),
                  _VertDivider(),
                  Consumer<FavoritesProvider?>(
                    builder: (context, FavoritesProvider? favProvider, _) {
                      return _StatItem(
                        label: t['favorites'] ?? 'Favorites',
                        value: '${favProvider?.favoriteIds.length ?? 0}');
                    },
                  ),
                  _VertDivider(),
                  _StatItem(label: t['views'] ?? 'Views', value: '$totalViews'),
                  _VertDivider(),
                  Consumer<ChatProvider>(
                    builder: (context, ChatProvider chatProvider, _) {
                      return _StatItem(
                        label: t['chats'] ?? 'Chats', 
                        value: '${chatProvider.conversations.length}');
                    },
                  ),
                  _VertDivider(),
                  _StatItem(label: t['sold_items'] ?? 'Sold', value: '$soldAdsCount'),
                  _VertDivider(),
                  _StatItem(label: t['boost_perf'] ?? 'Boosts', value: '$boostedAdsCount'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ── Shared Section Builder ────────────────────────────────────────────────
  Widget _buildSection(String title, List<_MenuRow> rows, Map<String, String> t) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDark ? AppColors.surface : AppColors.backgroundLightMode,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  )),
              if (title == (t['information'] ?? 'INFORMATION'))
                _ThemeToggle(),
            ],
          ),
        ),
        ...rows,
      ],
    );
  }

  // ── Sheets / Dialogs ──────────────────────────────────────────────────────

  void _showQuickSettings(Map<String, String> t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickSettingsSheet(onLogout: _logout, t: t),
    );
  }

  void _showEditProfileSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: user,
        t: _t,
        onSave: (updated) {},
      ),
    );
  }

  void _showLanguagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LanguagePickerSheet(
        onChanged: () => setState(() {}),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Text(content,
              style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode,
                  fontSize: 13,
                  height: 1.6)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style:
            ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: Text(_t['close'] ?? 'Close',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showHelpSheet() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
  }

  void _showCvUploadSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CvUploadSheet(t: _t),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  MY ADS TAB
// ══════════════════════════════════════════════════════════════════════════════
class _MyAdsTab extends StatefulWidget {
  final Map<String, String> t;
  const _MyAdsTab({required this.t});

  @override
  State<_MyAdsTab> createState() => _MyAdsTabState();
}

class _MyAdsTabState extends State<_MyAdsTab> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final auth = context.watch<AuthProvider>();
    final productProvider = context.watch<ProductProvider>();

    if (!auth.isAuthenticated) {
      return Center(
        child: Text(t['please_login'] ?? 'Please login to view your ads',
            style: const TextStyle(color: AppColors.textMuted)),
      );
    }

    final myAds = productProvider.getMyAds(auth.firebaseUser!.uid);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        // Post new ad banner
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PostAdScreen())),
          child: Container(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.gold.withValues(alpha: 0.2),
                isDark ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1)
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle,
                    color: AppColors.gold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['post_new_ad'] ?? 'Post a New Ad',
                          style: TextStyle(
                              color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      Text(
                          t['reach_buyers'] ??
                              'Reach thousands of buyers',
                          style: TextStyle(
                              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode,
                              fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.gold, size: 16),
              ],
            ),
          ),
        ),
        // Status filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Active', 'Pending', 'Rejected', 'Sold']
                  .map((s) => GestureDetector(
                onTap: () => setState(() => _filter = s),
                child: _FilterChip(
                    label: s, isSelected: _filter == s),
              ))
                  .toList(),
            ),
          ),
        ),
        if (myAds.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(t['no_ads_found'] ?? 'No ads found',
                      style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          )
        else
          ...myAds.where((ad) {
            if (_filter == 'All') return true;
            if (_filter == 'Active') return ad.status == 'approved' && !ad.isSold;
            if (_filter == 'Pending') return ad.status == 'pending';
            if (_filter == 'Rejected') return ad.status == 'rejected';
            if (_filter == 'Sold') return ad.isSold;
            return true;
          }).map((ad) => _MyAdCard(product: ad, t: t)),

      ],
    );
  }
}

class _MyAdCard extends StatelessWidget {
  final ProductModel product;
  final Map<String, String> t;

  const _MyAdCard({required this.product, required this.t});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyProvider = context.watch<CurrencyProvider>();
    
    Color statusColor;
    String statusText;
    
    if (product.isSold) {
      statusColor = Colors.grey;
      statusText = 'Sold';
    } else {
      switch (product.status) {
        case 'pending':
          statusColor = AppColors.orange;
          statusText = 'Pending';
          break;
        case 'rejected':
          statusColor = Colors.red;
          statusText = 'Rejected';
          break;
        case 'approved':
        default:
          statusColor = AppColors.green;
          statusText = 'Active';
          break;
      }
    }

    return Container(
      margin:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12)),
                child: Container(
                  width: 100,
                  height: 90,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: product.imageUrls.isNotEmpty
                      ? Image.network(
                          product.imageUrls[0],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.image,
                              color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                              size: 32),
                        )
                      : Center(
                          child: Icon(Icons.image,
                              color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 32),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.price == 0
                            ? 'Contact'
                            : currencyProvider.formatPrice(product.price),
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text('${product.views}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(width: 10),
                        const Icon(Icons.access_time,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(product.postedTime,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(statusText,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),

          // Action buttons
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface.withValues(alpha: 0.5) : AppColors.backgroundLightMode,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _AdActionBtn(
                  icon: Icons.visibility_outlined,
                  label: t['view'] ?? 'View',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(product: product)),
                  ),
                ),
                const SizedBox(width: 8),
                _AdActionBtn(
                  icon: Icons.edit_outlined,
                  label: t['edit'] ?? 'Edit',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            PostAdScreen(productToEdit: product)),
                  ),
                ),
                const SizedBox(width: 8),
                _AdActionBtn(
                  icon: Icons.trending_up_outlined,
                  label: t['boost'] ?? 'Boost',
                  color: AppColors.gold,
                  onTap: () => _showBoostDialog(context),
                ),
                const Spacer(),
                _AdActionBtn(
                  icon: Icons.delete_outline,
                  label: t['delete'] ?? 'Delete',
                  color: AppColors.orange,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBoostDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Boost Your Ad',
            style: TextStyle(
                color: AppColors.gold, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Boost your listing to appear at the top of search results.',
                style: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 13)),
            const SizedBox(height: 16),
            ...[
              '3 Days — ${context.read<CurrencyProvider>().formatPrice(500)}',
              '7 Days — ${context.read<CurrencyProvider>().formatPrice(1000)}',
              '30 Days — ${context.read<CurrencyProvider>().formatPrice(3000)}'
            ]
                .map((opt) => ListTile(
              leading: const Icon(Icons.star,
                  color: AppColors.gold, size: 18),
              title: Text(opt,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLightMode, fontSize: 14)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Boost selected: $opt'),
                    backgroundColor: AppColors.gold));
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        title: Text(t['delete_ad'] ?? 'Delete Ad',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Text(
            t['delete_confirm'] ?? 'Are you sure you want to delete this ad?',
            style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t['cancel'] ?? 'Cancel',
                style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<ProductProvider>().deleteProduct(product.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(t['ad_deleted'] ?? 'Ad deleted successfully'),
                      backgroundColor: AppColors.orange));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange),
            child: Text(t['delete'] ?? 'Delete',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  FAVORITES TAB
// ══════════════════════════════════════════════════════════════════════════════
class _FavoritesTab extends StatefulWidget {
  final Map<String, String> t;
  const _FavoritesTab({required this.t});

  @override
  State<_FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<_FavoritesTab> {
  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final favoritesProvider = context.watch<FavoritesProvider?>();
    final favs = favoritesProvider?.favoriteProducts ?? [];

    if (favs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border,
                  size: 72,
                  color: AppColors.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(t['favorites'] ?? 'No Saved Items',
                  style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Items you favorite will appear here',
                  style: TextStyle(
                      color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const ListingScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                icon: const Icon(Icons.search,
                    color: Colors.white, size: 18),
                label: const Text('Browse Listings',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      itemCount: favs.length,
      itemBuilder: (ctx, i) {
        final product = favs[i];
        return ProductCard(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SETTINGS TAB
// ══════════════════════════════════════════════════════════════════════════════
class _SettingsTab extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;
  final Map<String, String> t;
  final VoidCallback onLanguageChanged;

  const _SettingsTab({
    required this.user,
    required this.onLogout,
    required this.t,
    required this.onLanguageChanged,
  });

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _pushNotifications = true;
  bool _priceAlerts = true;
  bool _messageAlerts = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _priceAlerts = prefs.getBool('price_alerts') ?? true;
      _messageAlerts = prefs.getBool('message_alerts') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Map<String, String> get t => widget.t;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // ACCOUNT
        _SettingsSection(title: t['account_section'] ?? 'ACCOUNT', items: [
          _SettingsTile(
            icon: Icons.person_outline,
            label: t['edit_profile'] ?? 'Edit Profile',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _EditProfileSheet(
                  user: widget.user, t: t, onSave: (_) {}),
            ),
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            label: 'My Orders',
            subtitle: 'Track your purchases & sales',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: t['change_password'] ?? 'Change Password',
            onTap: () => _showChangePasswordDialog(),
          ),
          _SettingsTile(
            icon: Icons.phone_outlined,
            label: t['verify_phone'] ?? 'Verify Phone Number',
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.orange.withValues(alpha: 0.4)),
              ),
              child: Text(t['unverified'] ?? 'Unverified',
                  style: const TextStyle(
                      color: AppColors.orange, fontSize: 11)),
            ),
            onTap: () => _showVerifyPhoneDialog(),
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            label: t['email'] ?? 'Email',
            subtitle: widget.user.email,
            onTap: () {},
          ),
        ]),

        // NOTIFICATIONS
        _SettingsSection(
            title: t['notifications_section'] ?? 'NOTIFICATIONS',
            items: [
              _SettingsToggle(
                icon: Icons.notifications_outlined,
                label: t['push_notifications'] ?? 'Push Notifications',
                value: _pushNotifications,
                onChanged: (v) {
                  setState(() => _pushNotifications = v);
                  _saveSetting('push_notifications', v);
                },
              ),
              _SettingsToggle(
                icon: Icons.trending_down,
                label: t['price_alerts'] ?? 'Price Drop Alerts',
                value: _priceAlerts,
                onChanged: (v) {
                  setState(() => _priceAlerts = v);
                  _saveSetting('price_alerts', v);
                },
              ),
              _SettingsToggle(
                icon: Icons.message_outlined,
                label: t['message_alerts'] ?? 'Message Alerts',
                value: _messageAlerts,
                onChanged: (v) {
                  setState(() => _messageAlerts = v);
                  _saveSetting('message_alerts', v);
                },
              ),
              _SettingsToggle(
                icon: Icons.email_outlined,
                label: t['email_notifications'] ?? 'Email Notifications',
                value: _emailNotifications,
                onChanged: (v) {
                  setState(() => _emailNotifications = v);
                  _saveSetting('email_notifications', v);
                },
              ),
            ]),

        // PREFERENCES
        _SettingsSection(
            title: t['preferences'] ?? 'PREFERENCES',
            items: [
              _SettingsTile(
                icon: Icons.language,
                label: t['language'] ?? 'Language',
                subtitle: context.watch<LanguageProvider>().isArabic ? 'العربية' : 'English',
                onTap: () {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20))),
                    builder: (_) => _LanguagePickerSheet(
                        onChanged: widget.onLanguageChanged),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.location_on_outlined,
                label: t['default_location'] ?? 'Default Location',
                subtitle: 'Lahore, Pakistan',
                onTap: () => _showLocationPicker(),
              ),
              _SettingsTile(
                icon: Icons.currency_exchange,
                label: t['currency'] ?? 'Currency',
                subtitle: context.watch<CurrencyProvider>().selectedCurrency == 'Rs.' 
                    ? 'Pakistani Rupee (Rs.)' 
                    : 'US Dollar (\$)',
                onTap: () => _showCurrencyPicker(),
              ),
            ]),

        // PRIVACY & LEGAL
        _SettingsSection(
            title: t['privacy_legal'] ?? 'PRIVACY & LEGAL',
            items: [
              _SettingsTile(
                icon: Icons.shield_outlined,
                label: t['privacy_settings'] ?? 'Privacy Settings',
                onTap: () => _showPrivacySettings(),
              ),
              _SettingsTile(
                icon: Icons.policy_outlined,
                label: t['privacy_policy'] ?? 'Privacy Policy',
                onTap: () => _showInfoDialog(
                    t['privacy_policy'] ?? 'Privacy Policy',
                    context.read<CMSProvider>().privacyContent.isNotEmpty 
                      ? context.read<CMSProvider>().privacyContent 
                      : (t['privacy_content'] ?? '')),
              ),
              _SettingsTile(
                icon: Icons.gavel_outlined,
                label: t['terms'] ?? 'Terms of Service',
                onTap: () => _showInfoDialog(
                    t['terms'] ?? 'Terms of Service',
                    context.read<CMSProvider>().termsContent.isNotEmpty 
                      ? context.read<CMSProvider>().termsContent 
                      : (t['terms_content'] ?? '')),
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                label: t['help_support'] ?? 'Help & Support',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
                },
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                label: t['app_version'] ?? 'App Version',
                subtitle: '1.0.0',
                showArrow: false,
                onTap: () {},
              ),
            ]),

        // ADMIN
        if (widget.user.isAdmin)
          _SettingsSection(
              title: 'ADMIN',
              items: [
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admin Control Panel',
                  subtitle: 'Manage Products, Members, Finance & Reports',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDashboard()),
                  ),
                ),
              ]),

        // ACCOUNT ACTIONS
        _SettingsSection(
            title: t['account_actions'] ?? 'ACCOUNT ACTIONS',
            items: [
              _SettingsTile(
                icon: Icons.logout,
                label: t['logout'] ?? 'Logout',
                color: AppColors.orange,
                onTap: widget.onLogout,
                showArrow: false,
              ),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                label: t['delete_account'] ?? 'Delete Account',
                color: Colors.red,
                onTap: () => _showDeleteAccountDialog(),
                showArrow: false,
              ),
            ]),
      ],
    );
  }

  // ── Dialogs / Sheets ───────────────────────────────────────────────────────

  void _showChangePasswordDialog() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(t['change_password'] ?? 'Change Password',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _SimpleField(
              ctrl: oldCtrl,
              hint: context.read<LanguageProvider>().isArabic
                  ? 'كلمة المرور الحالية'
                  : 'Current password',
              obscure: true),
          const SizedBox(height: 10),
          _SimpleField(
              ctrl: newCtrl,
              hint: context.read<LanguageProvider>().isArabic
                  ? 'كلمة المرور الجديدة'
                  : 'New password',
              obscure: true),
          const SizedBox(height: 10),
          _SimpleField(
              ctrl: confCtrl,
              hint: context.read<LanguageProvider>().isArabic
                  ? 'تأكيد كلمة المرور'
                  : 'Confirm new password',
              obscure: true),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t['cancel'] ?? 'Cancel',
                  style:
                  TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode))),
          ElevatedButton(
            onPressed: () {
              if (newCtrl.text != confCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(context.read<LanguageProvider>().isArabic
                        ? 'كلمات المرور غير متطابقة'
                        : 'Passwords do not match'),
                    backgroundColor: AppColors.orange));
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(context.read<LanguageProvider>().isArabic
                      ? 'تم تغيير كلمة المرور ✅'
                      : 'Password changed successfully! ✅'),
                  backgroundColor: AppColors.green));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold),
            child: Text(t['update'] ?? 'Update',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showVerifyPhoneDialog() {
    final otpCtrl = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(t['verify_phone'] ?? 'Verify Phone Number',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              context.read<LanguageProvider>().isArabic
                  ? 'سنرسل رمزًا إلى ${widget.user.phone.isNotEmpty ? widget.user.phone : "+92 XXX XXXXXXX"}'
                  : 'We\'ll send a code to ${widget.user.phone.isNotEmpty ? widget.user.phone : "+92 XXX XXXXXXX"}',
              style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color, fontSize: 20, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, letterSpacing: 8),
              filled: true,
              fillColor: theme.cardTheme.color,
              counterText: '',
              border: const OutlineInputBorder(
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t['cancel'] ?? 'Cancel',
                  style:
                  TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(context.read<LanguageProvider>().isArabic
                      ? 'تم التحقق من الهاتف ✅'
                      : 'Phone verified successfully! ✅'),
                  backgroundColor: AppColors.green));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold),
            child: Text(t['verify'] ?? 'Verify',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() {
    final locations = context.read<LanguageProvider>().isArabic
        ? ['لاهور', 'كاراتشي', 'إسلام أباد', 'فيصل أباد', 'روالبندي', 'مولتان']
        : ['Lahore', 'Karachi', 'Islamabad', 'Faisalabad', 'Rawalpindi', 'Multan'];
    String selected = locations.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t['default_location'] ?? 'Default Location',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...locations.map((loc) => ListTile(
              leading: Icon(Icons.location_on_outlined,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
              title: Text(loc,
                  style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLightMode)),
              trailing: selected == loc
                  ? const Icon(Icons.check_circle,
                  color: AppColors.gold)
                  : null,
              onTap: () {
                setModal(() => selected = loc);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Default location: $loc'),
                    backgroundColor: AppColors.gold));
              },
            )),
          ]),
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    final currencyProvider = context.read<CurrencyProvider>();
    final currencies = [
      {'name': 'Pakistani Rupee (Rs.)', 'symbol': 'Rs.'},
      {'name': 'US Dollar (\$)', 'symbol': '\$'},
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t['currency'] ?? 'Currency',
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...currencies.map((c) => ListTile(
            title: Text(c['name']!,
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLightMode, fontSize: 14)),
            trailing: c['symbol'] == currencyProvider.selectedCurrency
                ? const Icon(Icons.check_circle,
                color: AppColors.gold)
                : null,
            onTap: () {
              currencyProvider.setCurrency(c['symbol']!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Currency changed to: ${c['name']}'),
                  backgroundColor: AppColors.gold));
            },
          )),
        ]),
      ),
    );
  }

  void _showPrivacySettings() {
    bool showPhone = true;
    bool showEmail = false;
    bool allowMessages = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t['privacy_settings'] ?? 'Privacy Settings',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _PrivacyToggle(
                context.read<LanguageProvider>().isArabic
                    ? 'إظهار رقم الهاتف في الإعلانات'
                    : 'Show phone number on listings',
                showPhone,
                    (v) => setModal(() => showPhone = v)),
            _PrivacyToggle(
                context.read<LanguageProvider>().isArabic
                    ? 'إظهار البريد الإلكتروني في الملف'
                    : 'Show email on profile',
                showEmail,
                    (v) => setModal(() => showEmail = v)),
            _PrivacyToggle(
                context.read<LanguageProvider>().isArabic
                    ? 'السماح بالرسائل المباشرة'
                    : 'Allow direct messages',
                allowMessages,
                    (v) => setModal(() => allowMessages = v)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.read<LanguageProvider>().isArabic
                          ? 'تم حفظ إعدادات الخصوصية ✅'
                          : 'Privacy settings saved ✅'),
                      backgroundColor: AppColors.green));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold),
                child: Text(t['save'] ?? 'Save',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Text(content,
              style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode,
                  fontSize: 13,
                  height: 1.6)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold),
            child: Text(t['close'] ?? 'Close',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(t['delete_account'] ?? 'Delete Account',
            style: const TextStyle(color: Colors.red)),
        content: Text(
          context.read<LanguageProvider>().isArabic
              ? 'هذا الإجراء لا يمكن التراجع عنه. سيتم حذف جميع بياناتك وإعلاناتك ورسائلك نهائيًا.'
              : 'This action is irreversible. All your data, ads and messages will be permanently deleted.',
          style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t['cancel'] ?? 'Cancel',
                style:
                TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: Text(t['delete'] ?? 'Delete',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  LANGUAGE PICKER SHEET  (shared by guest + settings)
// ══════════════════════════════════════════════════════════════════════════════
class _LanguagePickerSheet extends StatefulWidget {
  final VoidCallback onChanged;
  const _LanguagePickerSheet({required this.onChanged});

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<LanguageProvider>().languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: isDark ? AppColors.divider : AppColors.dividerLightMode,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Select Language / اختر اللغة',
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          // English option
          _LangOption(
            flagEmoji: '🇬🇧',
            name: 'English',
            nativeName: 'English',
            code: 'en',
            isSelected: _selected == 'en',
            onTap: () {
              setState(() => _selected = 'en');
              context.read<LanguageProvider>().setLanguage('en');
              Navigator.pop(context);
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
          // Arabic option
          _LangOption(
            flagEmoji: '🇸🇦',
            name: 'Arabic',
            nativeName: 'العربية',
            code: 'ar',
            isSelected: _selected == 'ar',
            onTap: () {
              setState(() => _selected = 'ar');
              context.read<LanguageProvider>().setLanguage('ar');
              Navigator.pop(context);
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
          // Urdu option
          _LangOption(
            flagEmoji: '🇵🇰',
            name: 'Urdu',
            nativeName: 'اردو',
            code: 'ur',
            isSelected: _selected == 'ur',
            onTap: () {
              setState(() => _selected = 'ur');
              context.read<LanguageProvider>().setLanguage('ur');
              Navigator.pop(context);
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
          Text(
            _selected == 'ar'
                ? 'سيتم تطبيق اللغة العربية على التطبيق بالكامل'
                : _selected == 'ur'
                    ? 'پوری ایپ پر اردو زبان لاگو ہوگی'
                    : 'Language will apply across the entire app',
            style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flagEmoji;
  final String name;
  final String nativeName;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flagEmoji,
    required this.name,
    required this.nativeName,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.15)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nativeName,
                      style: TextStyle(
                        color: isSelected ? AppColors.gold : (isDark ? Colors.white : AppColors.textPrimaryLightMode),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(name,
                      style: TextStyle(
                          color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.gold, size: 22),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HELP SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _HelpSheet extends StatelessWidget {
  final Map<String, String> t;
  const _HelpSheet({required this.t});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final faqs = [
      {'q': t['help_q1'] ?? '', 'a': t['help_a1'] ?? ''},
      {'q': t['help_q2'] ?? '', 'a': t['help_a2'] ?? ''},
      {'q': t['help_q3'] ?? '', 'a': t['help_a3'] ?? ''},
      {'q': t['help_q4'] ?? '', 'a': t['help_a4'] ?? ''},
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (_, ctrl) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: isDark ? AppColors.divider : AppColors.dividerLightMode,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(t['help_support'] ?? 'Help & Support',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                ...faqs.map((faq) => ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(faq['q']!,
                      style: TextStyle(
                          color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  iconColor: AppColors.gold,
                  collapsedIconColor: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(faq['a']!,
                          style: TextStyle(
                              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode,
                              fontSize: 13,
                              height: 1.5)),
                    ),
                  ],
                )),
                Divider(color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                const SizedBox(height: 8),
                Text('Still need help?',
                    style: TextStyle(
                        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLightMode,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Live chat opening...'),
                            backgroundColor: AppColors.green));
                      },
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10))),
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: AppColors.gold, size: 16),
                      label: const Text('Live Chat',
                          style:
                          TextStyle(color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: const Text(
                                    'Email: support@pakistansale.com'),
                                backgroundColor:
                                isDark ? AppColors.primaryDark : AppColors.primary));
                      },
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: isDark ? AppColors.divider : AppColors.dividerLightMode),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(10))),
                      icon: Icon(Icons.email_outlined,
                          color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 16),
                      label: Text('Email Us',
                          style: TextStyle(
                              color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CV UPLOAD SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _CvUploadSheet extends StatefulWidget {
  final Map<String, String> t;
  const _CvUploadSheet({required this.t});

  @override
  State<_CvUploadSheet> createState() => _CvUploadSheetState();
}

class _CvUploadSheetState extends State<_CvUploadSheet> {
  bool _uploaded = false;
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: isDark ? AppColors.divider : AppColors.dividerLightMode,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(widget.t['cv_title'] ?? 'Upload Your CV',
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(widget.t['cv_body'] ?? '',
              style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode,
                  fontSize: 13,
                  height: 1.5)),
          const SizedBox(height: 24),
          if (_uploaded)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.check_circle, color: AppColors.green),
                SizedBox(width: 12),
                Text('CV uploaded successfully!',
                    style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w600)),
              ]),
            )
          else
            GestureDetector(
              onTap: () async {
                setState(() => _uploading = true);
                await Future.delayed(const Duration(milliseconds: 1200));
                setState(() {
                  _uploading = false;
                  _uploaded = true;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      style: BorderStyle.solid),
                ),
                child: _uploading
                    ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.gold))
                    : Column(children: [
                  const Icon(Icons.upload_file,
                      color: AppColors.gold, size: 40),
                  const SizedBox(height: 10),
                  const Text('Tap to select your CV',
                      style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('PDF or DOCX, max 5 MB',
                      style: TextStyle(
                          color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                          fontSize: 12)),
                ]),
              ),
            ),
          const SizedBox(height: 16),
          if (_uploaded)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold),
                child: const Text('Done',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  AUTH SHEET (Login / Register)
// ══════════════════════════════════════════════════════════════════════════════
class _AuthSheet extends StatefulWidget {
  final bool isRegister;

  const _AuthSheet({this.isRegister = false});

  @override
  State<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<_AuthSheet> {
  late bool _isRegister;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.isRegister;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final auth = context.read<AuthProvider>();
    final lang = context.read<LanguageProvider>();
    
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang.isArabic ? 'يرجى ملء جميع الحقول' : 'Please fill in all fields'),
          backgroundColor: AppColors.orange));
      return;
    }

    try {
      if (_isRegister) {
        if (_nameCtrl.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(lang.isArabic ? 'يرجى إدخال الاسم' : 'Please enter your name'),
              backgroundColor: AppColors.orange));
          return;
        }
        await auth.signUp(
          _emailCtrl.text.trim(),
          _passwordCtrl.text.trim(),
          _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
      } else {
        await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isRegister
              ? (lang.isArabic ? 'تم إنشاء الحساب بنجاح!' : 'Account created! Welcome!')
              : (lang.isArabic ? 'أهلاً بك مجددًا!' : 'Welcome back!')),
          backgroundColor: AppColors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : Colors.white,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? AppColors.divider : AppColors.dividerLightMode,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRegister ? 'Create Account' : 'Welcome Back',
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _isRegister
                  ? 'Join thousands of buyers & sellers in Pakistan'
                  : 'Login to your Pak Sale account',
              style: TextStyle(
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13),
            ),
            const SizedBox(height: 24),
            if (_isRegister) ...[
              _AuthField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  controller: _nameCtrl,
                  icon: Icons.person_outline),
              const SizedBox(height: 12),
            ],
            _AuthField(
                label: 'Email Address',
                hint: 'Enter your email',
                controller: _emailCtrl,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            if (_isRegister) ...[
              _AuthField(
                  label: 'Phone Number',
                  hint: '+92 XXX XXXXXXX',
                  controller: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
            ],
            _AuthField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordCtrl,
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: GestureDetector(
                onTap: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                  size: 20,
                ),
              ),
            ),
            if (!_isRegister)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(
                      content: Text(
                          'Password reset email sent'),
                      backgroundColor: AppColors.gold)),
                  child: const Text('Forgot Password?',
                      style: TextStyle(
                          color: AppColors.gold, fontSize: 13)),
                ),
              )
            else
              const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                    : Text(
                  _isRegister ? 'Create Account' : 'Login',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isRegister
                      ? 'Already have an account? '
                      : "Don't have an account? ",
                  style: TextStyle(
                      color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _isRegister = !_isRegister),
                  child: Text(
                    _isRegister ? 'Login' : 'Register',
                    style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  EDIT PROFILE SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _EditProfileSheet extends StatefulWidget {
  final UserModel user;
  final Map<String, String> t;
  final Function(UserModel) onSave;

  const _EditProfileSheet(
      {required this.user, required this.t, required this.onSave});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _emailCtrl = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = widget.t;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : Colors.white,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? AppColors.divider : AppColors.dividerLightMode,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(t['edit_profile'] ?? 'Edit Profile',
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.cardTheme.color,
                      border: Border.all(
                          color: AppColors.gold, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _AuthField(
                label: 'Full Name',
                hint: 'Your name',
                controller: _nameCtrl,
                icon: Icons.person_outline),
            const SizedBox(height: 12),
            _AuthField(
                label: 'Email',
                hint: 'your@email.com',
                controller: _emailCtrl,
                icon: Icons.email_outlined),
            const SizedBox(height: 12),
            _AuthField(
                label: 'Phone',
                hint: '+92 XXX XXXXXXX',
                controller: _phoneCtrl,
                icon: Icons.phone_outlined),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final updated = widget.user.copyWith(
                    name: _nameCtrl.text.trim().isNotEmpty
                        ? _nameCtrl.text.trim()
                        : widget.user.name,
                    email: _emailCtrl.text.trim().isNotEmpty
                        ? _emailCtrl.text.trim()
                        : widget.user.email,
                    phone: _phoneCtrl.text.trim(),
                  );
                  context.read<AuthProvider>().updateProfile(updated);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.read<LanguageProvider>().isArabic
                          ? 'تم تحديث الملف الشخصي!'
                          : 'Profile updated!'),
                      backgroundColor: AppColors.green));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(t['save'] ?? 'Save Changes',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  QUICK SETTINGS SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _QuickSettingsSheet extends StatelessWidget {
  final VoidCallback onLogout;
  final Map<String, String> t;

  const _QuickSettingsSheet(
      {required this.onLogout, required this.t});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : Colors.white,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: isDark ? AppColors.divider : AppColors.dividerLightMode,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Quick Settings',
              style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimaryLightMode,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ListTile(
            leading:
            Icon(Icons.language, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode),
            title: Text(t['language'] ?? 'Language',
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLightMode)),
            trailing: Text(
                context.watch<LanguageProvider>().isArabic ? 'العربية' : 'English',
                style: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode)),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20))),
                builder: (_) => _LanguagePickerSheet(
                    onChanged: () {}),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined,
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode),
            title: Text('Notifications',
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLightMode)),
            trailing: Icon(Icons.chevron_right,
                color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help_outline,
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode),
            title: Text(t['help_support'] ?? 'Help & Support',
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLightMode)),
            trailing: Icon(Icons.chevron_right,
                color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: isDark ? AppColors.primaryDark : Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20))),
                builder: (_) => _HelpSheet(t: t),
              );
            },
          ),
          Divider(color: isDark ? AppColors.divider : AppColors.dividerLightMode),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.orange),
            title: Text(t['logout'] ?? 'Logout',
                style: const TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              onLogout();
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: isDark ? AppColors.textMuted : Colors.white.withValues(alpha: 0.7), fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15));
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    this.badge,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: isDark ? AppColors.divider : AppColors.dividerLightMode, width: 0.3)),
        ),
        child: Row(
          children: [
          Icon(icon, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimaryLightMode, fontSize: 14)),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            if (trailing != null) trailing!
            else
              Icon(Icons.chevron_right,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.gold : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSelected ? AppColors.gold : (isDark ? AppColors.divider : AppColors.dividerLightMode).withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode),
              fontSize: 12,
              fontWeight: isSelected
                  ? FontWeight.w600
                  : FontWeight.normal)),
    );
  }
}

class _AdActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _AdActionBtn({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? (isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode);
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: effectiveColor),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: effectiveColor,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isDark ? AppColors.surface : AppColors.backgroundLightMode,
        child: Text(title,
            style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600)),
      ),
      ...items,
    ]);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final Color? color;
  final bool showArrow;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.color,
    this.showArrow = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? (isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border(
              bottom:
              BorderSide(color: isDark ? AppColors.divider : AppColors.dividerLightMode, width: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: color ?? (isDark ? Colors.white : AppColors.textPrimaryLightMode),
                            fontSize: 14)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
                              fontSize: 12)),
                  ]),
            ),
            if (trailing != null)
              trailing!
            else if (showArrow)
              Icon(Icons.chevron_right,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
            bottom:
            BorderSide(color: isDark ? AppColors.divider : AppColors.dividerLightMode, width: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 14))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
            inactiveThumbColor: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
            inactiveTrackColor: isDark ? AppColors.card : Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
    );
  }
}

// ── Auth field widget ─────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;

  const _AuthField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLightMode, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimaryLightMode, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, fontSize: 13),
            prefixIcon:
            Icon(icon, color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.cardTheme.color,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: AppColors.gold, width: 1.5)),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ── Simple password field ─────────────────────────────────────────────────────
class _SimpleField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool obscure;
  const _SimpleField(
      {required this.ctrl, required this.hint, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode),
        filled: true,
        fillColor: theme.cardTheme.color,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// ── Privacy toggle ────────────────────────────────────────────────────────────
class _PrivacyToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrivacyToggle(this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimaryLightMode, fontSize: 14))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.gold,
          activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
          inactiveThumbColor: isDark ? AppColors.textMuted : AppColors.textSecondaryLightMode,
          inactiveTrackColor: isDark ? AppColors.card : AppColors.backgroundLightMode,
        ),
      ]),
    );
  }
}

// ── Tab bar delegate ──────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(ctx);
    final isDark = theme.brightness == Brightness.dark;
    return Container(color: isDark ? AppColors.primaryDark : AppColors.primaryLightMode, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => true;
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(!isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.gold.withValues(alpha: 0.15) : AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 14,
              color: AppColors.gold,
            ),
            const SizedBox(width: 6),
            Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
