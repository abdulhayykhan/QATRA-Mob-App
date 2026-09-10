import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/blood_models.dart';

class EmergencyRequestsRepository {
  final FirebaseFirestore? _firestore;

  EmergencyRequestsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  bool get isFirebaseAvailable => _firestore != null;

  /// Returns real-time stream of all broadcasting or matched requests from Firestore
  Stream<List<EmergencyRequest>> getActiveRequestsStream() {
    if (_firestore == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('emergencyRequests')
        .where('status', whereIn: [RequestStatus.broadcasting.name, RequestStatus.matched.name])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return EmergencyRequest.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Stream a single emergency request by ID
  Stream<EmergencyRequest?> getRequestStream(String requestId) {
    if (_firestore == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('emergencyRequests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return EmergencyRequest.fromMap(doc.data()!, doc.id);
    });
  }

  /// Create a new emergency blood request in Firestore
  Future<void> createRequest(EmergencyRequest request) async {
    if (_firestore == null) return;
    try {
      await _firestore.collection('emergencyRequests').doc(request.id).set(request.toMap());
    } catch (e) {
      debugPrint('EmergencyRequestsRepository.createRequest error: $e');
      rethrow;
    }
  }

  /// Real-time stream of donors who accepted dispatch for a request from the subcollection
  Stream<List<MatchedDonor>> getAcceptedDonorsStream(String requestId) {
    if (_firestore == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('emergencyRequests')
        .doc(requestId)
        .collection('acceptedDonors')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchedDonor.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Donor accepts dispatch -> writes donor record to acceptedDonors subcollection
  /// Strictly restricted to request.auth.uid == donor.id by Firestore security rules
  Future<void> acceptDispatch({
    required String requestId,
    required MatchedDonor donor,
  }) async {
    if (_firestore == null) return;
    try {
      await _firestore
          .collection('emergencyRequests')
          .doc(requestId)
          .collection('acceptedDonors')
          .doc(donor.id)
          .set(donor.toMap());
    } catch (e) {
      debugPrint('EmergencyRequestsRepository.acceptDispatch error: $e');
      rethrow;
    }
  }

  /// Cancel dispatch for a donor -> deletes donor record from acceptedDonors subcollection
  Future<void> cancelDispatch({
    required String requestId,
    required String donorId,
  }) async {
    if (_firestore == null) return;
    try {
      await _firestore
          .collection('emergencyRequests')
          .doc(requestId)
          .collection('acceptedDonors')
          .doc(donorId)
          .delete();
    } catch (e) {
      debugPrint('EmergencyRequestsRepository.cancelDispatch error: $e');
      rethrow;
    }
  }

  /// Mark request as fulfilled
  Future<void> fulfillRequest(String requestId) async {
    if (_firestore == null) return;
    try {
      await _firestore.collection('emergencyRequests').doc(requestId).update({
        'status': RequestStatus.fulfilled.name,
      });
    } catch (e) {
      debugPrint('EmergencyRequestsRepository.fulfillRequest error: $e');
      rethrow;
    }
  }
}
