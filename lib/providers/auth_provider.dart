import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../models/user_model.dart';
import '../core/errors/app_exception.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  final UserRepository _userRepo = UserRepository();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _authRepo.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      try {
        // Try to get user from Firestore with a timeout
        UserModel? model = await _userRepo.getUserById(user.uid).timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        
        // If user document doesn't exist or timed out, create/use a default one
        if (model == null) {
          model = UserModel(
            id: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            photoUrl: user.photoURL ?? '',
            isAdminApproved: true,
            createdAt: DateTime.now(),
          );
          // Try to save it, but don't block the UI if it fails
          _userRepo.createUser(model).catchError((e) => debugPrint("Failed to create user doc: $e"));
        }
        
        // Check suspension/approval status
        if (model.isSuspended || !model.isAdminApproved) {
          _error = 'Your account is suspended';
          await _authRepo.signOut();
          _firebaseUser = null;
          _userModel = null;
          notifyListeners();
          return;
        }

        _userModel = model;
      } catch (e) {
        _error = e.toString();
        // Fallback to basic model from Auth if everything fails
        _userModel = UserModel(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          isAdminApproved: true,
          createdAt: DateTime.now(),
        );
      }
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final credential = await _authRepo.signIn(email, password);
      if (credential.user != null) {
        final userModel = await _userRepo.getUserById(credential.user!.uid);
        if (userModel != null && (userModel.isSuspended || !userModel.isAdminApproved)) {
          await signOut();
          throw AuthException('Your account is suspended', 'suspended');
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithPhone(String phoneNumber, Function(String) onCodeSent) async {
    _setLoading(true);
    try {
      await _authRepo.signInWithPhone(
        phoneNumber: phoneNumber,
        onCodeSent: (id) {
          _setLoading(false);
          onCodeSent(id);
        },
        onFailed: (e) {
          _setLoading(false);
          throw AuthException(e.message ?? 'Phone auth failed', e.code);
        },
        onAutoVerify: (credential) {
          _setLoading(false);
        },
      );
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> verifyOTP(String verificationId, String smsCode, String name) async {
    _setLoading(true);
    try {
      final credential = await _authRepo.verifyOTP(verificationId, smsCode);
      if (credential.user != null) {
        // Check if user exists, if not create
        final existingUser = await _userRepo.getUserById(credential.user!.uid);
        if (existingUser == null) {
          final newUser = UserModel(
            id: credential.user!.uid,
            name: name,
            email: '',
            phone: credential.user!.phoneNumber ?? '',
            isAdminApproved: true,
            createdAt: DateTime.now(),
          );
          await _userRepo.createUser(newUser);
          _userModel = newUser;
        } else if (existingUser.isSuspended || !existingUser.isAdminApproved) {
          await signOut();
          throw AuthException('Your account is suspended', 'suspended');
        }
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password, String name, {String phone = ''}) async {
    _setLoading(true);
    try {
      final credential = await _authRepo.signUp(email, password);
      if (credential.user != null) {
        final newUser = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          isAdminApproved: true,
          createdAt: DateTime.now(),
        );
        await _userRepo.createUser(newUser);
        _userModel = newUser;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      await _userRepo.updateUser(updatedUser);
      _userModel = updatedUser;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> updatePrivacy(PrivacySettings privacy) async {
    if (_userModel == null) return;
    final updated = _userModel!.copyWith(privacy: privacy);
    await updateProfile(updated);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
