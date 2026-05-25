import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../repositories/product_repository.dart';

class AdminProvider extends ChangeNotifier {
  final UserRepository _userRepo = UserRepository();
  final ProductRepository _productRepo = ProductRepository();

  List<UserModel> _allUsers = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllUsers() async {
    _setLoading(true);
    try {
      _allUsers = await _userRepo.getAllUsers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleUserSuspension(String uid, bool isSuspended) async {
    try {
      await _userRepo.suspendUser(uid, isSuspended);
      final idx = _allUsers.indexWhere((u) => u.id == uid);
      if (idx != -1) {
        _allUsers[idx] = _allUsers[idx].copyWith(isSuspended: isSuspended);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _userRepo.deleteUser(uid);
      _allUsers.removeWhere((u) => u.id == uid);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
