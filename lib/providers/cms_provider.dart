import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/firestore_paths.dart';

class CMSProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Policies
  DateTime? _lastPolicyUpdate;
  bool _needsPolicyReacceptance = false;
  
  // Settings
  bool _maintenanceMode = false;
  bool _requireIdVerification = false;
  bool _cardPaymentEnabled = true;
  bool _jazzCashEnabled = true;
  bool _easyPaisaEnabled = true;
  String _maintenanceMsg = 'Pak Sale is currently undergoing maintenance. Please check back later.';
  
  // Content
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _broadcastNotifications = [];
  String _termsContent = '';
  String _privacyContent = '';
  String _helpContent = '';
  
  StreamSubscription? _cmsSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _bannersSub;
  StreamSubscription? _categoriesSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _helpSub;

  bool get needsPolicyReacceptance => _needsPolicyReacceptance;
  bool get maintenanceMode => _maintenanceMode;
  bool get requireIdVerification => _requireIdVerification;
  bool get cardPaymentEnabled => _cardPaymentEnabled;
  bool get jazzCashEnabled => _jazzCashEnabled;
  bool get easyPaisaEnabled => _easyPaisaEnabled;
  String get maintenanceMsg => _maintenanceMsg;
  List<Map<String, dynamic>> get banners => _banners;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get broadcastNotifications => _broadcastNotifications;
  String get termsContent => _termsContent;
  String get privacyContent => _privacyContent;
  String get helpContent => _helpContent;

  CMSProvider() {
    _init();
    _listenToSettings();
    _listenToDynamicContent();
  }

  Future<void> _init() async {
    _cmsSub = _db.collection(FirestorePaths.cms).doc('policies').snapshots().listen((doc) async {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final Timestamp? timestamp = data['lastUpdated'] as Timestamp?;
        if (timestamp != null) {
          _lastPolicyUpdate = timestamp.toDate();
          await _checkAcceptance();
        }
      }
    });

    // Fetch static CMS content
    _db.collection(FirestorePaths.cms).doc('terms').get().then((doc) {
      if (doc.exists) _termsContent = (doc.data() as Map<String, dynamic>)['content'] ?? '';
      notifyListeners();
    });
    _db.collection(FirestorePaths.cms).doc('privacy').get().then((doc) {
      if (doc.exists) _privacyContent = (doc.data() as Map<String, dynamic>)['content'] ?? '';
      notifyListeners();
    });
    
    // Listen to help content
    _helpSub = _db.collection(FirestorePaths.cms).doc('help').snapshots().listen((doc) {
      if (doc.exists) _helpContent = (doc.data() as Map<String, dynamic>)['content'] ?? '';
      notifyListeners();
    });
  }

  void _listenToSettings() {
    _settingsSub = _db.collection('settings').doc('general').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _maintenanceMode = data['maintenanceMode'] ?? false;
        _requireIdVerification = data['requireIdVerification'] ?? false;
        _cardPaymentEnabled = data['cardPaymentEnabled'] ?? true;
        _jazzCashEnabled = data['jazzCashEnabled'] ?? true;
        _easyPaisaEnabled = data['easyPaisaEnabled'] ?? true;
        _maintenanceMsg = data['maintenanceMessage'] ?? _maintenanceMsg;
        notifyListeners();
      }
    });
  }

  void _listenToDynamicContent() {
    _bannersSub = _db.collection('banners').where('isActive', isEqualTo: true).snapshots().listen((snap) {
      _banners = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });

    _categoriesSub = _db.collection('categories').orderBy('order').snapshots().listen((snap) {
      _categories = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });
    
    // Listen to broadcast notifications
    _notificationsSub = _db.collection('broadcast_notifications').orderBy('createdAt', descending: true).snapshots().listen((snap) {
      _broadcastNotifications = snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      notifyListeners();
    });
  }

  Future<void> _checkAcceptance() async {
    if (_lastPolicyUpdate == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastAcceptedStr = prefs.getString('last_accepted_policy_date');
    
    if (lastAcceptedStr == null) {
      // First time user, they'll accept during registration/login or first view
      _needsPolicyReacceptance = false; 
    } else {
      final lastAccepted = DateTime.parse(lastAcceptedStr);
      _needsPolicyReacceptance = _lastPolicyUpdate!.isAfter(lastAccepted);
    }
    notifyListeners();
  }

  Future<void> acceptPolicies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_accepted_policy_date', DateTime.now().toIso8601String());
    _needsPolicyReacceptance = false;
    notifyListeners();
  }

  Future<void> updatePaymentSettings({
    bool? card,
    bool? jazzCash,
    bool? easyPaisa,
  }) async {
    final Map<String, dynamic> updates = {};
    if (card != null) updates['cardPaymentEnabled'] = card;
    if (jazzCash != null) updates['jazzCashEnabled'] = jazzCash;
    if (easyPaisa != null) updates['easyPaisaEnabled'] = easyPaisa;

    if (updates.isNotEmpty) {
      await _db.collection('settings').doc('general').update(updates);
    }
  }

  Future<void> setMaintenanceMode(bool value, {String? msg}) async {
    final Map<String, dynamic> updates = {'maintenanceMode': value};
    if (msg != null) updates['maintenanceMessage'] = msg;
    await _db.collection('settings').doc('general').update(updates);
  }

  // Admin methods to update content
  Future<void> updateTerms(String content) async {
    await _db.collection(FirestorePaths.cms).doc('terms').set({'content': content}, SetOptions(merge: true));
  }
  
  Future<void> updatePrivacy(String content) async {
    await _db.collection(FirestorePaths.cms).doc('privacy').set({'content': content}, SetOptions(merge: true));
  }
  
  Future<void> updateHelp(String content) async {
    await _db.collection(FirestorePaths.cms).doc('help').set({'content': content}, SetOptions(merge: true));
  }
  
  Future<void> addBanner(Map<String, dynamic> banner) async {
    await _db.collection('banners').add(banner);
  }
  
  Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    await _db.collection('banners').doc(id).update(data);
  }
  
  Future<void> deleteBanner(String id) async {
    await _db.collection('banners').doc(id).delete();
  }
  
  Future<void> addCategory(Map<String, dynamic> category) async {
    await _db.collection('categories').add(category);
  }
  
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _db.collection('categories').doc(id).update(data);
  }
  
  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }
  
  Future<void> sendBroadcastNotification(Map<String, dynamic> notification) async {
    await _db.collection('broadcast_notifications').add({
      ...notification,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
  
  @override
  void dispose() {
    _cmsSub?.cancel();
    _settingsSub?.cancel();
    _bannersSub?.cancel();
    _categoriesSub?.cancel();
    _notificationsSub?.cancel();
    _helpSub?.cancel();
    super.dispose();
  }
}
