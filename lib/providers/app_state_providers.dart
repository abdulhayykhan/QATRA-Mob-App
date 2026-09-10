import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/blood_models.dart';
import '../core/models/user_models.dart';
import '../core/services/auth_repository.dart';
import '../core/services/drives_repository.dart';
import '../core/services/emergency_requests_repository.dart';
import '../core/services/location_service.dart';
import '../core/services/verification_repository.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final emergencyRequestsRepositoryProvider = Provider<EmergencyRequestsRepository>((ref) {
  return EmergencyRequestsRepository();
});

final activeEmergencyRequestsStreamProvider = StreamProvider<List<EmergencyRequest>>((ref) {
  final repo = ref.watch(emergencyRequestsRepositoryProvider);
  return repo.getActiveRequestsStream();
});

/// Explicit Demo Mode flag (defaults to false for production safety).
/// When false, only real live data from Firestore is shown (or an honest empty state).
/// When true, displays simulated seed requests and campus drives with a visible DEMO badge.
final isDemoModeProvider = StateProvider<bool>((ref) => false);

/// Synchronous convenience provider reading active requests stream.
/// Strictly honors isDemoModeProvider: never silently serves fake emergencies in production.
final activeEmergencyRequestsProvider = Provider<List<EmergencyRequest>>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  if (isDemoMode) {
    return EmergencyRequest.seedRequests;
  }
  final asyncVal = ref.watch(activeEmergencyRequestsStreamProvider);
  return asyncVal.value ?? const [];
});

final activeEmergencyRequestsLoadingProvider = Provider<bool>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  if (isDemoMode) return false;
  return ref.watch(activeEmergencyRequestsStreamProvider).isLoading;
});

final drivesRepositoryProvider = Provider<DrivesRepository>((ref) {
  return DrivesRepository();
});

final campusDrivesStreamProvider = StreamProvider<List<DriveEvent>>((ref) {
  final repo = ref.watch(drivesRepositoryProvider);
  return repo.getUpcomingDrivesStream();
});

final verificationRepositoryProvider = Provider<VerificationRepository>((ref) {
  return VerificationRepository();
});

final pendingVerificationSlipsStreamProvider = StreamProvider<List<VerificationSlip>>((ref) {
  final repo = ref.watch(verificationRepositoryProvider);
  return repo.getPendingSlipsStream();
});

// Current User State Provider
class UserNotifier extends StateNotifier<UserProfile> {
  final AuthRepository? _authRepository;

  UserNotifier({AuthRepository? authRepository})
      : _authRepository = authRepository,
        super(UserProfile(
          id: 'usr-default',
          fullName: 'Abdul Hayy Khan',
          email: 'abdulhayy.khan@duet.edu.pk',
          phone: '+92 300 1234567',
          bloodGroup: BloodGroup.oNegative,
          district: 'Karachi South',
          cnic: '42101-1234567-1',
          isCnicVerified: false,
          isAvailableToDonate: false,
          cooldownDaysRemaining: 0,
          livesSaved: 0,
          role: UserRole.donor,
          currentLat: 24.8607,
          currentLng: 67.0011,
        ));

  Future<bool> signInWithGoogle({required UserRole initialRole}) async {
    if (_authRepository == null) return false;
    try {
      final profile = await _authRepository.signInWithGoogle(initialRole: initialRole);
      if (profile != null) {
        state = profile;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void loginWithGoogle({
    required String email,
    required String fullName,
    required UserRole role,
  }) {
    state = state.copyWith(
      email: email,
      fullName: fullName,
      role: role,
    );
    _syncToFirestore();
  }

  void switchRole(UserRole newRole) {
    state = state.copyWith(role: newRole);
    _syncToFirestore();
  }

  void toggleAvailable(bool value) {
    state = state.copyWith(isAvailableToDonate: value);
    _syncToFirestore();
  }

  void verifyCnic(String cnic) {
    state = state.copyWith(
      cnic: cnic,
      isCnicVerified: true,
    );
    if (_authRepository != null && state.id.isNotEmpty) {
      _authRepository.updateCnic(uid: state.id, cnic: cnic);
    }
  }

  void updateProfile({
    required String fullName,
    required BloodGroup bloodGroup,
    required String district,
    String? cnic,
  }) {
    state = state.copyWith(
      fullName: fullName,
      bloodGroup: bloodGroup,
      district: district,
      cnic: cnic,
      isCnicVerified: cnic != null && cnic.isNotEmpty,
    );
    _syncToFirestore();
  }

  void updateLocation(double lat, double lng) {
    state = state.copyWith(currentLat: lat, currentLng: lng);
    _syncToFirestore();
  }

  Future<void> refreshLiveLocation(LocationService locationService) async {
    final coords = await locationService.getCoordinatesWithFallback();
    state = state.copyWith(currentLat: coords.lat, currentLng: coords.lng);
    _syncToFirestore();
  }

  void _syncToFirestore() {
    if (_authRepository != null && state.id.isNotEmpty) {
      _authRepository.updateUserProfile(state);
    }
  }

  void completeDonation() {
    state = state.copyWith(
      livesSaved: state.livesSaved + 1,
      cooldownDaysRemaining: 90,
      isAvailableToDonate: false,
      lastDonationDate: DateTime.now(),
    );
    _syncToFirestore();
  }

  void resetCooldown() {
    state = state.copyWith(cooldownDaysRemaining: 0, isAvailableToDonate: true);
    _syncToFirestore();
  }

  void setMockCooldown(int days) {
    state = state.copyWith(
      cooldownDaysRemaining: days,
      isAvailableToDonate: days == 0,
    );
  }

  void loadDemoVerifiedDonor() {
    state = state.copyWith(
      isCnicVerified: true,
      isAvailableToDonate: true,
      livesSaved: 12,
    );
    _syncToFirestore();
  }

  void loadFreshUnverifiedUser() {
    state = state.copyWith(
      isCnicVerified: false,
      isAvailableToDonate: false,
      livesSaved: 0,
      cooldownDaysRemaining: 0,
    );
    _syncToFirestore();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return UserNotifier(authRepository: authRepo);
});



// Filter state for Social Feed
class FeedFilterState {
  final BloodGroup? bloodGroup;
  final UrgencyLevel? urgency;
  final double maxDistanceKm;

  const FeedFilterState({
    this.bloodGroup,
    this.urgency,
    this.maxDistanceKm = 15.0,
  });

  FeedFilterState copyWith({
    BloodGroup? bloodGroup,
    UrgencyLevel? urgency,
    double? maxDistanceKm,
    bool clearBloodGroup = false,
    bool clearUrgency = false,
  }) {
    return FeedFilterState(
      bloodGroup: clearBloodGroup ? null : (bloodGroup ?? this.bloodGroup),
      urgency: clearUrgency ? null : (urgency ?? this.urgency),
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }
}

final feedFilterProvider = StateProvider<FeedFilterState>((ref) {
  return const FeedFilterState();
});

// Campus Drives Provider
final campusDrivesProvider = Provider<List<DriveEvent>>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  if (isDemoMode) {
    return DriveEvent.seedDrives;
  }
  final asyncVal = ref.watch(campusDrivesStreamProvider);
  return asyncVal.value ?? const [];
});

// 24/7 Verification Desk Queue Provider
final pendingVerificationSlipsProvider = Provider<List<VerificationSlip>>((ref) {
  final isDemoMode = ref.watch(isDemoModeProvider);
  if (isDemoMode) {
    return VerificationSlip.seedSlips;
  }
  final asyncVal = ref.watch(pendingVerificationSlipsStreamProvider);
  return asyncVal.value ?? const [];
});

// Myth vs Fact Provider
final mythFactProvider = Provider<List<MythFact>>((ref) {
  return const [
    MythFact(
      id: 'mf-1',
      question: 'Does donating blood cause chronic weakness or decrease stamina?',
      answer: 'Myth! The human body replenishes fluid/plasma volume within 24–48 hours, and red blood cells within a few weeks. It does not cause long-term weakness.',
      isMyth: true,
      category: 'Health & Recovery',
    ),
    MythFact(
      id: 'mf-2',
      question: 'Can females safely donate blood?',
      answer: 'Fact! Absolutely. As long as hemoglobin levels are >= 12.5 g/dL, weight is >= 50 kg, and other standard criteria are met, females can safely donate.',
      isMyth: false,
      category: 'Gender & Myths',
    ),
    MythFact(
      id: 'mf-3',
      question: 'Can someone with high blood pressure donate blood?',
      answer: 'Fact! Yes, if your blood pressure is under control and within acceptable clinical limits (< 180/100 mmHg) at the time of screening.',
      isMyth: false,
      category: 'Eligibility',
    ),
    MythFact(
      id: 'mf-4',
      question: 'Can I contract an infection or disease while donating blood?',
      answer: 'Myth! A completely sterile, brand-new disposable needle and bag set is used for every single donor and discarded immediately. There is zero risk of contracting infections.',
      isMyth: true,
      category: 'Safety & Hygiene',
    ),
  ];
});
