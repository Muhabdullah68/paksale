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
  String _maintenanceMsg = 'FnB Market is currently undergoing maintenance. Please check back later.';
  
  // Content
  List<Map<String, dynamic>> _banners = [];
  List<Map<String, dynamic>> _categories = [];
  String _termsContent = '';
  String _privacyContent = '';
  
  StreamSubscription? _cmsSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _bannersSub;
  StreamSubscription? _categoriesSub;

  bool get needsPolicyReacceptance => _needsPolicyReacceptance;
  bool get maintenanceMode => _maintenanceMode;
  bool get requireIdVerification => _requireIdVerification;
  bool get cardPaymentEnabled => _cardPaymentEnabled;
  bool get jazzCashEnabled => _jazzCashEnabled;
  bool get easyPaisaEnabled => _easyPaisaEnabled;
  String get maintenanceMsg => _maintenanceMsg;
  List<Map<String, dynamic>> get banners => _banners;
  List<Map<String, dynamic>> get categories => _categories;
  String get termsContent => _termsContent;
  String get privacyContent => _privacyContent;

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
  }

  void _listenToSettings() {
    _settingsSub = _db.collection('settings').doc('general').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _maintenanceMode = data['maintenanceMode'] ?? false;
        _requireIdVerification = data['requireIdVerification'] ?? false;
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

  @override
  void dispose() {
    _cmsSub?.cancel();
    _settingsSub?.cancel();
    _bannersSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
