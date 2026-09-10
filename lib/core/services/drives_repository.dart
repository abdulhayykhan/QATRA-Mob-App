import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_models.dart';

class DrivesRepository {
  final FirebaseFirestore? _firestore;

  DrivesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  bool get isFirebaseAvailable => _firestore != null;

  /// Returns real-time stream of upcoming campus drives from Firestore
  Stream<List<DriveEvent>> getUpcomingDrivesStream() {
    if (_firestore == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('drives')
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DriveEvent.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Create a new campus blood drive
  Future<void> createDrive(DriveEvent drive) async {
    if (_firestore == null) return;
    try {
      await _firestore.collection('drives').doc(drive.id).set(drive.toMap());
    } catch (e) {
      debugPrint('DrivesRepository.createDrive error: $e');
      rethrow;
    }
  }
}
