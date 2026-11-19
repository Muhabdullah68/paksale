import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/compare_provider.dart';
import '../repositories/user_repository.dart';
import '../services/language_provider.dart';
import '../services/currency_provider.dart';
import '../services/share_service.dart';
import '../services/web_clipboard.dart'
    if (dart.library.html) '../services/web_clipboard_web.dart'
    as browser_clipboard;
import '../screens/account_screen.dart';
import '../screens/chat_screen.dart';

/// Converts common local/international phone formats into a dialable URI
/// value. Unknown formats are kept as-is so `tel:` can still try them.
String normalizePhoneNumber(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';

  final hasPlus = value.startsWith('+');
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';

  var normalized = digits;
  if (normalized.startsWith('00')) {
    normalized = normalized.substring(2);
  } else if (!hasPlus && normalized.startsWith('0') && normalized.length > 10) {
    normalized = normalized.substring(1);
  }

  if (hasPlus || value.startsWith('00')) return '+$normalized';
  if (normalized.length == 10 && normalized.startsWith('3')) {
    return '+92$normalized';
  }
  if (normalized.length == 11 && normalized.startsWith('92')) {
    return '+$normalized';
  }
  return normalized;
}

void _showActionMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.orange),
  );
}

/// Call-privacy policy: only an explicit `false` blocks calls. A missing or
/// unknown value means the seller never chose, so legacy listings stay usable.
bool allowCallsFromFlag(bool? explicitFlag) => explicitFlag ?? true;

/// Missing privacy documents and unknown values are treated as "allow" so
/// legacy sellers are not accidentally blocked. Only an explicit false blocks.
Future<bool> _sellerAllowsCalls(ProductModel product) async {
  if (product.sellerId.isEmpty) return true;
  try {
    // Read the *raw* flag. PrivacySettings defaults `allowCalls` to false, so
    // going through UserModel would turn a missing field into "blocked" and
    // every legacy listing would claim the seller disabled calls.
    final explicit = await UserRepository().getAllowCallsFlag(product.sellerId);
    return allowCallsFromFlag(explicit);
  } catch (_) {
    return true;
  }
}

void _showCallDialog(
  BuildContext context, {
  required String sellerName,
  required String phone,
  required Uri uri,
  String? message,
}) {
  final t = context.read<LanguageProvider>().t;
  final messenger = ScaffoldMessenger.of(context);

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Call $sellerName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[Text(message), const SizedBox(height: 12)],
            const Text('Seller phone number'),
            const SizedBox(height: 4),
            SelectableText(
              phone,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t['cancel'] ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Show feedback synchronously, before any await, so a tap
              // always produces a visible message.
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Number copied to clipboard'),
                  backgroundColor: AppColors.gold,
                ),
              );
              if (kIsWeb) {
                // Flutter's clipboard channel loses the user gesture in
                // Safari; write through the browser API instead.
                final copied = await browser_clipboard.copyToClipboard(phone);
                if (!copied) {
                  await Clipboard.setData(ClipboardData(text: phone));
                }
              } else {
                await Clipboard.setData(ClipboardData(text: phone));
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Copy number'),
          ),
          FilledButton(
            onPressed: () async {
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!launched) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Could not open the dialer')),
                );
              }
            },
            child: const Text('Dial'),
          ),
        ],
      );
    },
  );
}

void _showCallDisabledDialog(BuildContext context, ProductModel product) {
  final t = context.read<LanguageProvider>().t;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(t['call'] ?? 'Call'),
        content: const Text(
          'This seller has disabled calls. Would you like to chat instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t['cancel'] ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              startProductChat(context, product);
            },
            child: Text(t['chat'] ?? 'Chat'),
          ),
        ],
      );
    },
  );
}

Future<void> callProductSeller(
  BuildContext context,
  ProductModel product,
) async {
  final rawPhone = product.sellerPhone.trim().isNotEmpty
      ? product.sellerPhone
      : product.whatsAppNumber;
  final phone = normalizePhoneNumber(rawPhone);
  if (phone.isEmpty) {
    _showActionMessage(context, 'The seller has not provided a phone number');
    return;
  }

  final allowsCalls = await _sellerAllowsCalls(product);
  if (!context.mounted) return;
  if (!allowsCalls) {
    _showCallDisabledDialog(context, product);
    return;
  }

  final sellerName = product.sellerName.trim().isEmpty
      ? 'the seller'
      : product.sellerName;
  final uri = Uri.parse('tel:$phone');

  // On desktop browsers tel: often does nothing, so always show the number
  // with explicit Copy/Dial actions. App users go straight to the dialer and
  // only see the dialog if the platform cannot launch it.
  if (kIsWeb) {
    _showCallDialog(context, sellerName: sellerName, phone: phone, uri: uri);
    return;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showCallDialog(
        context,
        sellerName: sellerName,
        phone: phone,
        uri: uri,
        message: 'Could not open the dialer. You can copy or dial manually.',
      );
    }
  } catch (_) {
    if (context.mounted) {
      _showCallDialog(
        context,
        sellerName: sellerName,
        phone: phone,
        uri: uri,
        message: 'Could not open the dialer. You can copy or dial manually.',
      );
    }
  }
}

/// Asks the user to sign in, opens the shared auth sheet, and re-runs
/// [startProductChat] on success so the conversation opens without an extra tap.
Future<void> _promptSignInForChat(
  BuildContext context,
  ProductModel product,
) async {
  final t = context.read<LanguageProvider>().t;
  final goSignIn = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(t['chat'] ?? 'Chat'),
      content: Text(
        t['login_prompt'] ?? 'Please sign in to message the seller',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(t['cancel'] ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(t['login'] ?? 'Sign in'),
        ),
      ],
    ),
  );
  if (goSignIn != true || !context.mounted) return;

  final signedIn = await showAuthSheet(context);
  if (signedIn && context.mounted) {
    // Now authenticated — create/reuse the conversation and open it.
    await startProductChat(context, product);
  }
}

Future<void> startProductChat(
  BuildContext context,
  ProductModel product,
) async {
  final auth = context.read<AuthProvider>();
  final chatProvider = context.read<ChatProvider>();

  if (!auth.isAuthenticated || auth.firebaseUser == null) {
    await _promptSignInForChat(context, product);
    return;
  }

  final currentUserId = auth.firebaseUser!.uid;
  if (currentUserId == product.sellerId) {
    _showActionMessage(
      context,
      'This is your own listing. You cannot chat with yourself.',
    );
    return;
  }

  ConversationModel? conversation = chatProvider.findConversation(
    currentUserId,
    product.sellerId,
    product.id,
  );

  if (conversation == null) {
    final newConversation = ConversationModel(
      id: '',
      participants: [currentUserId, product.sellerId],
      participantNames: {
        currentUserId: auth.userModel?.name ?? 'Buyer',
        product.sellerId: product.sellerName,
      },
      participantAvatars: {
        currentUserId: auth.userModel?.avatarUrl ?? '',
        product.sellerId: '',
      },
      lastMessage: 'Interested in ${product.title}',
      lastMessageAt: DateTime.now(),
      lastSenderId: currentUserId,
      unreadCount: {product.sellerId: 1},
      productId: product.id,
      productTitle: product.title,
      productImageUrl: product.imageUrls.isNotEmpty
          ? product.imageUrls.first
          : '',
    );

    try {
      final id = await chatProvider.startConversation(newConversation);
      if (!context.mounted) return;
      conversation = newConversation.copyWith(id: id);
    } catch (e) {
      if (!context.mounted) return;
      _showActionMessage(context, 'Error starting conversation: $e');
      return;
    }
  }

  if (!context.mounted) return;
  if (kIsWeb) {
    // go_router owns web navigation; use a real URL so back/forward and deep
    // links behave correctly.
    await context.push('/chat/${conversation.id}');
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ConversationScreen(conversation: conversation!),
    ),
  );
}

/// Toggles [product] in the compare list with user feedback.
void toggleCompareWithFeedback(
  BuildContext context,
  ProductModel product,
  CompareProvider? provider,
) {
  if (provider == null) return;
  final t = context.read<LanguageProvider>().t;
  final result = provider.toggleCompare(product);
  if (!context.mounted) return;
  final (message, color) = switch (result) {
    CompareToggleResult.added => (
      t['compare_added'] ?? '✓ Added to compare',
      AppColors.gold,
    ),
    CompareToggleResult.removed => (
      t['compare_removed'] ?? 'Removed from compare',
      AppColors.textMuted,
    ),
    CompareToggleResult.limitReached => (
      t['compare_limit'] ?? 'Compare limit reached (max 3)',
      AppColors.orange,
    ),
  };
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
}

class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const AppLogoIcon({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class AppLogo extends StatelessWidget {
  final double fontSize;
  const AppLogo({super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final appName = t['appName'] ?? 'Pak Sale';

    String part1 = appName;
    String part2 = '';

    if (appName.contains('Sale')) {
      part1 = appName.substring(0, appName.indexOf('Sale'));
      part2 = 'Sale';
    } else if (appName.contains(' ')) {
      final parts = appName.split(' ');
      part1 = parts[0];
      part2 = ' ${parts.sublist(1).join(' ')}';
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: part1,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
          TextSpan(
            text: part2,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomSearchBar extends StatelessWidget {
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final String hint;
  final bool onPrimaryBackground;

  const CustomSearchBar({
    super.key,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.controller,
    this.hint = 'Search in Pak Sale...',
    this.onPrimaryBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = (isDark || onPrimaryBackground)
        ? Colors.white
        : Colors.black87;
    final hintColor = (isDark || onPrimaryBackground)
        ? Colors.white60
        : Colors.black45;

    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 42, maxHeight: 52),
        decoration: BoxDecoration(
          color: (isDark || onPrimaryBackground)
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: (isDark || onPrimaryBackground)
                ? AppColors.gold.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: readOnly
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(Icons.search, color: hintColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint,
                        style: TextStyle(color: hintColor, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: true,
                maxLength: 80,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: hint,
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: hintColor, size: 18),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<LanguageProvider>().t;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.3 : 0.1,
            ),
            blurRadius: 16,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 22,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: t['nav_home'] ?? 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            activeIcon: const Icon(Icons.grid_view),
            label: t['nav_categories'] ?? 'Categories',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            activeIcon: const Icon(Icons.add_circle, size: 28),
            label: t['nav_post_ad'] ?? 'Post Ad',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_outline),
            activeIcon: const Icon(Icons.favorite),
            label: t['nav_saved'] ?? 'Saved',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: t['nav_account'] ?? 'Account',
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final bool isGridView;
  final VoidCallback? onShare;
  final bool showShareButton;
  final bool showCompareButton;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isGridView = false,
    this.onShare,
    this.showShareButton = true,
    this.showCompareButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return isGridView ? _buildGrid(context) : _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final currencyProvider = context.watch<CurrencyProvider>();
    final favoritesProvider = context.watch<FavoritesProvider?>();
    final compareProvider = context.watch<CompareProvider?>();
    final isFav = favoritesProvider?.isFavorite(product.id) ?? false;
    final isInCompare = compareProvider?.isInCompare(product.id) ?? false;

    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
                  .withValues(alpha: 0.2),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    child: _buildImage(context, 100, 100),
                  ),
                  if (p.isSold)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                        child: Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              t['sold'] ?? 'SOLD',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (p.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('⭐', style: TextStyle(fontSize: 9)),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.price == 0
                            ? (t['contact'] ?? 'Contact')
                            : currencyProvider.formatPrice(p.price),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            p.postedTime,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _ConditionBadge(condition: p.condition),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            size: 11,
                            color:
                                theme.textTheme.bodySmall?.color?.withValues(
                                  alpha: 0.5,
                                ) ??
                                AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${p.location}${p.city.isNotEmpty ? ', ${p.city}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    theme.textTheme.bodySmall?.color
                                        ?.withValues(alpha: 0.5) ??
                                    AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: 11,
                            color:
                                theme.textTheme.bodySmall?.color?.withValues(
                                  alpha: 0.5,
                                ) ??
                                AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${p.views}',
                            style: TextStyle(
                              color:
                                  theme.textTheme.bodySmall?.color?.withValues(
                                    alpha: 0.5,
                                  ) ??
                                  AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Right rail: heart with the action chips directly below it.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.only(right: 10, top: 10, bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (favoritesProvider == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t['sign_in_favorites'] ??
                                      'Please sign in to save favorites',
                                ),
                                backgroundColor: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primary,
                              ),
                            );
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await favoritesProvider.toggleFavorite(
                            product,
                          );
                          if (!ok) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  t['favorite_failed'] ??
                                      "Couldn't update favorite",
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.redAccent : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        direction: Axis.vertical,
                        spacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          _ActionChip(
                            icon: Icons.call_outlined,
                            label: t['call'] ?? 'Call',
                            compact: true,
                            onTap: () => callProductSeller(context, p),
                          ),
                          _ActionChip(
                            icon: Icons.chat_bubble_outline,
                            label: t['chat'] ?? 'Chat',
                            compact: true,
                            onTap: () => startProductChat(context, p),
                          ),
                          if (showShareButton)
                            _ActionChip(
                              icon: Icons.share_outlined,
                              label: t['share'] ?? 'Share',
                              compact: true,
                              onTap: () {
                                if (onShare != null) {
                                  onShare!();
                                } else {
                                  ShareService.shareProduct(context, product);
                                }
                              },
                            ),
                          if (showCompareButton)
                            _ActionChip(
                              icon: Icons.compare_arrows,
                              label: t['compare'] ?? 'Compare',
                              isActive: isInCompare,
                              compact: true,
                              onTap: () => toggleCompareWithFeedback(
                                context,
                                p,
                                compareProvider,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final currencyProvider = context.watch<CurrencyProvider>();
    final favoritesProvider = context.watch<FavoritesProvider?>();
    final compareProvider = context.watch<CompareProvider?>();
    final isFav = favoritesProvider?.isFavorite(product.id) ?? false;
    final isInCompare = compareProvider?.isInCompare(product.id) ?? false;

    final p = product;
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
                  .withValues(alpha: 0.2),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: _buildImage(
                        context,
                        double.infinity,
                        double.infinity,
                        isGrid: true,
                      ),
                    ),
                    if (p.isSold)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            t['sold'] ?? 'SOLD',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    if (p.isFeatured)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t['featured_label'] ?? 'Featured',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (p.isBoosted)
                      Positioned(
                        top: p.isFeatured ? 28 : 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '🚀 Boosted',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () async {
                          if (favoritesProvider == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t['sign_in_favorites'] ??
                                      'Please sign in to save favorites',
                                ),
                                backgroundColor: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primary,
                              ),
                            );
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await favoritesProvider.toggleFavorite(
                            product,
                          );
                          if (!ok) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  t['favorite_failed'] ??
                                      "Couldn't update favorite",
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 15,
                            color: isFav ? Colors.redAccent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Action chips sit directly under the favourite icon in
                    // the image's top-right corner (Categories layout).
                    Positioned(
                      top: 34,
                      right: 6,
                      child: GestureDetector(
                        // Absorb taps between chips so the card's onTap does
                        // not open the detail page.
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ConstrainedBox(
                            // Wide enough for two compact rows inside the
                            // ~84px-tall image without clipping the last row.
                            constraints: const BoxConstraints(maxWidth: 130),
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 2,
                              runSpacing: 2,
                              children: [
                                _ActionChip(
                                  icon: Icons.call_outlined,
                                  label: t['call'] ?? 'Call',
                                  compact: true,
                                  onTap: () => callProductSeller(context, p),
                                ),
                                _ActionChip(
                                  icon: Icons.chat_bubble_outline,
                                  label: t['chat'] ?? 'Chat',
                                  compact: true,
                                  onTap: () => startProductChat(context, p),
                                ),
                                if (showShareButton)
                                  _ActionChip(
                                    icon: Icons.share_outlined,
                                    label: t['share'] ?? 'Share',
                                    compact: true,
                                    onTap: () {
                                      if (onShare != null) {
                                        onShare!();
                                      } else {
                                        ShareService.shareProduct(
                                          context,
                                          product,
                                        );
                                      }
                                    },
                                  ),
                                if (showCompareButton)
                                  _ActionChip(
                                    icon: Icons.compare_arrows,
                                    label: t['compare'] ?? 'Compare',
                                    isActive: isInCompare,
                                    compact: true,
                                    onTap: () => toggleCompareWithFeedback(
                                      context,
                                      p,
                                      compareProvider,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.price == 0
                          ? (t['contact'] ?? 'Contact')
                          : currencyProvider.formatPrice(p.price),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 9,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          p.postedTime,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 9,
                          color:
                              theme.textTheme.bodySmall?.color?.withValues(
                                alpha: 0.5,
                              ) ??
                              AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${p.location}${p.city.isNotEmpty ? ', ${p.city}' : ''}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  theme.textTheme.bodySmall?.color?.withValues(
                                    alpha: 0.5,
                                  ) ??
                                  AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _ConditionBadge(condition: p.condition, small: true),
                        const Spacer(),
                        Icon(
                          Icons.remove_red_eye_outlined,
                          size: 9,
                          color:
                              theme.textTheme.bodySmall?.color?.withValues(
                                alpha: 0.5,
                              ) ??
                              AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${p.views}',
                          style: TextStyle(
                            color:
                                theme.textTheme.bodySmall?.color?.withValues(
                                  alpha: 0.5,
                                ) ??
                                AppColors.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    double width,
    double height, {
    bool isGrid = false,
  }) {
    if (product.imageUrls.isNotEmpty) {
      return Hero(
        tag: 'product_image_${product.id}',
        child: Image.network(
          product.imageUrls[0],
          width: width,
          height: height,
          cacheWidth: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(context, width, height),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final isDarkLoading =
                Theme.of(context).brightness == Brightness.dark;
            return Container(
              width: width,
              height: height,
              color: isDarkLoading
                  ? AppColors.surface
                  : AppColors.cardLightMode,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return _buildImagePlaceholder(context, width, height);
  }

  Widget _buildImagePlaceholder(
    BuildContext context,
    double width,
    double height,
  ) {
    IconData icon;
    Color color;
    switch (product.category) {
      case 'Vehicles':
        icon = Icons.directions_car;
        color = const Color(0xFF1565C0);
        break;
      case 'Properties':
        icon = Icons.home;
        color = const Color(0xFF2E7D32);
        break;
      case 'Electronics':
        icon = Icons.devices;
        color = const Color(0xFF6A1B9A);
        break;
      case 'Furniture & Décor':
        icon = Icons.chair;
        color = const Color(0xFF5D4037);
        break;
      case 'WaterCrafts':
        icon = Icons.directions_boat;
        color = const Color(0xFF0288D1);
        break;
      case 'Jewellery':
        icon = Icons.diamond;
        color = const Color(0xFFC62828);
        break;
      case 'Lifestyle':
        icon = Icons.shopping_bag;
        color = const Color(0xFFD81B60);
        break;
      case 'Market':
        icon = Icons.shopping_cart;
        color = const Color(0xFF388E3C);
        break;
      case 'Outdoor & Leisure':
        icon = Icons.landscape;
        color = const Color(0xFFF57C00);
        break;
      case 'Special Numbers':
        icon = Icons.looks_one;
        color = AppColors.gold;
        break;
      case 'Heavy Equipments':
        icon = Icons.construction;
        color = const Color(0xFF455A64);
        break;
      case 'Jobs Center':
        icon = Icons.work;
        color = const Color(0xFF00897B);
        break;
      case 'Super Ads':
        icon = Icons.star;
        color = AppColors.orange;
        break;
      default:
        icon = Icons.image;
        color = AppColors.textMuted;
    }
    return Container(
      width: width,
      height: height,
      color: color.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.12 : 0.08,
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.38,
          heightFactor: 0.38,
          child: FittedBox(
            child: Icon(icon, color: color.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  // Smallest variant, used for the chips overlaid on grid-card images.
  final bool compact;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 2, vertical: 1)
        : const EdgeInsets.symmetric(horizontal: 7, vertical: 3);
    final iconSize = compact ? 7.0 : 10.0;
    final fontSize = compact ? 7.0 : 10.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // Opaque so taps on the chip's padding count as taps on the chip,
        // instead of falling through to the card's navigation onTap.
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: padding,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.gold.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: isActive ? 0.8 : 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: AppColors.gold),
              SizedBox(width: compact ? 1 : 3),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryCircle extends StatelessWidget {
  final String name;
  final String icon;
  final double size;
  final VoidCallback? onTap;

  const CategoryCircle({
    super.key,
    required this.name,
    required this.icon,
    this.size = 65,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final adjustedSize = screenWidth < 360 ? size * 0.85 : size;
    final iconSize = adjustedSize * 0.42;
    final textSize = screenWidth < 360 ? 10.0 : 11.0;

    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: adjustedSize,
              height: adjustedSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardTheme.color,
                border: Border.all(
                  color:
                      (isDark ? AppColors.divider : AppColors.dividerLightMode)
                          .withValues(alpha: 0.2),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Text(icon, style: TextStyle(fontSize: iconSize)),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: adjustedSize + 10,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: textSize,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdBannerPlaceholder extends StatelessWidget {
  final String text;

  const AdBannerPlaceholder({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  const Icon(Icons.campaign, color: AppColors.gold, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactActionButtons extends StatelessWidget {
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final PrivacySettings? privacy;

  const ContactActionButtons({
    super.key,
    this.onWhatsApp,
    this.onCall,
    this.onChat,
    this.privacy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;

    final showCall = privacy == null || privacy!.allowCalls;
    final showWhatsApp =
        privacy == null || privacy!.phoneVisibility != 'nobody';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : AppColors.cardLightMode,
        border: Border(
          top: BorderSide(
            color: (isDark ? AppColors.divider : AppColors.dividerLightMode)
                .withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (showCall)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                label: Text(
                  t['call_now'] ?? 'Call Now',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (showCall && onChat != null) const SizedBox(width: 10),
          if (showWhatsApp && onWhatsApp != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onWhatsApp,
                icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                label: Text(
                  t['whatsapp'] ?? 'WhatsApp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (showWhatsApp && onWhatsApp != null && onChat != null)
            const SizedBox(width: 10),
          if (onChat != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onChat,
                icon: const Icon(
                  Icons.message_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  t['message'] ?? 'Message',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 12),
          Text(
            t['loading'] ?? 'Loading...',
            style: TextStyle(
              color: isDark
                  ? AppColors.textMuted
                  : AppColors.textSecondaryLightMode,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: AppColors.textMuted.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.textMuted
                    : AppColors.textSecondaryLightMode,
                fontSize: 13,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  final String condition;
  final bool small;

  const _ConditionBadge({required this.condition, this.small = false});

  Color get _color {
    switch (condition) {
      case 'Rent':
        return AppColors.primary;
      case 'Sale':
        return AppColors.orange;
      case 'Exchange':
        return const Color(0xFF7B1FA2);
      case 'Full Time':
        return AppColors.green;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _color.withValues(alpha: 0.12);
    final pad = small
        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
        : const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
    final radius = small ? 4.0 : 6.0;
    final fontSize = small ? 8.5 : 10.0;
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        condition,
        style: TextStyle(
          color: _color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SocialMediaFooter extends StatelessWidget {
  const SocialMediaFooter({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LanguageProvider>().t;
    const items = [
      (FontAwesomeIcons.tiktok, 'TikTok', 'https://www.tiktok.com/'),
      (FontAwesomeIcons.instagram, 'Instagram', 'https://www.instagram.com/'),
      (FontAwesomeIcons.snapchat, 'Snapchat', 'https://www.snapchat.com/'),
      (FontAwesomeIcons.youtube, 'YouTube', 'https://www.youtube.com/'),
      (FontAwesomeIcons.xTwitter, 'X', 'https://twitter.com/'),
      (FontAwesomeIcons.facebookF, 'Facebook', 'https://www.facebook.com/'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Requested plum background: rgb(74,10,30) = #4A0A1E.
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t['follow_us'] ?? 'Follow us',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, name, url) in items)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: name,
                    child: Semantics(
                      button: true,
                      label: name,
                      child: InkWell(
                        onTap: () => _launch(url),
                        customBorder: const CircleBorder(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            // Same plum as the card (#4A0A1E); the gold ring
                            // keeps each circle distinct against the card.
                            color: AppColors.primaryDark,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.65),
                              width: 1.6,
                            ),
                          ),
                          child: Center(
                            child: FaIcon(
                              icon,
                              size: 22,
                              // White on plum stays clearly visible.
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
