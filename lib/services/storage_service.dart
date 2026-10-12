import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cross_file/cross_file.dart';

import '../core/cloudinary_config.dart';
import '../core/storage_config.dart';

/// Central image storage for the app (shared by the mobile app and the web
/// build). Uploads go to whichever backend is selected in
/// [activeStorageBackend].
///
/// The Firebase Storage implementation is kept intact so that when the Blaze
/// plan is re-enabled the app can switch back with a one-line change.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Cross-platform upload: reads the [XFile] into bytes and uploads them.
  /// Works on mobile, desktop, and web.
  Future<String> uploadProductImage(String productId, XFile file) async {
    final bytes = await file.readAsBytes();
    return uploadProductImageBytes(productId, bytes);
  }

  Future<String> uploadProductImageBytes(
      String productId, Uint8List bytes) async {
    switch (activeStorageBackend) {
      case StorageBackend.cloudinary:
        return _uploadToCloudinary(bytes);
      case StorageBackend.firebase:
        return _uploadToFirebaseProduct(productId, bytes);
    }
  }

  Future<String> uploadAvatar(String uid, XFile file) async {
    final bytes = await file.readAsBytes();
    switch (activeStorageBackend) {
      case StorageBackend.cloudinary:
        return _uploadToCloudinary(bytes);
      case StorageBackend.firebase:
        return _uploadToFirebaseAvatar(uid, bytes);
    }
  }

  /// Deletes an uploaded file.
  ///
  /// Note: Cloudinary unsigned uploads cannot be deleted from the client
  /// (deletion requires the API secret), so this is a no-op on Cloudinary.
  Future<void> deleteFile(String url) async {
    if (activeStorageBackend == StorageBackend.firebase) {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    }
  }

  // ── Cloudinary ────────────────────────────────────────────────────────────

  /// Uploads raw bytes to Cloudinary via an unsigned upload preset and returns
  /// the resulting public `secure_url`.
  Future<String> _uploadToCloudinary(Uint8List bytes) async {
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse(CloudinaryConfig.uploadUrl))
            ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
            ..fields['folder'] = CloudinaryConfig.folder
            ..files.add(http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: '${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));

      final streamed = await request.send().timeout(CloudinaryConfig.timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            'Cloudinary upload failed (${response.statusCode}): ${response.body}');
        throw Exception('Cloudinary upload failed (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['secure_url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('Cloudinary upload returned no secure_url');
      }
      return url;
    } catch (e) {
      debugPrint('Cloudinary Storage Error: $e');
      rethrow;
    }
  }

  // ── Firebase (kept for when Blaze is re-enabled) ──────────────────────────

  Future<String> _uploadToFirebaseProduct(
      String productId, Uint8List bytes) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref =
          _storage.ref().child('products').child(productId).child(fileName);

      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Firebase Storage Error: $e');
      rethrow;
    }
  }

  Future<String> _uploadToFirebaseAvatar(String uid, Uint8List bytes) async {
    final ref = _storage.ref().child('avatars/$uid/profile.jpg');
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }
}
