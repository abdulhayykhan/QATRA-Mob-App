import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatra_app/core/models/blood_models.dart';
import 'package:qatra_app/core/models/user_models.dart';
import 'package:qatra_app/core/services/drives_repository.dart';
import 'package:qatra_app/core/services/emergency_requests_repository.dart';
import 'package:qatra_app/core/services/location_service.dart';
import 'package:qatra_app/core/services/supabase_service.dart';
import 'package:qatra_app/core/services/verification_repository.dart';
import 'package:qatra_app/core/utils/cnic_validator.dart';
import 'package:qatra_app/core/utils/distance_calculator.dart';
import 'package:qatra_app/providers/app_state_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Blood Compatibility Tests', () {
    test('O- Negative is Universal Donor', () {
      expect(BloodGroup.oNegative.compatibleRecipients.length, equals(8));
      for (final group in BloodGroup.values) {
        expect(BloodGroup.oNegative.canDonateTo(group), isTrue);
      }
    });

    test('AB+ Positive is Universal Recipient', () {
      expect(BloodGroup.abPositive.compatibleDonors.length, equals(8));
      expect(BloodGroup.abPositive.canDonateTo(BloodGroup.oPositive), isFalse);
      expect(BloodGroup.abPositive.canDonateTo(BloodGroup.abPositive), isTrue);
    });

    test('B+ Positive Compatibility', () {
      expect(BloodGroup.bPositive.canDonateTo(BloodGroup.bPositive), isTrue);
      expect(BloodGroup.bPositive.canDonateTo(BloodGroup.abPositive), isTrue);
      expect(BloodGroup.bPositive.canDonateTo(BloodGroup.aPositive), isFalse);
      expect(BloodGroup.bPositive.canDonateTo(BloodGroup.oPositive), isFalse);
    });
  });

  group('Pakistani CNIC Validation & Masking Tests', () {
    test('Validates 13-digit formatted CNIC', () {
      expect(CnicValidator.isValid('42101-1234567-1'), isTrue);
      expect(CnicValidator.isValid('4210112345671'), isTrue);
    });

    test('Rejects invalid CNIC formats', () {
      expect(CnicValidator.isValid('12345'), isFalse);
      expect(CnicValidator.isValid(''), isFalse);
      expect(CnicValidator.isValid(null), isFalse);
      expect(CnicValidator.isValid('42101-abc4567-1'), isFalse);
    });

    test('Masks CNIC for public privacy', () {
      final masked = CnicValidator.maskCnic('42101-1234567-1');
      expect(masked, equals('42101-XXXXXXX-1'));
    });
  });

  group('Haversine Distance & ETA Tests', () {
    test('Computes realistic distance in Karachi', () {
      // JPMC (24.8532, 67.0458) to Civil Hospital (24.8596, 67.0101)
      final dist = DistanceCalculator.calculateDistanceKm(
        lat1: 24.8532,
        lon1: 67.0458,
        lat2: 24.8596,
        lon2: 67.0101,
      );
      expect(dist, greaterThan(3.0));
      expect(dist, lessThan(5.0));

      final eta = DistanceCalculator.estimateEtaMinutes(dist);
      expect(eta, greaterThan(10));
      expect(eta, lessThan(20));
    });

    test('Formats distances under 1km in meters and >= 1km in kilometers', () {
      expect(DistanceCalculator.formatDistance(0.45), equals('450 m'));
      expect(DistanceCalculator.formatDistance(0.05), equals('50 m'));
      expect(DistanceCalculator.formatDistance(1.23), equals('1.2 km'));
      expect(DistanceCalculator.formatDistance(10.0), equals('10.0 km'));
    });
  });

  group('Donor Cooldown & Eligibility Boundaries Tests', () {
    test('Zero days remaining means not on cooldown and eligible', () {
      final user = UserProfile(
        id: 'u-1',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: '+92 300 0000000',
        bloodGroup: BloodGroup.oPositive,
        district: 'Karachi South',
        cooldownDaysRemaining: 0,
      );
      expect(user.isOnCooldown, isFalse);
    });

    test('Positive days remaining activates cooldown state', () {
      final user = UserProfile(
        id: 'u-2',
        fullName: 'Cooldown User',
        email: 'cooldown@example.com',
        phone: '+92 300 0000000',
        bloodGroup: BloodGroup.oPositive,
        district: 'Karachi South',
        cooldownDaysRemaining: 74,
      );
      expect(user.isOnCooldown, isTrue);
      expect(user.cooldownDaysRemaining, equals(74));
    });
  });

  group('Production Default User State Tests', () {
    test('New user starts unverified with zero lives saved and paused availability', () {
      final user = UserProfile(
        id: 'usr-new',
        fullName: 'New User',
        email: 'new@qatra.pk',
        phone: '+92 300 1112233',
        bloodGroup: BloodGroup.aPositive,
        district: 'Karachi East',
      );
      expect(user.isCnicVerified, isFalse);
      expect(user.isAvailableToDonate, isFalse);
      expect(user.livesSaved, equals(0));
      expect(user.cooldownDaysRemaining, equals(0));
      expect(user.isOnCooldown, isFalse);
    });
  });

  group('Proximity Radius & Blood Request Matching Tests', () {
    test('Identifies hospitals within concentric radius zones', () {
      // User at DUET / Jamshed Town (24.8722, 67.0435)
      const userLat = 24.8722;
      const userLng = 67.0435;

      // JPMC (24.8532, 67.0458) is ~2.1 km away
      final jpmcDist = DistanceCalculator.calculateDistanceKm(
        lat1: userLat,
        lon1: userLng,
        lat2: 24.8532,
        lon2: 67.0458,
      );
      expect(jpmcDist, lessThan(5.0)); // Within 5km zone

      // Indus Hospital (24.8322, 67.1264) is ~9.5 km away
      final indusDist = DistanceCalculator.calculateDistanceKm(
        lat1: userLat,
        lon1: userLng,
        lat2: 24.8322,
        lon2: 67.1264,
      );
      expect(indusDist, greaterThan(5.0));
      expect(indusDist, lessThan(15.0)); // Within 10-15km zone
    });

    test('Emergency request correctly matches compatible donors', () {
      final request = EmergencyRequest(
        id: 'REQ-TEST-1',
        seekerId: 's-1',
        seekerName: 'Test Seeker',
        bloodGroup: BloodGroup.bPositive,
        component: BloodComponent.prbc,
        unitsRequired: 2,
        hospital: Hospital.karachiHospitals.first,
        urgency: UrgencyLevel.high,
        deskReviewStatus: 'Submitted for Verification Desk Review',
        createdAt: DateTime.now(),
      );

      // B+ can receive from O-, O+, B-, B+
      expect(BloodGroup.oNegative.canDonateTo(request.bloodGroup), isTrue);
      expect(BloodGroup.oPositive.canDonateTo(request.bloodGroup), isTrue);
      expect(BloodGroup.bPositive.canDonateTo(request.bloodGroup), isTrue);
      expect(BloodGroup.aPositive.canDonateTo(request.bloodGroup), isFalse);
      expect(BloodGroup.abPositive.canDonateTo(request.bloodGroup), isFalse);
    });
  });

  group('Health Pre-Screening Eligibility Tests', () {
    test('Valid donor passes all criteria', () {
      const checklist = HealthChecklist(
        isAgeValid: true,
        isWeightValid: true,
        hasRecentIllness: false,
        hasRecentTattooOrSurgery: false,
        hemoglobinLevel: 13.5,
      );
      expect(checklist.isEligible, isTrue);
    });

    test('Recent illness triggers 14-day hold', () {
      const checklist = HealthChecklist(
        hasRecentIllness: true,
      );
      expect(checklist.isEligible, isFalse);
      expect(checklist.eligibilityFeedback, contains('14-day hold'));
    });

    test('Underweight soft-disqualifies donor', () {
      const checklist = HealthChecklist(
        isWeightValid: false,
      );
      expect(checklist.isEligible, isFalse);
      expect(checklist.eligibilityFeedback, contains('50 kg'));
    });
  });

  group('Firestore Model Serialization & Deserialization Tests', () {
    test('UserProfile serializes to map and deserializes correctly', () {
      final original = UserProfile(
        id: 'usr-abc-123',
        fullName: 'Fatima Ali',
        email: 'fatima@duet.edu.pk',
        phone: '+92 300 9876543',
        bloodGroup: BloodGroup.aPositive,
        district: 'Karachi Central',
        cnic: '42101-9988776-3',
        isCnicVerified: true,
        isAvailableToDonate: true,
        livesSaved: 3,
        cooldownDaysRemaining: 0,
        role: UserRole.donor,
        currentLat: 24.8935,
        currentLng: 67.0702,
      );

      final map = original.toMap();
      expect(map['id'], equals('usr-abc-123'));
      expect(map['fullName'], equals('Fatima Ali'));
      expect(map['bloodGroup'], equals('A+'));
      expect(map['isCnicVerified'], isTrue);

      final reconstructed = UserProfile.fromMap(map, 'usr-abc-123');
      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.fullName, equals(original.fullName));
      expect(reconstructed.email, equals(original.email));
      expect(reconstructed.phone, equals(original.phone));
      expect(reconstructed.bloodGroup, equals(original.bloodGroup));
      expect(reconstructed.district, equals(original.district));
      expect(reconstructed.cnic, equals(original.cnic));
      expect(reconstructed.isCnicVerified, equals(original.isCnicVerified));
      expect(reconstructed.isAvailableToDonate, equals(original.isAvailableToDonate));
      expect(reconstructed.livesSaved, equals(3));
      expect(reconstructed.role, equals(UserRole.donor));
    });

    test('Hospital serializes to map and deserializes correctly', () {
      final hosp = Hospital.karachiHospitals[0];
      final map = hosp.toMap();

      expect(map['name'], contains('JPMC'));
      expect(map['latitude'], equals(hosp.latitude));
      expect(map['longitude'], equals(hosp.longitude));

      final reconstructed = Hospital.fromMap(map);
      expect(reconstructed.id, equals(hosp.id));
      expect(reconstructed.name, equals(hosp.name));
      expect(reconstructed.emergencyPhone, equals(hosp.emergencyPhone));
    });

    test('MatchedDonor serializes and deserializes correctly', () {
      final donor = MatchedDonor(
        id: 'dnr-99',
        donorName: 'Kamran Khan',
        bloodGroup: BloodGroup.oNegative,
        distanceKm: 3.4,
        etaMinutes: 15,
        status: 'Accepted Dispatch',
        phoneNumber: '+92 312 3456789',
      );

      final map = donor.toMap();
      expect(map['id'], equals('dnr-99'));
      expect(map['phoneNumber'], equals('+92 312 3456789'));

      final reconstructed = MatchedDonor.fromMap(map);
      expect(reconstructed.id, equals(donor.id));
      expect(reconstructed.donorName, equals(donor.donorName));
      expect(reconstructed.bloodGroup, equals(donor.bloodGroup));
      expect(reconstructed.phoneNumber, equals(donor.phoneNumber));
    });

    test('EmergencyRequest full serialization round-trip', () {
      final now = DateTime.now();
      final request = EmergencyRequest(
        id: 'REQ-SERIAL-1',
        seekerId: 'seeker-99',
        seekerName: 'Hassan Raza',
        bloodGroup: BloodGroup.bNegative,
        component: BloodComponent.platelets,
        unitsRequired: 3,
        unitsFulfilled: 1,
        hospital: Hospital.karachiHospitals[1],
        urgency: UrgencyLevel.high,
        patientMrn: 'MRN-9901',
        doctorStamp: 'Trauma Consultant Approved',
        deskReviewStatus: 'Submitted for Verification Desk Review',
        status: RequestStatus.matched,
        broadcastRadiusKm: 15,
        createdAt: now,
        activeDonorsInRadius: 20,
        matchedDonors: [
          MatchedDonor(
            id: 'donor-1',
            donorName: 'Ali Raza',
            bloodGroup: BloodGroup.bNegative,
            distanceKm: 2.1,
            etaMinutes: 10,
            status: 'Accepted Dispatch',
            phoneNumber: '+92 300 1122334',
          ),
        ],
      );

      final map = request.toMap();
      expect(map['id'], equals('REQ-SERIAL-1'));
      expect(map['seekerId'], equals('seeker-99'));
      expect(map['bloodGroup'], equals('B-'));
      expect(map['matchedDonors'], hasLength(1));

      final reconstructed = EmergencyRequest.fromMap(map, 'REQ-SERIAL-1');
      expect(reconstructed.id, equals(request.id));
      expect(reconstructed.seekerName, equals(request.seekerName));
      expect(reconstructed.bloodGroup, equals(BloodGroup.bNegative));
      expect(reconstructed.component, equals(BloodComponent.platelets));
      expect(reconstructed.hospital.name, equals(Hospital.karachiHospitals[1].name));
      expect(reconstructed.matchedDonors, hasLength(1));
      expect(reconstructed.matchedDonors.first.phoneNumber, equals('+92 300 1122334'));
    });
  });

  group('Campus Drives & Repository Tests', () {
    test('DriveEvent serializes and deserializes correctly', () {
      final drive = DriveEvent(
        id: 'test-drive-1',
        title: 'DUET Blood Camp',
        organizer: 'Alkhidmat Youth',
        universityCampus: 'DUET Karachi',
        venue: 'Gymnasium',
        date: DateTime(2026, 9, 15, 10, 0),
        time: '10:00 AM - 4:00 PM',
        targetUnits: 120,
        registeredDonors: 85,
        registeredVolunteers: 20,
        description: 'Testing campus drive event serialization',
      );

      final map = drive.toMap();
      expect(map['id'], equals('test-drive-1'));
      expect(map['universityCampus'], equals('DUET Karachi'));
      expect(map['targetUnits'], equals(120));

      final reconstructed = DriveEvent.fromMap(map, 'test-drive-1');
      expect(reconstructed.id, equals(drive.id));
      expect(reconstructed.title, equals(drive.title));
      expect(reconstructed.organizer, equals(drive.organizer));
      expect(reconstructed.universityCampus, equals(drive.universityCampus));
      expect(reconstructed.targetUnits, equals(drive.targetUnits));
      expect(reconstructed.registeredDonors, equals(drive.registeredDonors));
    });

    test('Seed drives list contains DUET, NED, and KU', () {
      final seeds = DriveEvent.seedDrives;
      expect(seeds.length, greaterThanOrEqualTo(3));
      expect(seeds.any((d) => d.universityCampus.contains('DUET')), isTrue);
      expect(seeds.any((d) => d.universityCampus.contains('NED')), isTrue);
      expect(seeds.any((d) => d.universityCampus.contains('KU')), isTrue);
    });

    test('Seed emergency requests list is non-empty and well-formed', () {
      final seeds = EmergencyRequest.seedRequests;
      expect(seeds.length, greaterThanOrEqualTo(3));
      for (final req in seeds) {
        expect(req.id, isNotEmpty);
        expect(req.hospital.name, isNotEmpty);
        expect(req.unitsRequired, greaterThan(0));
      }
    });

    test('DrivesRepository offline fallback safe execution', () async {
      final repo = DrivesRepository(firestore: null);
      expect(repo.isFirebaseAvailable, isFalse);

      final stream = repo.getUpcomingDrivesStream();
      expect(await stream.isEmpty, isTrue);

      await expectLater(
        repo.createDrive(DriveEvent.seedDrives.first),
        completes,
      );
    });

    test('EmergencyRequestsRepository offline fallback safe execution', () async {
      final repo = EmergencyRequestsRepository(firestore: null);
      expect(repo.isFirebaseAvailable, isFalse);

      final activeStream = repo.getActiveRequestsStream();
      expect(await activeStream.isEmpty, isTrue);

      final singleStream = repo.getRequestStream('dummy-id');
      expect(await singleStream.isEmpty, isTrue);

      final donorsStream = repo.getAcceptedDonorsStream('dummy-id');
      expect(await donorsStream.isEmpty, isTrue);

      await expectLater(
        repo.createRequest(EmergencyRequest.seedRequests.first),
        completes,
      );
      await expectLater(
        repo.acceptDispatch(
          requestId: 'dummy-id',
          donor: EmergencyRequest.seedRequests.first.matchedDonors.first,
        ),
        completes,
      );
      await expectLater(
        repo.cancelDispatch(
          requestId: 'dummy-id',
          donorId: 'donor-me',
        ),
        completes,
      );
      await expectLater(
        repo.fulfillRequest('dummy-id'),
        completes,
      );
    });

    test('MatchedDonor subcollection serialization and document ID binding', () {
      final donorData = {
        'donorName': 'Tariq Mehmood',
        'bloodGroup': 'A+',
        'distanceKm': 3.7,
        'etaMinutes': 14,
        'status': 'Accepted Dispatch',
        'phoneNumber': '+92 321 9876543',
      };

      // When mapped from subcollection document where doc.id is the donor UID
      const docId = 'user-auth-uid-456';
      final donor = MatchedDonor.fromMap(donorData, docId);

      expect(donor.id, equals(docId));
      expect(donor.donorName, equals('Tariq Mehmood'));
      expect(donor.bloodGroup, equals(BloodGroup.aPositive));
      expect(donor.distanceKm, equals(3.7));
      expect(donor.etaMinutes, equals(14));
      expect(donor.phoneNumber, equals('+92 321 9876543'));

      final serialized = donor.toMap();
      expect(serialized['id'], equals(docId));
      expect(serialized['donorName'], equals('Tariq Mehmood'));
      expect(serialized['bloodGroup'], equals('A+'));
      expect(serialized['phoneNumber'], equals('+92 321 9876543'));
    });
  });

  group('Demo Mode vs Live Stream Trust & Safety Tests', () {
    test('Default mode does NOT inject seed requests when stream is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isDemoModeProvider), isFalse);
      final requests = container.read(activeEmergencyRequestsProvider);
      expect(requests, isEmpty);
    });

    test('Demo mode explicitly toggles seed requests', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(isDemoModeProvider.notifier).state = true;
      expect(container.read(isDemoModeProvider), isTrue);

      final requests = container.read(activeEmergencyRequestsProvider);
      expect(requests, isNotEmpty);
      expect(requests.length, equals(EmergencyRequest.seedRequests.length));
    });

    test('Default mode does NOT inject seed drives when stream is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isDemoModeProvider), isFalse);
      final drives = container.read(campusDrivesProvider);
      expect(drives, isEmpty);
    });

    test('Demo mode explicitly toggles seed drives', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(isDemoModeProvider.notifier).state = true;
      final drives = container.read(campusDrivesProvider);
      expect(drives, isNotEmpty);
      expect(drives.length, equals(DriveEvent.seedDrives.length));
    });
  });

  group('LocationService & Geolocation Tests', () {
    test('Default Karachi coordinates constant validation', () {
      expect(LocationService.defaultKarachiLat, closeTo(24.8607, 0.0001));
      expect(LocationService.defaultKarachiLng, closeTo(67.0011, 0.0001));
    });

    test('LocationService fallback returns Karachi center when platform channel is uninitialized', () async {
      final service = LocationService();
      // In flutter_test headless environment without native mocking, getCurrentPosition catches platform exception and safely falls back
      final coords = await service.getCoordinatesWithFallback();
      expect(coords.lat, closeTo(LocationService.defaultKarachiLat, 0.0001));
      expect(coords.lng, closeTo(LocationService.defaultKarachiLng, 0.0001));
    });

    test('UserNotifier.updateLocation updates user state coordinates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProvider.notifier);
      notifier.updateLocation(24.9056, 67.0822); // Gulshan-e-Iqbal

      final updatedUser = container.read(userProvider);
      expect(updatedUser.currentLat, equals(24.9056));
      expect(updatedUser.currentLng, equals(67.0822));
    });

    test('UserNotifier.refreshLiveLocation integrates with LocationService fallback', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(locationServiceProvider);
      final notifier = container.read(userProvider.notifier);

      await notifier.refreshLiveLocation(service);

      final updatedUser = container.read(userProvider);
      expect(updatedUser.currentLat, closeTo(LocationService.defaultKarachiLat, 0.0001));
      expect(updatedUser.currentLng, closeTo(LocationService.defaultKarachiLng, 0.0001));
    });
  });

  group('DriveEvent and DrivesRepository Tests', () {
    test('Serializes and deserializes organizerId correctly', () {
      final drive = DriveEvent(
        id: 'drv-99',
        title: 'Tech Campus Drive',
        organizer: 'Tech Society',
        organizerId: 'usr-organizer-123',
        universityCampus: 'Fast NUCES',
        venue: 'Main Auditorium',
        date: DateTime(2026, 5, 20),
        time: '10:00 AM - 04:00 PM',
        targetUnits: 120,
        registeredDonors: 45,
        registeredVolunteers: 12,
        description: 'Test blood drive description',
      );

      final map = drive.toMap();
      expect(map['organizerId'], equals('usr-organizer-123'));

      final reconstructed = DriveEvent.fromMap(map, 'drv-99');
      expect(reconstructed.organizerId, equals('usr-organizer-123'));
      expect(reconstructed.title, equals('Tech Campus Drive'));
    });

    test('DrivesRepository fallback when Firebase is not initialized', () async {
      final repo = DrivesRepository();
      expect(repo.isFirebaseAvailable, isFalse);

      final stream = repo.getUpcomingDrivesStream();
      final items = await stream.toList();
      expect(items, isEmpty);

      // Verify createDrive, updateDrive, deleteDrive do not throw when offline
      final drive = DriveEvent.seedDrives.first;
      await expectLater(repo.createDrive(drive), completes);
      await expectLater(repo.updateDrive(drive), completes);
      await expectLater(repo.deleteDrive(drive.id), completes);
    });
  });

  group('VerificationSlip and VerificationRepository Tests', () {
    test('Serializes and deserializes VerificationSlip correctly', () {
      final slip = VerificationSlip(
        id: 'REQ-1234',
        seekerId: 'seeker-user-456',
        hospital: 'Aga Khan University Hospital',
        doctorStamp: 'Trauma Consultant Stamp (Approved)',
        mrn: 'MRN-99881',
        bloodGroup: BloodGroup.oNegative,
        units: '2 Bags',
        deskReviewStatus: 'Submitted for Verification Desk Review',
        flagged: false,
        createdAt: DateTime(2026, 3, 10, 14, 30),
      );

      final map = slip.toMap();
      expect(map['id'], equals('REQ-1234'));
      expect(map['seekerId'], equals('seeker-user-456'));
      expect(map['hospital'], equals('Aga Khan University Hospital'));
      expect(map['bloodGroup'], equals('O-'));
      expect(map['units'], equals('2 Bags'));
      expect(map['deskReviewStatus'], equals('Submitted for Verification Desk Review'));
      expect(map['flagged'], isFalse);

      final reconstructed = VerificationSlip.fromMap(map, 'REQ-1234');
      expect(reconstructed.id, equals('REQ-1234'));
      expect(reconstructed.seekerId, equals('seeker-user-456'));
      expect(reconstructed.bloodGroup, equals(BloodGroup.oNegative));
      expect(reconstructed.flagged, isFalse);
    });

    test('VerificationSlip seed data is well-formed', () {
      expect(VerificationSlip.seedSlips, isNotEmpty);
      for (final slip in VerificationSlip.seedSlips) {
        expect(slip.id, startsWith('REQ-'));
        expect(slip.seekerId, isNotEmpty);
        expect(slip.hospital, isNotEmpty);
        expect(slip.doctorStamp, isNotEmpty);
      }
    });

    test('VerificationRepository fallback when Firebase is not initialized', () async {
      final repo = VerificationRepository();
      expect(repo.isFirebaseAvailable, isFalse);

      final stream = repo.getPendingSlipsStream();
      final items = await stream.toList();
      expect(items, isEmpty);

      final slip = VerificationSlip.seedSlips.first;
      await expectLater(repo.submitSlip(slip), completes);
      await expectLater(repo.approveSlip(slip.id), completes);
      await expectLater(repo.rejectSlip(slip.id, 'Test rejection reason'), completes);
    });

    test('Default mode does NOT inject seed verification slips', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isDemoModeProvider), isFalse);
      final slips = container.read(pendingVerificationSlipsProvider);
      expect(slips, isEmpty);
    });

    test('Demo mode explicitly toggles seed verification slips', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(isDemoModeProvider.notifier).state = true;
      final slips = container.read(pendingVerificationSlipsProvider);
      expect(slips, isNotEmpty);
      expect(slips.length, equals(VerificationSlip.seedSlips.length));
    });
  });

  group('UserNotifier Production Guest & Auth Tests', () {
    test('Default unauthenticated state is clean guest without hardcoded personal info', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final user = container.read(userProvider);
      expect(user.role, equals(UserRole.guest));
      expect(user.id, isEmpty);
      expect(user.fullName, isEmpty);
      expect(user.phone, isEmpty);
      expect(user.email, isEmpty);
      expect(user.isCnicVerified, isFalse);
      expect(user.isAvailableToDonate, isFalse);
      expect(user.livesSaved, equals(0));
    });

    test('Sign out resets state to guest', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProvider.notifier);
      notifier.switchRole(UserRole.donor);
      expect(container.read(userProvider).role, equals(UserRole.donor));

      await notifier.signOut();
      final user = container.read(userProvider);
      expect(user.role, equals(UserRole.guest));
      expect(user.fullName, isEmpty);
      expect(user.isCnicVerified, isFalse);
    });

    test('CNIC verification keeps isCnicVerified false until desk staff review', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProvider.notifier);
      notifier.verifyCnic('42101-1234567-1');

      final user = container.read(userProvider);
      expect(user.cnic, equals('42101-1234567-1'));
      expect(user.isCnicVerified, isFalse);
    });

    test('Updating profile preserves unverified CNIC status without self-elevation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(userProvider.notifier);
      notifier.updateProfile(
        fullName: 'Zainab Bibi',
        phone: '0300-9999999',
        bloodGroup: BloodGroup.bNegative,
        district: 'Karachi South',
        cnic: '42201-1111111-1',
      );

      final user = container.read(userProvider);
      expect(user.fullName, equals('Zainab Bibi'));
      expect(user.phone, equals('0300-9999999'));
      expect(user.bloodGroup, equals(BloodGroup.bNegative));
      expect(user.district, equals('Karachi South'));
      expect(user.cnic, equals('42201-1111111-1'));
      expect(user.isCnicVerified, isFalse);
    });
  });

  group('Dynamic 90-Day Donation Cooldown Tests', () {
    test('Calculates remaining days dynamically from lastDonationDate', () {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final user = UserProfile(
        id: 'u-cool',
        fullName: 'Donor User',
        email: 'donor@qatra.pk',
        phone: '0300-1111111',
        bloodGroup: BloodGroup.oPositive,
        district: 'Karachi Central',
        lastDonationDate: thirtyDaysAgo,
      );

      expect(user.effectiveCooldownDaysRemaining, inInclusiveRange(59, 61));
      expect(user.isOnCooldown, isTrue);
    });

    test('Cooldown dynamically clears to 0 after 90 days', () {
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));

      final user = UserProfile(
        id: 'u-ready',
        fullName: 'Ready Donor',
        email: 'ready@qatra.pk',
        phone: '0300-2222222',
        bloodGroup: BloodGroup.oPositive,
        district: 'Karachi Central',
        lastDonationDate: ninetyDaysAgo,
      );

      expect(user.effectiveCooldownDaysRemaining, equals(0));
      expect(user.isOnCooldown, isFalse);
    });

    test('Cooldown dynamically clears when more than 90 days have elapsed', () {
      final now = DateTime.now();
      final hundredDaysAgo = now.subtract(const Duration(days: 100));

      final user = UserProfile(
        id: 'u-past',
        fullName: 'Past Donor',
        email: 'past@qatra.pk',
        phone: '0300-3333333',
        bloodGroup: BloodGroup.oPositive,
        district: 'Karachi Central',
        lastDonationDate: hundredDaysAgo,
      );

      expect(user.effectiveCooldownDaysRemaining, equals(0));
      expect(user.isOnCooldown, isFalse);
    });

    test('Falls back to manual cooldownDaysRemaining if lastDonationDate is null', () {
      final user = UserProfile(
        id: 'u-manual',
        fullName: 'Manual Cooldown',
        email: 'manual@qatra.pk',
        phone: '0300-4444444',
        bloodGroup: BloodGroup.oPositive,
        district: 'Karachi Central',
        cooldownDaysRemaining: 45,
      );

      expect(user.effectiveCooldownDaysRemaining, equals(45));
      expect(user.isOnCooldown, isTrue);
    });
  });

  group('External Communication & Routing Intent URI Generation Tests', () {
    test('Formats WhatsApp emergency broadcast URL with encoded details', () {
      final hospital = Hospital.karachiHospitals.first;
      final req = EmergencyRequest(
        id: 'REQ-101',
        seekerId: 'seeker-101',
        seekerName: 'Hassan Raza',
        hospital: hospital,
        bloodGroup: BloodGroup.abNegative,
        component: BloodComponent.platelets,
        unitsRequired: 3,
        urgency: UrgencyLevel.high,
        createdAt: DateTime(2026, 3, 17, 10, 0),
        broadcastRadiusKm: 10,
        status: RequestStatus.broadcasting,
      );

      final message = '''
🚨 *URGENT BLOOD REQUISITION — QATRA* 🚨
Blood Group: *${req.bloodGroup.label}* (${req.component.label})
Required Units: *${req.unitsRequired}*
Urgency: *${req.urgency.description}*
Hospital: *${req.hospital.name}*
Address: ${req.hospital.address}
Status: *Verified by Alkhidmat Verification Desk* (REQ #${req.id})

If you can donate or know someone who can, please respond via QATRA Emergency Blood Response or contact the desk immediately.
'''.trim();

      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
      expect(uri.scheme, equals('https'));
      expect(uri.host, equals('wa.me'));
      expect(uri.queryParameters['text'], contains('URGENT BLOOD REQUISITION'));
      expect(uri.queryParameters['text'], contains('AB-'));
      expect(uri.queryParameters['text'], contains(hospital.name));
      expect(uri.queryParameters['text'], contains('REQ-101'));
    });

    test('Formats Google Maps turn-by-turn navigation destination URL', () {
      final hospital = Hospital.karachiHospitals.first;
      final navUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
      );

      expect(navUri.scheme, equals('https'));
      expect(navUri.host, equals('www.google.com'));
      expect(navUri.path, equals('/maps/dir/'));
      expect(navUri.queryParameters['api'], equals('1'));
      expect(navUri.queryParameters['destination'], equals('${hospital.latitude},${hospital.longitude}'));
    });

    test('Formats Alkhidmat Emergency Helpline tel URI', () {
      final helplineUri = Uri.parse('tel:1021');
      expect(helplineUri.scheme, equals('tel'));
      expect(helplineUri.path, equals('1021'));
    });
  });

  group('Supabase Hybrid PostgreSQL Integration Tests', () {
    test('SupabaseService constants and endpoints are properly configured', () {
      expect(SupabaseService.supabaseUrl, equals('https://talimcuofkvphkvreryo.supabase.co'));
      expect(SupabaseService.supabaseAnonKey.startsWith('eyJ'), isTrue);
    });

    test('SupabaseService handles uninitialized or offline state safely without throwing', () async {
      // In offline/unit test sandbox, client access should be null-safe
      final client = SupabaseService.client;
      // If uninitialized, client should be null and not throw
      if (!SupabaseService.isInitialized) {
        expect(client, isNull);
      }

      // recordRequestAudit and recordFraudAudit should safely no-op when client is null
      await expectLater(
        SupabaseService.recordRequestAudit(
          requestId: 'REQ-AUDIT-TEST',
          seekerId: 'seeker-1',
          seekerName: 'Test Seeker',
          hospitalId: 'HOSP-1',
          bloodGroup: 'B+',
          component: 'PRBC',
          units: 2,
          urgency: 'Immediate',
        ),
        completes,
      );

      await expectLater(
        SupabaseService.recordFraudAudit(
          requestId: 'REQ-AUDIT-TEST',
          cnic: '42101-1234567-1',
          phone: '03001234567',
          mrn: 'MRN-999',
          reason: 'Test fraud detection pattern',
          confidence: 'High',
        ),
        completes,
      );
    });
  });
}



