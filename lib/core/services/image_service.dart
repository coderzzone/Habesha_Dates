import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const int maxFileSize = 1024 * 1024; // 1MB in bytes

  static Future<String?> uploadImage(File file, String fileName, {String folder = 'profile_pics'}) async {
    try {
      // Check file size limit
      final int sizeInBytes = await file.length();
      if (sizeInBytes > maxFileSize) {
        debugPrint("File size exceeds 1MB limit: ${sizeInBytes / 1024 / 1024} MB");
        return "size_limit_exceeded";
      }

      final ref = _storage.ref('$folder/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Firebase Storage upload error: $e");
    }
    return null;
  }
}
