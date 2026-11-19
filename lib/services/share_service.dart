// services/share_service.dart — central social-share helper.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'web_clipboard.dart'
    if (dart.library.html) 'web_clipboard_web.dart'
    as browser_clipboard;

class ShareService {
  ShareService._();

  /// Stable public website. The `*.vercel.app` preview host changes on every
  /// deploy, so shared links would break after each release. This custom
  /// domain (308 → `https://www.paksale.net/`) always serves this app,
  /// including `/listing/<id>` deep links.
  static const String siteBase = 'https://paksale.net';

  /// Canonical listing URL — identical on web and app so a link copied in one
  /// opens the exact product on the live website in the other.
  static String productUrl(String productId) => '$siteBase/listing/$productId';

  /// Profile links have no dedicated route, so point at the real account tab
  /// on the same stable domain (instead of the old, unrelated `paksale.app`).
  static String profileUrl(String userId) => '$siteBase/account';

  /// Copies the link instantly on every platform, then on mobile also opens
  /// the native OS share sheet (WhatsApp, Facebook, X, ...) with the same
  /// text. On desktop browsers there is no reliable share sheet, so copying
  /// is the whole action.
  static Future<void> shareText(
    BuildContext context,
    String text, {
    String? title,
    String? subject,
  }) async {
    if (kIsWeb) {
      // Flutter's clipboard channel loses the user gesture on iOS Safari, so
      // write through the browser API while the tap is still on the stack.
      final copied = await browser_clipboard.copyToClipboard(text);
      if (context.mounted) {
        if (copied) {
          _copiedSnack(context);
        } else {
          _showManualCopy(context, text);
        }
      }
      return;
    }

    // Mobile: copy FIRST so the link is available even if the share sheet is
    // dismissed, then open the native sheet with the exact same text.
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) _copiedSnack(context);

    try {
      await SharePlus.instance.share(
        ShareParams(text: text, title: title ?? subject),
      );
    } catch (_) {
      // Clipboard already succeeded — nothing else to do.
    }
  }

  static Future<void> shareProduct(BuildContext context, ProductModel product) {
    final price = product.price > 0
        ? '\nPrice: ${product.price} ${product.currency}'
        : '';
    return shareText(
      context,
      '${product.title}$price\n${productUrl(product.id)}',
      title: product.title,
    );
  }

  static void _copiedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied to clipboard!'),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Last-resort fallback: the link is placed in a selectable dialog so the
  /// user can copy it manually even when the browser blocks clipboard access.
  static void _showManualCopy(BuildContext context, String text) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Copy this link'),
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
