// web/app_router.dart
//
// go_router configuration for the web build only. Gives every page a real
// URL so browser back/forward and deep links work:
//
//   /home             home tab        (shell)
//   /categories       categories tab  (shell)
//   /post-ad          post ad tab     (shell)
//   /favorites        favorites tab   (shell)
//   /chat             chat tab        (shell)
//   /account          account tab     (shell)
//   /browse           listing page    (pushed, query: category/subCategory/q)
//   /listing/:id      product detail  (pushed, deep-linkable)
//   /notifications    notifications   (pushed)
//   /admin            admin panel     (pushed)
//   /help             help & support  (pushed)
//   /safe-meeting     safe meeting    (pushed)
//   /female-support   female support  (pushed)
//
// The mobile app never uses this file — it keeps its classic Navigator flow.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/compare_provider.dart';
import '../providers/product_provider.dart';
import '../screens/account_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/categories_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/compare_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/female_support_screen.dart';
import '../screens/help_screen.dart';
import '../screens/listing_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/post_ad_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/safe_meeting_screen.dart';
import '../theme/app_theme.dart';
import 'web_home.dart';
import 'web_shell.dart';

/// Resolves a `/listing/:id` deep link to a [ProductModel], then shows the
/// [ProductDetailScreen]. Looks in already-loaded lists first and falls back
/// to a direct fetch so the URL works even on a fresh page load.
class ProductDetailResolver extends StatefulWidget {
  final String id;
  const ProductDetailResolver({super.key, required this.id});

  @override
  State<ProductDetailResolver> createState() => _ProductDetailResolverState();
}

class _ProductDetailResolverState extends State<ProductDetailResolver> {
  ProductModel? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final provider = context.read<ProductProvider>();
    ProductModel? found;
    for (final p in [
      ...provider.products,
      ...provider.featuredProducts,
      ...provider.userProducts,
    ]) {
      if (p.id == widget.id) {
        found = p;
        break;
      }
    }
    found ??= await provider.fetchProductById(widget.id);
    if (!mounted) return;
    setState(() {
      _product = found;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }
    final p = _product;
    if (p == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off,
                  size: 64, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('Listing not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                ),
                child: const Text('Back to Home',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    return ProductDetailScreen(product: p);
  }
}

/// The single web router. On mobile this is never installed.
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) => '/home',
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          WebPage(content: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => WebHomeBody(
                onProductTap: (p) => context.push('/listing/${p.id}'),
                onCategoryTap: (c) => context.push(
                    '/browse?category=${Uri.encodeQueryComponent(c)}'),
                onSeeAllAds: () => context.push('/browse'),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/categories',
              builder: (_, __) => const CategoriesScreen(webEmbedded: true),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/post-ad',
              builder: (_, __) => const PostAdScreen(webEmbedded: true),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/favorites',
              builder: (_, __) => const FavoritesScreen(webEmbedded: true),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (_, __) => const ChatScreen(webEmbedded: true),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              builder: (_, __) => const AccountScreen(webEmbedded: true),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/browse',
      builder: (context, state) {
        final q = state.uri.queryParameters;
        return ListingScreen(
          categoryTitle: q['category'],
          subCategoryTitle: q['subCategory'],
          initialQuery: q['q'],
        );
      },
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (context, state) =>
          ProductDetailResolver(id: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/compare',
      builder: (context, state) => CompareScreen(
        selectedProducts:
            context.read<CompareProvider>().compareList.toList(),
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (_, __) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/help',
      builder: (_, __) => const HelpScreen(),
    ),
    GoRoute(
      path: '/safe-meeting',
      builder: (_, __) => const SafeMeetingScreen(),
    ),
    GoRoute(
      path: '/female-support',
      builder: (_, __) => const FemaleSupportScreen(),
    ),
  ],
);
