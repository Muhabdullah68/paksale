import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage(String productId, File file) async {
    try {
      // Ensure file exists before uploading
      if (!await file.exists()) {
        debugPrint('Firebase Storage Error: File does not exist at path: ${file.path}');
        throw Exception("File does not exist at path: ${file.path}");
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('products').child(productId).child(fileName);
      
      final uploadTask = ref.putFile(
        file,
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

  Future<String> uploadAvatar(String uid, File file) async {
    final ref = _storage.ref().child('avatars/$uid/profile.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteFile(String url) async {
    final ref = _storage.refFromURL(url);
    await ref.delete();
  }
}
