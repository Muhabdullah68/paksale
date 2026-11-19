// services/share_service.dart — central social-share helper.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'web_clipboard.dart'
    if (dart.library.html) 'web_clipboard_web.dart' as browser_clipboard;

class ShareService {
  ShareService._();

  /// Canonical listing URL. On web uses the actual origin so links are
  /// shareable; on mobile uses the public deep-link host.
  static String productUrl(String productId) {
    if (kIsWeb) {
      final base = Uri.base;
      return '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}/listing/$productId';
    }
    return 'https://paksale.app/listing/$productId';
  }

  static String profileUrl(String userId) {
    if (kIsWeb) {
      final base = Uri.base;
      return '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}/account';
    }
    return 'https://paksale.app/profile/$userId';
  }

  /// Opens the native OS/browser share sheet (WhatsApp, Facebook, X, Copy
  /// Link, ...). Falls back to clipboard when the platform has no sheet
  /// (e.g. desktop browsers without the Web Share API).
  static Future<void> shareText(
    BuildContext context,
    String text, {
    String? title,
    String? subject,
  }) async {
    // Browsers do not reliably expose a share sheet, and Flutter's clipboard
    // channel loses the user gesture on iOS Safari. Write through the browser
    // API synchronously instead; if that fails, show a selectable fallback so
    // the link is still usable.
    if (kIsWeb) {
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

    try {
      await SharePlus.instance.share(
        ShareParams(text: text, title: title ?? subject),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) _copiedSnack(context);
    }
  }

  static Future<void> shareProduct(
      BuildContext context, ProductModel product) {
    final price = product.price > 0 ? '\nPrice: ${product.price} ${product.currency}' : '';
    return shareText(
      context,
      '${product.title}$price\n${productUrl(product.id)}',
      title: product.title,
    );
  }

  static void _copiedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Link copied to clipboard!'),
      backgroundColor: AppColors.gold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
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
