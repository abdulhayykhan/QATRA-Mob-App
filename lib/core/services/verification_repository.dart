import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_models.dart';

class VerificationRepository {
  final FirebaseFirestore? _firestore;

  VerificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  bool get isFirebaseAvailable => _firestore != null;

  /// Real-time stream of all pending verification slips for 24/7 Desk Review
  Stream<List<VerificationSlip>> getPendingSlipsStream() {
    if (_firestore == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('verificationQueue')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VerificationSlip.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Submit a requisition slip for verification desk review
  Future<void> submitSlip(VerificationSlip slip) async {
    if (_firestore == null) return;
    try {
      await _firestore
          .collection('verificationQueue')
          .doc(slip.id)
          .set(slip.toMap());
    } catch (e) {
      debugPrint('VerificationRepository.submitSlip error: $e');
      rethrow;
    }
  }

  /// Approve a requisition slip
  Future<void> approveSlip(String slipId) async {
    if (_firestore == null) return;
    try {
      await _firestore
          .collection('verificationQueue')
          .doc(slipId)
          .update({
        'deskReviewStatus': 'Approved & Broadcasted',
        'flagged': false,
      });
    } catch (e) {
      debugPrint('VerificationRepository.approveSlip error: $e');
      rethrow;
    }
  }

  /// Reject a requisition slip with reason
  Future<void> rejectSlip(String slipId, String reason) async {
    if (_firestore == null) return;
    try {
      await _firestore
          .collection('verificationQueue')
          .doc(slipId)
          .update({
        'deskReviewStatus': 'Rejected',
        'flagged': true,
        'flagReason': reason,
      });
    } catch (e) {
      debugPrint('VerificationRepository.rejectSlip error: $e');
      rethrow;
    }
  }
}
