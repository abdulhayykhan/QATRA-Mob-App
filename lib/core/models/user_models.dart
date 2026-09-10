import 'blood_models.dart';

enum UserRole {
  guest('Guest / Unverified'),
  seeker('Emergency Seeker'),
  donor('Verified Donor'),
  driveOrganizer('Campus Drive Lead'),
  admin('24/7 Desk Admin');

  final String label;
  const UserRole(this.label);

  static UserRole fromString(String value) {
    final v = value.trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.name.toLowerCase() == v || role.label.toLowerCase() == v) {
        return role;
      }
    }
    return UserRole.donor;
  }
}

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final BloodGroup bloodGroup;
  final String district;
  final String? cnic;
  final bool isCnicVerified;
  final bool isAvailableToDonate;
  final DateTime? lastDonationDate;
  final int cooldownDaysRemaining;
  final int livesSaved;
  final UserRole role;
  final double currentLat;
  final double currentLng;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.bloodGroup,
    required this.district,
    this.cnic,
    this.isCnicVerified = false,
    this.isAvailableToDonate = false,
    this.lastDonationDate,
    this.cooldownDaysRemaining = 0,
    this.livesSaved = 0,
    this.role = UserRole.donor,
    this.currentLat = 24.8607,
    this.currentLng = 67.0011,
  });

  bool get isOnCooldown => cooldownDaysRemaining > 0;

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    BloodGroup? bloodGroup,
    String? district,
    String? cnic,
    bool? isCnicVerified,
    bool? isAvailableToDonate,
    DateTime? lastDonationDate,
    int? cooldownDaysRemaining,
    int? livesSaved,
    UserRole? role,
    double? currentLat,
    double? currentLng,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      district: district ?? this.district,
      cnic: cnic ?? this.cnic,
      isCnicVerified: isCnicVerified ?? this.isCnicVerified,
      isAvailableToDonate: isAvailableToDonate ?? this.isAvailableToDonate,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      cooldownDaysRemaining: cooldownDaysRemaining ?? this.cooldownDaysRemaining,
      livesSaved: livesSaved ?? this.livesSaved,
      role: role ?? this.role,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'bloodGroup': bloodGroup.label,
      'district': district,
      'cnic': cnic,
      'isCnicVerified': isCnicVerified,
      'isAvailableToDonate': isAvailableToDonate,
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'cooldownDaysRemaining': cooldownDaysRemaining,
      'livesSaved': livesSaved,
      'role': role.name,
      'currentLat': currentLat,
      'currentLng': currentLng,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, [String? id]) {
    BloodGroup parseBloodGroup(dynamic bg) {
      if (bg == null) return BloodGroup.oNegative;
      return BloodGroup.fromString(bg.toString());
    }

    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      if (d is String) return DateTime.tryParse(d);
      try {
        return (d as dynamic).toDate();
      } catch (_) {
        return null;
      }
    }

    return UserProfile(
      id: id ?? map['id'] ?? '',
      fullName: map['fullName'] ?? 'QATRA User',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bloodGroup: parseBloodGroup(map['bloodGroup']),
      district: map['district'] ?? 'Karachi South',
      cnic: map['cnic'],
      isCnicVerified: map['isCnicVerified'] ?? false,
      isAvailableToDonate: map['isAvailableToDonate'] ?? false,
      lastDonationDate: parseDate(map['lastDonationDate']),
      cooldownDaysRemaining: (map['cooldownDaysRemaining'] as num?)?.toInt() ?? 0,
      livesSaved: (map['livesSaved'] as num?)?.toInt() ?? 0,
      role: UserRole.fromString(map['role']?.toString() ?? 'donor'),
      currentLat: (map['currentLat'] as num?)?.toDouble() ?? 24.8607,
      currentLng: (map['currentLng'] as num?)?.toDouble() ?? 67.0011,
    );
  }
}

class HealthChecklist {
  final bool isAgeValid; // 18-65
  final bool isWeightValid; // >= 50kg
  final bool hasRecentIllness; // 14-day hold
  final bool hasRecentTattooOrSurgery; // 6-month hold
  final double hemoglobinLevel; // >= 12.5

  const HealthChecklist({
    this.isAgeValid = true,
    this.isWeightValid = true,
    this.hasRecentIllness = false,
    this.hasRecentTattooOrSurgery = false,
    this.hemoglobinLevel = 13.5,
  });

  bool get isEligible =>
      isAgeValid &&
      isWeightValid &&
      !hasRecentIllness &&
      !hasRecentTattooOrSurgery &&
      hemoglobinLevel >= 12.5;

  String get eligibilityFeedback {
    if (!isAgeValid) return 'Must be between 18 and 65 years old.';
    if (!isWeightValid) return 'Minimum weight required is 50 kg (110 lbs).';
    if (hasRecentIllness) return 'Temporary 14-day hold due to recent medication/fever.';
    if (hasRecentTattooOrSurgery) return '6-month deferral required post-surgery or tattooing.';
    if (hemoglobinLevel < 12.5) return 'Hemoglobin level must be at least 12.5 g/dL.';
    return 'Congratulations! You meet standard eligibility criteria for donation.';
  }
}

class DriveEvent {
  final String id;
  final String title;
  final String organizer;
  final String universityCampus;
  final String venue;
  final DateTime date;
  final String time;
  final int targetUnits;
  final int registeredDonors;
  final int registeredVolunteers;
  final String description;

  const DriveEvent({
    required this.id,
    required this.title,
    required this.organizer,
    required this.universityCampus,
    required this.venue,
    required this.date,
    required this.time,
    required this.targetUnits,
    required this.registeredDonors,
    required this.registeredVolunteers,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'organizer': organizer,
      'universityCampus': universityCampus,
      'venue': venue,
      'date': date.toIso8601String(),
      'time': time,
      'targetUnits': targetUnits,
      'registeredDonors': registeredDonors,
      'registeredVolunteers': registeredVolunteers,
      'description': description,
    };
  }

  factory DriveEvent.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is DateTime) return d;
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      try {
        return (d as dynamic).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    return DriveEvent(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? 'Campus Blood Drive',
      organizer: map['organizer'] ?? 'Alkhidmat Youth Chapter',
      universityCampus: map['universityCampus'] ?? 'Karachi University Campus',
      venue: map['venue'] ?? 'Main Campus Ground',
      date: parseDate(map['date']),
      time: map['time'] ?? '09:00 AM - 04:00 PM',
      targetUnits: (map['targetUnits'] as num?)?.toInt() ?? 100,
      registeredDonors: (map['registeredDonors'] as num?)?.toInt() ?? 0,
      registeredVolunteers: (map['registeredVolunteers'] as num?)?.toInt() ?? 0,
      description: map['description'] ?? '',
    );
  }

  static final List<DriveEvent> seedDrives = [
    DriveEvent(
      id: 'drive-01',
      title: 'DUET Annual Life-Saver Blood Drive',
      organizer: 'Alkhidmat Youth DUET Chapter',
      universityCampus: 'Dawood University of Eng & Tech (DUET)',
      venue: 'Main Campus Gymnasium, Jamshed Town, Karachi',
      date: DateTime.now().add(const Duration(days: 3)),
      time: '09:00 AM - 04:00 PM',
      targetUnits: 150,
      registeredDonors: 112,
      registeredVolunteers: 28,
      description: 'Join hands with DUET & Alkhidmat to support thalassemia children and emergency trauma units across Karachi.',
    ),
    DriveEvent(
      id: 'drive-02',
      title: 'NED Spring Blood Camp 2026',
      organizer: 'NED Social Welfare Society',
      universityCampus: 'NED University of Eng & Tech',
      venue: 'Student Activity Center, University Rd',
      date: DateTime.now().add(const Duration(days: 7)),
      time: '10:00 AM - 05:00 PM',
      targetUnits: 200,
      registeredDonors: 145,
      registeredVolunteers: 35,
      description: 'Annual mega blood donation camp in collaboration with Alkhidmat Blood Bank Karachi.',
    ),
    DriveEvent(
      id: 'drive-03',
      title: 'KU Campus Awareness & Donation Drive',
      organizer: 'Alkhidmat Foundation Youth Wing',
      universityCampus: 'University of Karachi (KU)',
      venue: 'Arts Lobby, Main Campus',
      date: DateTime.now().add(const Duration(days: 12)),
      time: '09:30 AM - 03:30 PM',
      targetUnits: 180,
      registeredDonors: 98,
      registeredVolunteers: 22,
      description: 'Campus-wide donation and awareness seminar addressing donation myths and emergency preparedness.',
    ),
  ];
}

class MythFact {
  final String id;
  final String question;
  final String answer;
  final bool isMyth;
  final String category;

  const MythFact({
    required this.id,
    required this.question,
    required this.answer,
    required this.isMyth,
    required this.category,
  });
}
