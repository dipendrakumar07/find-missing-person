import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a photo to Firebase Storage and returns the public download URL.
  /// If Firebase Storage is unavailable or unconfigured, converts to a resilient Base64 Data URI
  /// so photos are permanently stored directly in Firestore and NEVER disappear!
  Future<String> uploadPhoto({
    File? file,
    Uint8List? bytes,
    required String fileName,
    String folder = 'missing_persons_photos',
  }) async {
    // 1. Always obtain the raw image bytes
    Uint8List? imageBytes = bytes;
    if (imageBytes == null && file != null && !kIsWeb) {
      try {
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
        }
      } catch (e) {
        debugPrint('Error reading photo file bytes: $e');
      }
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      return '';
    }

    // 2. Prepare permanent Base64 Data URI (guaranteed persistence across all devices)
    final base64String = base64Encode(imageBytes);
    final dataUri = 'data:image/jpeg;base64,$base64String';

    // 3. Attempt Firebase Storage upload if credentials and storage are active
    final apiKey = _storage.app.options.apiKey;
    if (!apiKey.contains('Dummy') && apiKey.isNotEmpty) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final ref = _storage.ref().child('$folder/${timestamp}_$cleanName');

        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
        );

        final uploadTask = ref.putData(imageBytes, metadata);
        final snapshot = await uploadTask.timeout(const Duration(seconds: 10));
        final downloadUrl = await snapshot.ref.getDownloadURL().timeout(const Duration(seconds: 5));
        if (downloadUrl.isNotEmpty) {
          return downloadUrl;
        }
      } catch (e) {
        debugPrint('Firebase Storage notice ($e) -> Using permanent Base64 cloud storage in Firestore');
      }
    }

    // 4. Return permanent Data URI (Never return temporary local cache path!)
    return dataUri;
  }
}
