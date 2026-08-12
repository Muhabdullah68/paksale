// web/web_shell.dart
//
// Website chrome for the web build only (kIsWeb). The mobile app never
// renders any of this — it keeps its original phone UI.
//
// WebPage  : frames any page with the sticky site header + footer.
// WebHeader: logo + wordmark, big search bar, category mega-menu, nav links,
//            notifications, theme + language toggles, account / admin links.
// WebFooter: brand, quick links, social icons, copyright.
// WebNav   : tiny singleton that lets the header switch Home tabs on the root
//            screen (the 6-tab IndexedStack in HomeScreen).
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/cms_provider.dart';
import '../services/language_provider.dart';
import '../services/theme_provider.dart';
import '../widgets/common_widgets.dart';

/// Home tab indices — mirrors HomeScreen's bottom nav order.
class WebTab {
  static const int home = 0;
  static const int categories = 1;
  static const int postAd = 2;
  static const int favorites = 3;
  static const int chat = 4;
  static const int account = 5;
}

/// Maps a [WebTab] to its go_router path. Lives next to [WebTab] so the shell
/// and the router share the mapping without a circular import.
String webTabPath(int tab) {
  switch (tab) {
    case WebTab.categories:
      return '/categories';
    case WebTab.postAd:
      return '/post-ad';
    case WebTab.favorites:
      return '/favorites';
    case WebTab.chat:
      return '/chat';
    case WebTab.account:
      return '/account';
    default:
      return '/home';
  }
}

/// Lets the header drive the root HomeScreen's tab stack on web.
class WebNav extends ChangeNotifier {
  static final WebNav instance = WebNav();
  int _tab = WebTab.home;
  int get tab => _tab;
  void setTab(int index) {
    if (_tab == index) return;
    _tab = index;
    notifyListeners();
  }
}

/// A single breadcrumb segment. [label] is shown as plain text when it is the
/// last crumb; otherwise it navigates to [onTap].
class WebCrumb {
  final String label;
  final VoidCallback? onTap;
  const WebCrumb(this.label, {this.onTap});
}

/// The single scroll controller shared by every WebPage. Lets the header
/// (and any navigation) scroll the page back to the top.
final ScrollController webPageScrollController = ScrollController();

/// Frames any page with the sticky website header + footer.
///
/// The whole page is ONE scrollable document: the sticky [WebHeader] stays
/// pinned on top while the content and footer flow naturally as a single
/// scroll region. The footer therefore sits at the END of the document, not
/// pinned to the viewport bottom.
class WebPage extends StatelessWidget {
  final Widget content;
  final List<WebCrumb> breadcrumbs;
  final bool showFooter;

  const WebPage({
    super.key,
    required this.content,
    this.breadcrumbs = const [],
    this.showFooter = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: webPageScrollController,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (breadcrumbs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: WebBreadcrumbs(crumbs: breadcrumbs),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: content,
                      ),
                      if (showFooter) const WebFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal breadcrumb trail (Home › Category › ...).
class WebBreadcrumbs extends StatelessWidget {
  final List<WebCrumb> crumbs;
  const WebBreadcrumbs({super.key, required this.crumbs});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        _Crumb(
          label: 'Home',
          icon: Icons.home_outlined,
          onTap: () => context.go('/home'),
        ),
        for (var i = 0; i < crumbs.length; i++) ...[
          const Icon(Icons.chevron_right,
              size: 14, color: AppColors.textMuted),
          _Crumb(
            label: crumbs[i].label,
            isCurrent: i == crumbs.length - 1,
            onTap: crumbs[i].onTap,
          ),
        ],
      ],
    );
  }
}

class _Crumb extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isCurrent;
  final VoidCallback? onTap;
  const _Crumb({
    required this.label,
    this.icon,
    this.isCurrent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? AppColors.gold : AppColors.textSecondary;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
        ],
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
    if (isCurrent || onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class WebHeader extends StatefulWidget {
  const WebHeader({super.key});

  @override
  State<WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<WebHeader> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _menuOpen = false;
  Timer? _menuExitTimer;

  static const double _row0Height = 30;
  static const double _row1Height = 64;
  static const double _row2Height = 44;

  void _scheduleMenuClose() {
    _menuExitTimer?.cancel();
    _menuExitTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted && _menuOpen) setState(() => _menuOpen = false);
    });
  }

  void _closeMenuNow() {
    _menuExitTimer?.cancel();
    if (mounted && _menuOpen) setState(() => _menuOpen = false);
  }

  void _openNavDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WebNavDrawer(
        onSelect: (int tab) {
          Navigator.pop(ctx);
          _goTab(tab);
        },
        onBrowse: () {
          Navigator.pop(ctx);
          _goToListing();
        },
      ),
    );
  }

  @override
  void dispose() {
    _menuExitTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  void _goTab(int tab) {
    if (_menuOpen) setState(() => _menuOpen = false);
    _scrollToTop();
    context.go(webTabPath(tab));
  }

  String _browsePath({String? category, String? subCategory, String? query}) {
    final params = <String, String>{
      if (category != null) 'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      if (query != null) 'q': query,
    };
    if (params.isEmpty) return '/browse';
    final qs = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '/browse?$qs';
  }

  void _goToListing({String? category, String? subCategory, String? query}) {
    if (_menuOpen) setState(() => _menuOpen = false);
    _scrollToTop();
    context.push(_browsePath(
      category: category,
      subCategory: subCategory,
      query: query,
    ));
  }

  void _goNotifications() {
    if (_menuOpen) setState(() => _menuOpen = false);
    context.push('/notifications');
  }

  void _goAdmin() {
    if (_menuOpen) setState(() => _menuOpen = false);
    context.push('/admin');
  }

  void _scrollToTop() {
    if (webPageScrollController.hasClients) {
      webPageScrollController.jumpTo(0);
    }
  }

  void _submitSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isNotEmpty) {
      _goToListing(query: q);
      _searchCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final lang = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final unread = context.watch<NotificationProvider>().unreadCount;

    final isAdmin = auth.userModel?.isAdmin ?? false;
    final isLoggedIn = auth.isAuthenticated;

    final navItems = <_NavItem>[
      _NavItem(
        key: 'home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: t['nav_home'] ?? 'Home',
        onTap: () => _goTab(WebTab.home),
      ),
      _NavItem(
        key: 'categories',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: t['nav_categories'] ?? 'Categories',
        onTap: () => _goTab(WebTab.categories),
      ),
      _NavItem(
        key: 'ads',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: t['all_categories'] ?? 'All Ads',
        onTap: () => _goToListing(),
      ),
      _NavItem(
        key: 'saved',
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
        label: t['nav_saved'] ?? 'Saved',
        onTap: () => _goTab(WebTab.favorites),
      ),
      _NavItem(
        key: 'chat',
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        label: t['nav_chat'] ?? 'Chat',
        onTap: () => _goTab(WebTab.chat),
      ),
      if (isAdmin)
        _NavItem(
          key: 'admin',
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          label: 'Admin',
          onTap: _goAdmin,
        ),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.primary,
          elevation: 4,
          shadowColor: Colors.black45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Row 0: utility bar (city + quick links) ────────────────
              Container(
                height: _row0Height,
                color: isDark ? AppColors.primaryDark : const Color(0xFF4A0A1E),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          return Row(
                            children: [
                              // Left: City selector
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.location_on_outlined,
                                          color: AppColors.gold, size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        'Sargodha, Pakistan',
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(Icons.arrow_drop_down,
                                          color: Colors.white54, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Center: Quick links (only on wider screens)
                              if (w >= 720) ...[
                                _UtilityLink(
                                    label: t['help_support'] ?? 'Help & Support',
                                    onTap: () => context.push('/help')),
                                const SizedBox(width: 18),
                                _UtilityLink(
                                    label:
                                        t['safe_meeting'] ?? 'Safe Meeting',
                                    onTap: () =>
                                        context.push('/safe-meeting')),
                                const SizedBox(width: 18),
                                _UtilityLink(
                                    label: t['female_support'] ??
                                        'Female Support',
                                    onTap: () =>
                                        context.push('/female-support')),
                                const Spacer(),
                              ],
                              // Right: Become seller / trust badge
                              if (w >= 620)
                                _UtilityLink(
                                    label: '⭐ Become a Verified Seller',
                                    onTap: () => _goTab(WebTab.postAd),
                                    color: AppColors.gold),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // ── Row 1: brand + search + actions ─────────────────────────
              SizedBox(
                height: _row1Height,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final w = c.maxWidth;
                          return Row(
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _goTab(WebTab.home),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AppLogoIcon(size: 36),
                                      if (w >= 1000) ...[
                                        const SizedBox(width: 10),
                                        const AppLogo(fontSize: 24),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 42,
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onSubmitted: (_) => _submitSearch(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText:
                                          '${t['search_hint'] ?? 'Search in Pak Sale...'}',
                                      hintStyle: const TextStyle(
                                          color: Colors.white60, fontSize: 14),
                                      prefixIcon: const Icon(Icons.search,
                                          color: Colors.white70, size: 20),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.tune,
                                            color: Colors.white70, size: 20),
                                        tooltip: 'Search & Filter',
                                        onPressed: _submitSearch,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.12),
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: AppColors.gold
                                                .withValues(alpha: 0.35)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: AppColors.gold, width: 1.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Sell button
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _goTab(WebTab.postAd),
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 6),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_circle_outline,
                                            color: Colors.white, size: 18),
                                        SizedBox(width: 6),
                                        Text('Sell',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (w >= 820) ...[
                                // Theme toggle
                                _HeaderIconButton(
                                  icon: isDark
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                  tooltip: isDark ? 'Light mode' : 'Dark mode',
                                  onTap: () =>
                                      themeProvider.toggleTheme(!isDark),
                                ),
                                // Language toggle
                                _HeaderIconButton(
                                  icon: Icons.language,
                                  tooltip: 'Language',
                                  onTap: () {
                                    final next = lang.languageCode == 'en'
                                        ? 'ur'
                                        : 'en';
                                    lang.setLanguage(next);
                                  },
                                ),
                              ],
                              if (w >= 700)
                                _HeaderIconButton(
                                  icon: Icons.notifications_none,
                                  badge: unread,
                                  tooltip: 'Notifications',
                                  onTap: _goNotifications,
                                ),
                              const SizedBox(width: 6),
                              // Account / sign-in
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _goTab(WebTab.account),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.person_outline,
                                            color: Colors.white, size: 18),
                                        if (w >= 640) ...[
                                          const SizedBox(width: 6),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxWidth: 120),
                                            child: Text(
                                              isLoggedIn
                                                  ? (auth.userModel?.name ??
                                                      'Account')
                                                  : 'Sign In',
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // ── Row 2: nav links + category mega menu trigger ───────────
              Container(
                color: isDark ? AppColors.primaryDark : const Color(0xFF5A0A22),
                height: _row2Height,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        // Hide less-important links on narrow windows so the
                        // row never overflows horizontally.
                        final visibleKeys = <String>{
                          'home',
                          if (w >= 640) 'ads',
                          if (w >= 800) 'saved',
                          if (w >= 800) 'chat',
                          if (w >= 800) 'admin',
                        };
                        final links = navItems
                            .where((n) => n.key != 'categories')
                            .where((n) => visibleKeys.contains(n.key))
                            .toList();
                        return Row(
                          children: [
                            if (w < 820)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    _closeMenuNow();
                                    _openNavDrawer();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 10),
                                    child: Icon(Icons.menu,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            // Categories mega menu trigger
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) {
                                _menuExitTimer?.cancel();
                                setState(() => _menuOpen = true);
                              },
                              onExit: (_) => _scheduleMenuClose(),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _menuOpen = !_menuOpen),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _menuOpen
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.grid_view,
                                          color: AppColors.gold, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                          t['nav_categories'] ?? 'Categories',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down,
                                          color: Colors.white70, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Other nav links
                            ...links.map((n) => _NavLink(
                                  item: n,
                                  onTap: n.onTap,
                                )),
                            const Spacer(),
                            const SizedBox(width: 8),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Mega menu dropdown (overlays content) ──────────────────────────
        if (_menuOpen)
          Positioned(
            top: _row0Height + _row1Height + _row2Height - 2,
            left: 0,
            right: 0,
            child: _CategoryMegaMenu(
              onClose: _scheduleMenuClose,
              onSelect: (name) {
                _menuExitTimer?.cancel();
                _goToListing(category: name);
              },
            ),
          ),
      ],
    );
  }
}

class _NavItem {
  final String key;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  const _NavItem({
    required this.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });
}

class _NavLink extends StatelessWidget {
  final _NavItem item;
  final VoidCallback onTap;
  const _NavLink({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Text(item.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebNavDrawer extends StatelessWidget {
  final ValueChanged<int> onSelect;
  final VoidCallback onBrowse;
  const _WebNavDrawer({required this.onSelect, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final navItems = <(IconData, String, VoidCallback)>[
      (Icons.home_outlined, t['nav_home'] ?? 'Home',
          () => onSelect(WebTab.home)),
      (Icons.grid_view_outlined, t['nav_categories'] ?? 'Categories',
          () => onSelect(WebTab.categories)),
      (Icons.storefront_outlined, t['all_categories'] ?? 'All Ads', onBrowse),
      (Icons.add_circle_outline, t['nav_post_ad'] ?? 'Post an Ad',
          () => onSelect(WebTab.postAd)),
      (Icons.favorite_outline, t['nav_saved'] ?? 'Saved',
          () => onSelect(WebTab.favorites)),
      (Icons.chat_bubble_outline, t['nav_chat'] ?? 'Chat',
          () => onSelect(WebTab.chat)),
      (Icons.person_outline, t['nav_account'] ?? 'My Account',
          () => onSelect(WebTab.account)),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.divider : AppColors.dividerLightMode,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(t['nav_menu'] ?? 'Menu',
                style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          const Divider(
              height: 1,
              color: AppColors.gold),
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              itemBuilder: (_, i) {
                final item = navItems[i];
                return ListTile(
                  leading: Icon(item.$1, color: AppColors.gold),
                  title: Text(item.$2,
                      style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  onTap: item.$3,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  final String tooltip;
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badge,
    this.tooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (badge != null && badge! > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                        color: AppColors.gold, shape: BoxShape.circle),
                    child: Text('$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UtilityLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _UtilityLink({
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY MEGA MENU
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryMegaMenu extends StatelessWidget {
  final VoidCallback onClose;
  final ValueChanged<String> onSelect;
  const _CategoryMegaMenu({required this.onClose, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cms = context.watch<CMSProvider>();

    final List<Map<String, dynamic>> cats = cms.categories.isNotEmpty
        ? cms.categories
        : [
            {'name': 'Vehicles', 'icon': '🚗'},
            {'name': 'Properties', 'icon': '🏠'},
            {'name': 'Electronics', 'icon': '⚡'},
            {'name': 'Furniture & Décor', 'icon': '🪑'},
            {'name': 'WaterCrafts', 'icon': '⛵'},
            {'name': 'Jewellery', 'icon': '💎'},
            {'name': 'Lifestyle', 'icon': '🛍️'},
            {'name': 'Market', 'icon': '🛒'},
            {'name': 'Outdoor & Leisure', 'icon': '⛺'},
            {'name': 'Special Numbers', 'icon': '🔢'},
            {'name': 'Heavy Equipments', 'icon': '🏗️'},
            {'name': 'Jobs Center', 'icon': '💼'},
            {'name': 'Super Ads', 'icon': '⭐'},
          ];

    return MouseRegion(
      onExit: (_) => onClose(),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 12,
        shadowColor: Colors.black45,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Browse Categories',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.textTheme.titleLarge?.color)),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = (c.maxWidth / 190).floor().clamp(2, 7);
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3.6,
                        children: cats.map((cat) {
                          final name = cat['name']?.toString() ?? '';
                          final icon = cat['icon']?.toString() ?? '🏷️';
                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => onSelect(name),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.gold
                                          .withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  children: [
                                    Text(icon,
                                        style:
                                            const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12.5,
                                              color: theme
                                                  .textTheme.bodyLarge
                                                  ?.color)),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        size: 14, color: AppColors.gold),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  void _goTab(BuildContext context, int tab) {
    if (webPageScrollController.hasClients) {
      webPageScrollController.jumpTo(0);
    }
    context.go(webTabPath(tab));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.primaryDark : const Color(0xFF2A020E),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final wide = c.maxWidth > 760;
                  final brand = _FooterBlock(
                    title: '',
                    children: [
                      const Row(
                        children: [
                          AppLogoIcon(size: 40),
                          SizedBox(width: 10),
                          AppLogo(fontSize: 22),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pak Sale is your local marketplace to buy and sell '
                        'cars, properties, electronics, jobs and more.',
                        style: TextStyle(
                            color: isDark
                                ? AppColors.textMuted
                                : Colors.white70,
                            fontSize: 13,
                            height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      const SocialMediaFooter(),
                    ],
                  );

                  final marketplace = _FooterBlock(
                    title: 'Marketplace',
                    children: [
                      _FooterLink(
                          'Home', () => _goTab(context, WebTab.home)),
                      _FooterLink(
                          'All Ads', () => context.push('/browse')),
                      _FooterLink(
                          'Categories', () => _goTab(context, WebTab.categories)),
                      _FooterLink(
                          'Post an Ad', () => _goTab(context, WebTab.postAd)),
                    ],
                  );

                  final myAccount = _FooterBlock(
                    title: 'My Account',
                    children: [
                      _FooterLink(
                          'My Ads', () => _goTab(context, WebTab.account)),
                      _FooterLink(
                          'Saved', () => _goTab(context, WebTab.favorites)),
                      _FooterLink('Chat', () => _goTab(context, WebTab.chat)),
                      _FooterLink(
                          'Notifications', () => context.push('/notifications')),
                    ],
                  );

                  final support = _FooterBlock(
                    title: 'Support',
                    children: [
                      _FooterLink(
                          'Help & Support', () => context.push('/help')),
                      _FooterLink(
                          'Safe Meeting', () => context.push('/safe-meeting')),
                      _FooterLink(
                          'Female Support', () => context.push('/female-support')),
                      _FooterLink(
                          'Admin Panel', () => context.push('/admin')),
                    ],
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: brand),
                        const SizedBox(width: 40),
                        Expanded(flex: 2, child: marketplace),
                        Expanded(flex: 2, child: myAccount),
                        Expanded(flex: 2, child: support),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      brand,
                      const SizedBox(height: 28),
                      marketplace,
                      const SizedBox(height: 24),
                      myAccount,
                      const SizedBox(height: 24),
                      support,
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              Divider(
                  color: Colors.white.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '© 2026 Pak Sale. All rights reserved.',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterBlock extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _FooterBlock({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title,
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
        ],
        ...children,
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
      ),
    );
  }
}

class SocialMediaFooter extends StatelessWidget {
  const SocialMediaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (FontAwesomeIcons.tiktok, 'TikTok'),
      (FontAwesomeIcons.instagram, 'Instagram'),
      (FontAwesomeIcons.snapchat, 'Snapchat'),
      (FontAwesomeIcons.youtube, 'YouTube'),
      (FontAwesomeIcons.xTwitter, 'X'),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (icon, _) in items)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.5),
                        width: 1.2),
                  ),
                  child: FaIcon(icon, size: 15, color: AppColors.gold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
