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
