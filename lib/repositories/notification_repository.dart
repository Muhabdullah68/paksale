// repositories/notification_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Manages the `notifications` top-level collection.
/// Each document has a `userId` field so we can query per-user.
///
/// Firestore path: notifications/{notificationId}
///
/// Firestore rules should allow:
///   - read: if request.auth.uid == resource.data.userId
///   - create: if request.auth != null
///   - update: if request.auth.uid == resource.data.userId (for markRead)
///   - delete: if request.auth.uid == resource.data.userId
class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _ref => _db.collection('notifications');
  CollectionReference get _broadcastRef => _db.collection('broadcast_notifications');

  // ── Real-time stream for a user ──────────────────────────────────────────
  Stream<List<NotificationModel>> streamForUser(String uid) {
    return _ref
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  // ── Broadcast stream ──────────────────────────────────────────────────────
  Stream<List<NotificationModel>> streamBroadcasts() {
    return _broadcastRef
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList());
  }

  // ── Unread count stream ──────────────────────────────────────────────────
  Stream<int> unreadCountStream(String uid) {
    return _ref
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.size);
  }

  // ── Create ───────────────────────────────────────────────────────────────
  Future<void> create(NotificationModel notif) async {
    await _ref.doc(notif.id.isEmpty ? null : notif.id).set(notif.toFirestore());
  }

  /// Convenience: create with auto-generated ID
  Future<void> send(NotificationModel notif) async {
    final doc = _ref.doc();
    await doc.set(notif
        .toFirestore()
      ..['id'] = doc.id);
  }

  // ── Mark one as read ─────────────────────────────────────────────────────
  Future<void> markRead(String notifId) async {
    await _ref.doc(notifId).update({'isRead': true});
  }

  // ── Mark all read for user ───────────────────────────────────────────────
  Future<void> markAllRead(String uid) async {
    final snap = await _ref
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Delete one ────────────────────────────────────────────────────────────
  Future<void> delete(String notifId) async {
    await _ref.doc(notifId).delete();
  }

  // ── Clear all for user ───────────────────────────────────────────────────
  Future<void> clearAll(String uid) async {
    final snap = await _ref.where('userId', isEqualTo: uid).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
