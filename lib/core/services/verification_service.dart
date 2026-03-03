import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
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
  VerificationService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  String buildIdSignature(String rawIdNumber) {
    final normalized = rawIdNumber
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    return sha256.convert(utf8.encode(normalized)).toString();
  }

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
    final normalizedId = nationalIdNumber
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    final signature = buildIdSignature(normalizedId);
    final ts = DateTime.now().millisecondsSinceEpoch;

    final idRef = _storage.ref('verifications/$uid/${ts}_id.jpg');
    final selfieRef = _storage.ref('verifications/$uid/${ts}_selfie.jpg');

    await idRef.putFile(idImageFile);
    await selfieRef.putFile(selfieImageFile);

    final idImageUrl = await idRef.getDownloadURL();
    final selfieImageUrl = await selfieRef.getDownloadURL();

    final signatureRef = _firestore.collection('id_signatures').doc(signature);
    final userRef = _firestore.collection('users').doc(uid);
    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((tx) async {
      final signatureSnapshot = await tx.get(signatureRef);
      if (signatureSnapshot.exists) {
        final ownerUid = signatureSnapshot.data()?['ownerUid'] as String?;
        if (ownerUid != null && ownerUid != uid) {
          throw StateError('id_already_registered');
        }
      }

      tx.set(signatureRef, {
        'ownerUid': uid,
        'nationalIdLast4': normalizedId.length >= 4
            ? normalizedId.substring(normalizedId.length - 4)
            : normalizedId,
        'updatedAt': now,
      }, SetOptions(merge: true));

      tx.set(userRef, {
        'isVerified': true,
        'verification': {
          'status': 'verified',
          'provider': 'fayda',
          'idSignature': signature,
          'nationalIdLast4': normalizedId.length >= 4
              ? normalizedId.substring(normalizedId.length - 4)
              : normalizedId,
          'idImageUrl': idImageUrl,
          'selfieImageUrl': selfieImageUrl,
          'verifiedAt': now,
        },
        'lastUpdated': now,
      }, SetOptions(merge: true));
    });

    return VerificationResult(
      signature: signature,
      idImageUrl: idImageUrl,
      selfieImageUrl: selfieImageUrl,
    );
  }
}
