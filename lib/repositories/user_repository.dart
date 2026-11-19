import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/firestore_paths.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef =>
      _firestore.collection(FirestorePaths.users);

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  /// Returns the raw `privacy.allowCalls` value, or `null` when the seller has
  /// never set it (no user doc, no `privacy` map, or no `allowCalls` key).
  ///
  /// This is intentionally separate from [getUserById]: `PrivacySettings`
  /// defaults `allowCalls` to false, so reading through the model would turn a
  /// *missing* value into an explicit "blocked". Callers use `null` to mean
  /// "legacy seller — allow calls", so only an explicit false blocks.
  Future<bool?> getAllowCallsFlag(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;
    final privacy = data['privacy'];
    if (privacy is! Map) return null;
    final value = privacy['allowCalls'];
    return value is bool ? value : null;
  }

  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toFirestore());
  }

  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.id).update(user.toFirestore());
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _usersRef.doc(uid).update({'fcmToken': token});
  }

  Future<void> suspendUser(String uid, bool suspend) async {
    await _usersRef.doc(uid).update({'isSuspended': suspend});
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersRef.get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }
}
