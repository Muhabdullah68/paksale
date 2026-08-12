import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Cross-platform upload: reads the [XFile] into bytes and uploads them.
  /// Works on mobile, desktop, and web.
  Future<String> uploadProductImage(String productId, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return await uploadProductImageBytes(productId, bytes);
    } catch (e) {
      debugPrint('Firebase Storage Error: $e');
      rethrow;
    }
  }

  Future<String> uploadProductImageBytes(String productId, Uint8List bytes) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('products').child(productId).child(fileName);

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage Error: $e');
      rethrow;
    }
  }

  Future<String> uploadAvatar(String uid, XFile file) async {
    final bytes = await file.readAsBytes();
    final ref = _storage.ref().child('avatars/$uid/profile.jpg');
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}
