import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/firestore_paths.dart';

class CMSProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DateTime? _lastPolicyUpdate;
  bool _needsPolicyReacceptance = false;
  StreamSubscription? _cmsSub;

  bool get needsPolicyReacceptance => _needsPolicyReacceptance;

  CMSProvider() {
    _init();
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

  @override
  void dispose() {
    _cmsSub?.cancel();
    super.dispose();
  }
}
