import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VerificationResult {
  VerificationResult({
    required this.signature,
    required this.idImageUrl,
    required this.selfieImageUrl,
  });

  final String signature;
  final String idImageUrl;
  final String selfieImageUrl;
}

class VerificationService {
  VerificationService({FirebaseStorage? storage, FirebaseFunctions? functions})
    : _storage = storage ?? FirebaseStorage.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  bool isValidNationalId(String rawIdNumber) {
    final normalized = rawIdNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return normalized.length >= 8 && normalized.length <= 32;
  }

  Future<VerificationResult> verifyAndPersist({
    required String uid,
    required String nationalIdNumber,
    required File idImageFile,
    required File selfieImageFile,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;

    final idRef = _storage.ref('verifications/$uid/${ts}_id.jpg');
    final selfieRef = _storage.ref('verifications/$uid/${ts}_selfie.jpg');

    await idRef.putFile(idImageFile);
    await selfieRef.putFile(selfieImageFile);

    final idImageUrl = await idRef.getDownloadURL();
    final selfieImageUrl = await selfieRef.getDownloadURL();

    try {
      final callable = _functions.httpsCallable('submitVerification');
      final result = await callable.call({
        'nationalIdNumber': nationalIdNumber,
        'idImageUrl': idImageUrl,
        'selfieImageUrl': selfieImageUrl,
      });

      final data = (result.data as Map?) ?? {};
      final signature = data['signature']?.toString() ?? '';

      return VerificationResult(
        signature: signature,
        idImageUrl: idImageUrl,
        selfieImageUrl: selfieImageUrl,
      );
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        throw StateError('id_already_registered');
      }
      rethrow;
    }
  }
}
