import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/blood_models.dart';
import '../models/user_models.dart';

class AuthRepository {
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore? _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? (Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null),
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  Stream<User?> get authStateChanges =>
      _firebaseAuth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => _firebaseAuth?.currentUser;

  bool get isFirebaseAvailable => _firebaseAuth != null && _firestore != null;

  /// Signs in with Google and links/fetches the Firestore user document.
  /// If the user document does not exist, creates it with unverified defaults.
  Future<UserProfile?> signInWithGoogle({required UserRole initialRole}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Canceled by user
        return null;
      }

      if (_firebaseAuth != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null && _firestore != null) {
          final docRef = _firestore.collection('users').doc(user.uid);
          final docSnap = await docRef.get();

          if (docSnap.exists && docSnap.data() != null) {
            return UserProfile.fromMap(docSnap.data()!, docSnap.id);
          } else {
            // First time user: default unverified state as per PRD specifications
            final newProfile = UserProfile(
              id: user.uid,
              fullName: user.displayName ?? googleUser.displayName ?? 'QATRA Member',
              email: user.email ?? googleUser.email,
              phone: user.phoneNumber ?? '+92 300 1234567',
              bloodGroup: BloodGroup.oNegative,
              district: 'Karachi South',
              cnic: null,
              isCnicVerified: false,
              isAvailableToDonate: false,
              cooldownDaysRemaining: 0,
              livesSaved: 0,
              role: initialRole,
              currentLat: 24.8607,
              currentLng: 67.0011,
            );

            await docRef.set(newProfile.toMap());
            return newProfile;
          }
        }
      }

      // Fallback for demo / offline or test execution
      return UserProfile(
        id: googleUser.id,
        fullName: googleUser.displayName ?? 'QATRA Member',
        email: googleUser.email,
        phone: '+92 300 1234567',
        bloodGroup: BloodGroup.oNegative,
        district: 'Karachi South',
        cnic: null,
        isCnicVerified: false,
        isAvailableToDonate: false,
        cooldownDaysRemaining: 0,
        livesSaved: 0,
        role: initialRole,
        currentLat: 24.8607,
        currentLng: 67.0011,
      );
    } catch (e) {
      debugPrint('AuthRepository.signInWithGoogle error: $e');
      rethrow;
    }
  }

  /// Syncs updated profile to Firestore `users/{uid}`
  Future<void> updateUserProfile(UserProfile profile) async {
    if (_firestore != null && profile.id.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(profile.id).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('AuthRepository.updateUserProfile error: $e');
      }
    }
  }

  /// Updates CNIC for the user in Firestore `users/{uid}`
  Future<void> updateCnic({required String uid, required String cnic}) async {
    if (_firestore != null && uid.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'cnic': cnic,
          'isCnicVerified': true,
        });
      } catch (e) {
        debugPrint('AuthRepository.updateCnic error: $e');
      }
    }
  }

  /// Signs out from both Google and Firebase
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth?.signOut();
    } catch (e) {
      debugPrint('AuthRepository.signOut error: $e');
    }
  }
}
