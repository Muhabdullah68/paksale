// screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/language_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/cms_provider.dart';
import '../models/notification_model.dart';
import '../core/utils/timestamp_utils.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LanguageProvider>().t;
    final auth = context.watch<AuthProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final cmsProvider = context.watch<CMSProvider>();

    // ── Guest state ──────────────────────────────────────────────────────────
    if (!auth.isAuthenticated) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context, t, notifProvider, isDark, auth),
        body: _GuestBanner(t: t),
      );
    }

    // ── Authenticated state ──────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, t, notifProvider, isDark, auth),
      body: (notifProvider.isLoading)
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : (notifProvider.notifications.isEmpty && cmsProvider.broadcastNotifications.isEmpty)
              ? _EmptyState(t: t, isDark: isDark)
              : _NotificationList(
                  notifProvider: notifProvider,
                  t: t,
                  broadcastNotifications: cmsProvider.broadcastNotifications,
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    Map<String, String> t,
    NotificationProvider notifProvider,
    bool isDark,
    AuthProvider auth,
  ) {
    return AppBar(
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Text(
            t['notifications'] ?? 'Notifications',
            style: const TextStyle(color: Colors.white),
          ),
          if (auth.isAuthenticated && notifProvider.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${notifProvider.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (auth.isAuthenticated && notifProvider.notifications.isNotEmpty)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: isDark ? AppColors.primaryDark : Colors.white,
            onSelected: (val) async {
              if (val == 'read_all') {
                await notifProvider.markAllRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        t['all_marked_read'] ?? 'All marked as read'),
                    backgroundColor: AppColors.green,
                    duration: const Duration(seconds: 2),
                  ));
                }
              } else if (val == 'clear_all') {
                await notifProvider.clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        t['notifications_cleared'] ??
                            'All notifications cleared'),
                    backgroundColor: AppColors.gold,
                    duration: const Duration(seconds: 2),
                  ));
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'read_all',
                child: Row(children: [
                  const Icon(Icons.done_all,
                      size: 18, color: AppColors.green),
                  const SizedBox(width: 10),
                  Text(t['mark_all_read'] ?? 'Mark all as read',
                      style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLightMode)),
                ]),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(children: [
                  const Icon(Icons.delete_sweep,
                      size: 18, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Text(t['clear_all'] ?? 'Clear All',
                      style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLightMode)),
                ]),
              ),
            ],
          ),
      ],
    );
  }
}

// ── Notification list ─────────────────────────────────────────────────────────
class _NotificationList extends StatelessWidget {
  final NotificationProvider notifProvider;
  final Map<String, String> t;
  final List<Map<String, dynamic>> broadcastNotifications;
  const _NotificationList({required this.notifProvider, required this.t, required this.broadcastNotifications});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifications = notifProvider.notifications;

    // Group by date
    final today = <NotificationModel>[];
    final yesterday = <NotificationModel>[];
    final older = <NotificationModel>[];

    final now = DateTime.now();
    for (final n in notifications) {
      final diff = now.difference(n.createdAt);
      if (diff.inDays == 0) {
        today.add(n);
      } else if (diff.inDays == 1) {
        yesterday.add(n);
      } else {
        older.add(n);
      }
    }

    return ListView(
      children: [
        if (broadcastNotifications.isNotEmpty) ...[
          _GroupHeader(label: 'Announcements', isDark: isDark),
          ...broadcastNotifications.map((n) => _BroadcastNotificationTile(
                notification: n,
                t: t,
              )),
        ],
        if (today.isNotEmpty) ...[
          _GroupHeader(label: t['today'] ?? 'Today', isDark: isDark),
          ...today.map((n) => _NotificationTile(
                notif: n,
                t: t,
                onDismiss: () => notifProvider.delete(n.id),
                onTap: () => notifProvider.markRead(n.id),
              )),
        ],
        if (yesterday.isNotEmpty) ...[
          _GroupHeader(label: t['yesterday'] ?? 'Yesterday', isDark: isDark),
          ...yesterday.map((n) => _NotificationTile(
                notif: n,
                t: t,
                onDismiss: () => notifProvider.delete(n.id),
                onTap: () => notifProvider.markRead(n.id),
              )),
        ],
        if (older.isNotEmpty) ...[
          _GroupHeader(label: t['earlier'] ?? 'Earlier', isDark: isDark),
          ...older.map((n) => _NotificationTile(
                notif: n,
                t: t,
                onDismiss: () => notifProvider.delete(n.id),
                onTap: () => notifProvider.markRead(n.id),
              )),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Broadcast notification tile ─────────────────────────────────────────────────────────
class _BroadcastNotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final Map<String, String> t;
  const _BroadcastNotificationTile({required this.notification, required this.t});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryDark.withValues(alpha: 0.35)
            : AppColors.primary.withValues(alpha: 0.08),
        border: Border(
          left: BorderSide(
            color: AppColors.gold,
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.campaign, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification['title'] ?? 'Announcement',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (notification['createdAt'] != null)
                      Text(
                        _formatTime(notification['createdAt']),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textSecondaryLightMode,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification['body'] ?? '',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    return TimestampUtils.timeAgo(timestamp);
  }
}

// ── Group header ──────────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _GroupHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          color: isDark
              ? AppColors.textMuted
              : AppColors.textSecondaryLightMode,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  final NotificationModel notif;
  final Map<String, String> t;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notif,
    required this.t,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent.withValues(alpha: 0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(t['delete'] ?? 'Delete',
                style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: notif.isRead
                ? Colors.transparent
                : (isDark
                    ? AppColors.primaryDark.withValues(alpha: 0.45)
                    : AppColors.primary.withValues(alpha: 0.05)),
            border: Border(
              left: BorderSide(
                color: notif.isRead
                    ? Colors.transparent
                    : notif.iconColor,
                width: 3,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: notif.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(notif.icon, color: notif.iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              color: notif.isRead
                                  ? theme.textTheme.bodyLarge?.color
                                  : (isDark
                                      ? Colors.white
                                      : AppColors.primary),
                              fontSize: 14,
                              fontWeight: notif.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          notif.timeAgoStr(t),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondaryLightMode,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.body,
                      style: TextStyle(
                        color: notif.isRead
                            ? (isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLightMode)
                            : theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (notif.actorName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                notif.iconColor.withValues(alpha: 0.2),
                            child: Text(
                              notif.actorName!.isNotEmpty
                                  ? notif.actorName![0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: notif.iconColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            notif.actorName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textSecondaryLightMode,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Unread dot
              if (!notif.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: notif.iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final Map<String, String> t;
  final bool isDark;
  const _EmptyState({required this.t, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          Text(
            t['no_notifications'] ?? 'No Notifications',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t['notifications_empty_hint'] ??
                "We'll notify you when something arrives",
            style: TextStyle(
              color: isDark
                  ? AppColors.textMuted.withValues(alpha: 0.8)
                  : AppColors.textSecondaryLightMode,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Guest banner ──────────────────────────────────────────────────────────────
class _GuestBanner extends StatelessWidget {
  final Map<String, String> t;
  const _GuestBanner({required this.t});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline,
                  size: 44, color: AppColors.gold),
            ),
            const SizedBox(height: 20),
            Text(
              t['login_required'] ?? 'Login Required',
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : AppColors.textPrimaryLightMode,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t['login_to_notifications'] ??
                  'Sign in to see your personalised notifications for bids, messages, price drops and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.textMuted
                    : AppColors.textSecondaryLightMode,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  t['go_to_login'] ?? 'Go to Login',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
