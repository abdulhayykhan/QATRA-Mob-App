import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatra_app/core/models/blood_models.dart';
import 'package:qatra_app/core/models/user_models.dart';
import 'package:qatra_app/core/services/drives_repository.dart';
import 'package:qatra_app/core/services/emergency_requests_repository.dart';
import 'package:qatra_app/core/utils/cnic_validator.dart';
import 'package:qatra_app/core/utils/distance_calculator.dart';
import 'package:qatra_app/providers/app_state_providers.dart';

void main() {
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
}

