// models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Notification types used by the app.
/// Both customers and sellers can receive these.
class NotifType {
  // ── Seller notifications ──────────────────────────────────────────────────
  static const String newBid        = 'new_bid';        // Someone bid on seller's auction
  static const String jobApplication = 'job_application'; // Someone applied to seller's job post
  static const String adApproved    = 'ad_approved';    // Admin approved a listing
  static const String adRejected    = 'ad_rejected';    // Admin rejected a listing
  static const String newMessage    = 'new_message';    // New chat message
  static const String itemSold      = 'item_sold';      // Seller marked item sold / deal confirmed

  // ── Buyer / customer notifications ───────────────────────────────────────
  static const String priceDrop     = 'price_drop';     // Price dropped on a favorited item
  static const String bidOutbid     = 'bid_outbid';     // Someone out-bid the buyer
  static const String bidWon        = 'bid_won';        // Buyer won an auction
  static const String offerReceived = 'offer_received'; // Buyer received a counter-offer
  static const String jobStatusUpdate = 'job_status_update'; // Applied-job status changed

  // ── General ───────────────────────────────────────────────────────────────
  static const String system        = 'system';         // Generic system notification
  static const String reminder      = 'reminder';       // Reminder (e.g. auction ending soon)
}

class NotificationModel {
  final String id;
  final String userId;           // The recipient's UID
  final String type;             // One of NotifType.*
  final String title;
  final String body;
  final bool isRead;
  final String? relatedProductId;
  final String? relatedConversationId;
  final String? relatedJobId;
  final String? actorName;       // Who triggered the notification (e.g. bidder name)
  final String? actorAvatarUrl;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.relatedProductId,
    this.relatedConversationId,
    this.relatedJobId,
    this.actorName,
    this.actorAvatarUrl,
    required this.createdAt,
  });

  // ── Firestore ─────────────────────────────────────────────────────────────
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      type: d['type'] as String? ?? NotifType.system,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      isRead: d['isRead'] as bool? ?? false,
      relatedProductId: d['relatedProductId'] as String?,
      relatedConversationId: d['relatedConversationId'] as String?,
      relatedJobId: d['relatedJobId'] as String?,
      actorName: d['actorName'] as String?,
      actorAvatarUrl: d['actorAvatarUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type,
    'title': title,
    'body': body,
    'isRead': isRead,
    'relatedProductId': relatedProductId,
    'relatedConversationId': relatedConversationId,
    'relatedJobId': relatedJobId,
    'actorName': actorName,
    'actorAvatarUrl': actorAvatarUrl,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    userId: userId,
    type: type,
    title: title,
    body: body,
    isRead: isRead ?? this.isRead,
    relatedProductId: relatedProductId,
    relatedConversationId: relatedConversationId,
    relatedJobId: relatedJobId,
    actorName: actorName,
    actorAvatarUrl: actorAvatarUrl,
    createdAt: createdAt,
  );

  // ── UI helpers ────────────────────────────────────────────────────────────
  IconData get icon {
    switch (type) {
      case NotifType.newBid:        return Icons.gavel;
      case NotifType.jobApplication:return Icons.work_outline;
      case NotifType.adApproved:    return Icons.check_circle_outline;
      case NotifType.adRejected:    return Icons.cancel_outlined;
      case NotifType.newMessage:    return Icons.message_outlined;
      case NotifType.itemSold:      return Icons.handshake_outlined;
      case NotifType.priceDrop:     return Icons.trending_down;
      case NotifType.bidOutbid:     return Icons.gavel;
      case NotifType.bidWon:        return Icons.emoji_events_outlined;
      case NotifType.offerReceived: return Icons.local_offer_outlined;
      case NotifType.jobStatusUpdate: return Icons.assignment_turned_in_outlined;
      case NotifType.reminder:      return Icons.alarm_outlined;
      default:                      return Icons.notifications_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case NotifType.newBid:
      case NotifType.bidOutbid:
      case NotifType.newMessage:
      case NotifType.offerReceived: return AppColors.gold;
      case NotifType.adApproved:
      case NotifType.bidWon:
      case NotifType.itemSold:
      case NotifType.jobApplication:
      case NotifType.jobStatusUpdate:
      case NotifType.priceDrop:     return AppColors.green;
      case NotifType.adRejected:    return Colors.redAccent;
      case NotifType.reminder:      return AppColors.orange;
      default:                      return AppColors.primary;
    }
  }

  /// Human-readable relative time (supports translations)
  String timeAgoStr(Map<String, String> t) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return t['time_just_now'] ?? 'Just now';
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return '$mins ${t['time_min_ago'] ?? 'min ago'}';
    }
    if (diff.inHours < 24) {
      final hrs = diff.inHours;
      return '$hrs ${hrs > 1 ? (t['time_hours_ago'] ?? 'hours ago') : (t['time_hour_ago'] ?? 'hour ago')}';
    }
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return '$days ${days > 1 ? (t['time_days_ago'] ?? 'days ago') : (t['time_day_ago'] ?? 'day ago')}';
    }
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
