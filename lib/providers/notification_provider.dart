// providers/notification_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repo = NotificationRepository();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> _userNotifications = [];
  List<NotificationModel> _broadcasts = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _uid;

  StreamSubscription<List<NotificationModel>>? _notifSub;
  StreamSubscription<List<NotificationModel>>? _broadcastSub;
  StreamSubscription<int>? _countSub;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get hasUnread => _unreadCount > 0;

  // ── Initialise for a logged-in user ──────────────────────────────────────
  void init(String uid) {
    if (_uid == uid) return; // already listening
    _uid = uid;
    _isLoading = true;
    notifyListeners();

    _notifSub?.cancel();
    _broadcastSub?.cancel();
    _countSub?.cancel();

    _notifSub = _repo.streamForUser(uid).listen((list) {
      _userNotifications = list;
      _mergeAndNotify();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });

    _broadcastSub = _repo.streamBroadcasts().listen((list) {
      _broadcasts = list;
      _mergeAndNotify();
    });

    _countSub = _repo.unreadCountStream(uid).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  void _mergeAndNotify() {
    // Combine and sort by date
    final combined = [..._userNotifications, ..._broadcasts];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _notifications = combined;
    _isLoading = false;
    notifyListeners();
  }

  // ── Dispose streams when user logs out ───────────────────────────────────
  void clear() {
    _notifSub?.cancel();
    _broadcastSub?.cancel();
    _countSub?.cancel();
    _notifSub = null;
    _broadcastSub = null;
    _countSub = null;
    _notifications = [];
    _userNotifications = [];
    _broadcasts = [];
    _unreadCount = 0;
    _uid = null;
    notifyListeners();
  }

  // ── Mark one read ─────────────────────────────────────────────────────────
  Future<void> markRead(String notifId) async {
    await _repo.markRead(notifId);
    // optimistic update
    final idx = _notifications.indexWhere((n) => n.id == notifId);
    if (idx != -1 && !_notifications[idx].isRead) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
  }

  // ── Mark all read ─────────────────────────────────────────────────────────
  Future<void> markAllRead() async {
    if (_uid == null) return;
    await _repo.markAllRead(_uid!);
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }

  // ── Delete one ───────────────────────────────────────────────────────────
  Future<void> delete(String notifId) async {
    await _repo.delete(notifId);
    final removed = _notifications.firstWhere(
      (n) => n.id == notifId,
      orElse: () => _notifications.first,
    );
    _notifications.removeWhere((n) => n.id == notifId);
    if (!removed.isRead && _unreadCount > 0) _unreadCount--;
    notifyListeners();
  }

  // ── Clear all ─────────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    if (_uid == null) return;
    await _repo.clearAll(_uid!);
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }
}
