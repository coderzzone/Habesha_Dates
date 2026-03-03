import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadImage(File file, String fileName) async {
    try {
      final ref = _storage.ref('profile_pics/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Firebase Storage upload error: $e");
    }
    return null;
  }
}
