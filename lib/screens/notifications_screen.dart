// screens/notifications_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: AppColors.gold,
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 20),
            const Text(
              'No Notifications',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you when something arrives',
              style: TextStyle(color: AppColors.textMuted.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
      )
          : ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1),
        itemBuilder: (ctx, i) => _NotificationItem(
          notification: _notifications[i],
          onDismiss: () {
            setState(() {
              _notifications.removeAt(i);
            });
          },
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _notifications = [
    {
      'type': 'price_drop',
      'title': 'Price Drop Alert!',
      'message': 'iPhone 14 Pro price dropped from 2,500 Q.R to 2,000 Q.R',
      'time': '2 min ago',
      'icon': Icons.trending_down,
      'iconColor': AppColors.green,
      'isRead': false,
    },
    {
      'type': 'message',
      'title': 'New Message',
      'message': 'Ahmed Al-Mansoori sent you a message about your listing',
      'time': '1 hour ago',
      'icon': Icons.message,
      'iconColor': AppColors.gold,
      'isRead': false,
    },
    {
      'type': 'offer',
      'title': 'New Offer Received',
      'message': 'Someone made an offer on your Toyota Camry listing',
      'time': '3 hours ago',
      'icon': Icons.local_offer,
      'iconColor': AppColors.orange,
      'isRead': true,
    },
    {
      'type': 'system',
      'title': 'Welcome to QatarSale!',
      'message': 'Start exploring thousands of listings in Qatar',
      'time': '1 day ago',
      'icon': Icons.info_outline,
      'iconColor': AppColors.gold,
      'isRead': true,
    },
    {
      'type': 'reminder',
      'title': 'Your Ad is Expiring Soon',
      'message': 'Renew your "Sofa Set for Sale" listing to keep it visible',
      'time': '2 days ago',
      'icon': Icons.access_time,
      'iconColor': AppColors.orange,
      'isRead': true,
    },
  ];
}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onDismiss;

  const _NotificationItem({required this.notification, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification['time']),
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: Colors.red.withOpacity(0.8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () {
          if (notification['type'] == 'message') {
            Navigator.pop(context);
            // Navigate to chat
          } else if (notification['type'] == 'price_drop') {
            Navigator.pop(context);
            // Navigate to product
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          color: notification['isRead'] ? Colors.transparent : AppColors.primaryDark.withOpacity(0.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification['iconColor'].withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification['icon'],
                  color: notification['iconColor'],
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: TextStyle(
                              color: notification['isRead'] ? AppColors.textPrimary : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          notification['time'],
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: TextStyle(
                        color: notification['isRead'] ? AppColors.textSecondary : AppColors.textPrimary,
                        fontSize: 13,
                      ),
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
}