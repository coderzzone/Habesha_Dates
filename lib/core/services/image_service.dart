import 'dart:io';
import 'package:dio/dio.dart';

class ImageService {
  // Replace these with your actual ImageKit details
  static const String _publicKey = "public_328gQi1XhxJ5oKR75qD9BTiT7LA="; 
  static const String _urlEndpoint = "https://ik.imagekit.io/ddw3thfez"; 

  static Future<String?> uploadImage(File file, String fileName) async {
    final dio = Dio();
    
    // ImageKit requires FormData for uploads
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
      "fileName": fileName,
      "publicKey": _publicKey,
      "useUniqueFileName": "true",
      "folder": "/profile_pics",
    });

    try {
      final response = await dio.post(
        "https://upload.imagekit.io/api/v1/files/upload",
        data: formData,
      );

      if (response.statusCode == 200) {
        // Return the permanent URL provided by ImageKit
        return response.data['url'];
      }
    } catch (e) {
      print("ImageKit Upload Error: $e");
    }
    return null;
  }
}