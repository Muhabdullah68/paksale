// services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Static helper methods that fire-and-forget a notification to Firestore.
/// Call these from any business-logic point (product creation, chat, auction, etc.).
///
/// Usage example:
///   await NotificationService.adApproved(
///     sellerId: product.sellerId,
///     productTitle: product.title,
///     productId: product.id,
///   );
class NotificationService {

  // ─────────────────────────────────────────────────────────────────────────
  // SELLER notifications
  // ─────────────────────────────────────────────────────────────────────────

  /// Someone placed a bid on the seller's auction listing.
  static Future<void> newBid({
    required String sellerId,
    required String productTitle,
    required String productId,
    required double bidAmount,
    required String bidderName,
    String currency = 'Q.R',
  }) =>
      _send(NotificationModel(
        id: '',
        userId: sellerId,
        type: NotifType.newBid,
        title: 'New Bid Placed! 🔨',
        body:
            '$bidderName bid ${bidAmount.toStringAsFixed(0)} $currency on your "$productTitle".',
        relatedProductId: productId,
        actorName: bidderName,
        createdAt: DateTime.now(),
      ));

  /// A buyer applied to the seller's job post.
  static Future<void> jobApplication({
    required String sellerId,
    required String jobTitle,
    required String jobId,
    required String applicantName,
  }) =>
      _send(NotificationModel(
        id: '',
        userId: sellerId,
        type: NotifType.jobApplication,
        title: 'New Application Received 📋',
        body: '$applicantName applied for your "$jobTitle" position.',
        relatedJobId: jobId,
        actorName: applicantName,
        createdAt: DateTime.now(),
      ));

  /// Admin approved the seller's listing.
  static Future<void> adApproved({
    required String sellerId,
    required String productTitle,
    required String productId,
  }) =>
      _send(NotificationModel(
        id: '',
        userId: sellerId,
        type: NotifType.adApproved,
        title: 'Ad Approved ✅',
        body: 'Your "$productTitle" listing is now live and visible to buyers.',
        relatedProductId: productId,
        createdAt: DateTime.now(),
      ));

  /// Admin rejected the seller's listing.
  static Future<void> adRejected({
    required String sellerId,
    required String productTitle,
    required String productId,
    String reason = '',
  }) =>
      _send(NotificationModel(
        id: '',
        userId: sellerId,
        type: NotifType.adRejected,
        title: 'Ad Rejected ❌',
        body: reason.isNotEmpty
            ? 'Your "$productTitle" was rejected. Reason: $reason'
            : 'Your "$productTitle" listing was rejected. Please review and resubmit.',
        relatedProductId: productId,
        createdAt: DateTime.now(),
      ));

  /// A deal was confirmed and the item is sold.
  static Future<void> itemSold({
    required String sellerId,
    required String productTitle,
    required String productId,
    required String buyerName,
  }) =>
      _send(NotificationModel(
        id: '',
        userId: sellerId,
        type: NotifType.itemSold,
        title: 'Item Sold 🎉',
        body: '$buyerName confirmed the purchase of "$productTitle". Congratulations!',
        relatedProductId: productId,
        actorName: buyerName,
        createdAt: DateTime.now(),
      ));

  // ─────────────────────────────────────────────────────────────────────────
  // BUYER / CUSTOMER notifications
  // ─────────────────────────────────────────────────────────────────────────

  /// Price dropped on a product the buyer favorited.
  static Future<void> priceDrop({
    required String buyerId,
    required String productTitle,
    required String productId,
    required double oldPrice,
    required double newPrice,
    String currency = 'Q.R',
  }) =>
      _send(NotificationModel(
        id: '',
        userId: buyerId,
        type: NotifType.priceDrop,
        title: 'Price Drop Alert! 📉',
        body:
            '"$productTitle" dropped from ${oldPrice.toStringAsFixed(0)} to ${newPrice.toStringAsFixed(0)} $currency.',
        relatedProductId: productId,
        createdAt: DateTime.now(),
      ));

  /// Someone out-bid the buyer on an auction.
  static Future<void> bidOutbid({
    required String buyerId,
    required String productTitle,
    required String productId,
    required double currentBid,
    String currency = 'Q.R',
  }) =>
      _send(NotificationModel(
        id: '',
        userId: buyerId,
        type: NotifType.bidOutbid,
        title: "You've Been Outbid! 🔨",
        body:
            'The current bid on "$productTitle" is now ${currentBid.toStringAsFixed(0)} $currency. Bid again to stay in the race.',
        relatedProductId: productId,
        createdAt: DateTime.now(),
      ));

  /// The buyer won an auction.
  static Future<void> bidWon({
    required String buyerId,
    required String productTitle,
    required String productId,
    required double finalBid,
    String currency = 'Q.R',
  }) =>
      _send(NotificationModel(
        id: '',
        userId: buyerId,
        type: NotifType.bidWon,
        title: "You Won the Auction! 🏆",
        body:
            'Congratulations! You won "$productTitle" with a bid of ${finalBid.toStringAsFixed(0)} $currency.',
        relatedProductId: productId,
        createdAt: DateTime.now(),
      ));

  /// Seller sent the buyer a counter-offer / accepted offer.
  static Future<void> offerReceived({
    required String buyerId,
    required String productTitle,
    required String productId,
    required double offerAmount,
    required String sellerName,
    String currency = 'Q.R',
  }) =>
      _send(NotificationModel(
        id: '',
        userId: buyerId,
        type: NotifType.offerReceived,
        title: 'Offer Received 💬',
        body:
            '$sellerName offered you "$productTitle" for ${offerAmount.toStringAsFixed(0)} $currency.',
        relatedProductId: productId,
        actorName: sellerName,
        createdAt: DateTime.now(),
      ));

  /// Buyer's job application status changed (e.g. shortlisted / rejected).
  static Future<void> jobStatusUpdate({
    required String applicantId,
    required String jobTitle,
    required String jobId,
    required String status, // e.g. 'Shortlisted', 'Rejected', 'Interview'
  }) =>
      _send(NotificationModel(
        id: '',
        userId: applicantId,
        type: NotifType.jobStatusUpdate,
        title: 'Application Update 📄',
        body: 'Your application for "$jobTitle" has been updated to: $status.',
        relatedJobId: jobId,
        createdAt: DateTime.now(),
      ));

  // ─────────────────────────────────────────────────────────────────────────
  // SHARED notifications
  // ─────────────────────────────────────────────────────────────────────────

  /// New chat message from another user.
  static Future<void> newMessage({
    required String recipientId,
    required String senderName,
    required String conversationId,
    String messagePreview = '',
  }) =>
      _send(NotificationModel(
        id: '',
        userId: recipientId,
        type: NotifType.newMessage,
        title: 'New Message 💬',
        body: messagePreview.isNotEmpty
            ? '$senderName: $messagePreview'
            : '$senderName sent you a message.',
        relatedConversationId: conversationId,
        actorName: senderName,
        createdAt: DateTime.now(),
      ));

  /// General system or reminder notification.
  static Future<void> system({
    required String userId,
    required String title,
    required String body,
  }) =>
      _send(NotificationModel(
        id: '',
        userId: userId,
        type: NotifType.system,
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ));

  // ─────────────────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────────────────
  static Future<void> _send(NotificationModel notif) async {
    try {
      final doc = FirebaseFirestore.instance.collection('notifications').doc();
      await doc.set({...notif.toFirestore(), 'id': doc.id});
    } catch (e) {
      // Notification failures should never crash the app
      // ignore: avoid_print
      print('[NotificationService] Failed to send notification: $e');
    }
  }
}
