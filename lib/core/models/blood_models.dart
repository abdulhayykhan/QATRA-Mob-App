enum BloodGroup {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  abPositive('AB+'),
  abNegative('AB-'),
  oPositive('O+'),
  oNegative('O-');

  final String label;
  const BloodGroup(this.label);

  static BloodGroup fromString(String value) {
    final v = value.trim().toLowerCase();
    return BloodGroup.values.firstWhere(
      (e) => e.label.toLowerCase() == v || e.name.toLowerCase() == v,
      orElse: () => BloodGroup.oPositive,
    );
  }

  bool isRare() {
    return this == BloodGroup.oNegative || this == BloodGroup.abNegative;
  }

  // Compatibility matrix
  List<BloodGroup> get compatibleRecipients {
    switch (this) {
      case BloodGroup.oNegative:
        return BloodGroup.values; // Universal donor
      case BloodGroup.oPositive:
        return [BloodGroup.oPositive, BloodGroup.aPositive, BloodGroup.bPositive, BloodGroup.abPositive];
      case BloodGroup.aNegative:
        return [BloodGroup.aNegative, BloodGroup.aPositive, BloodGroup.abNegative, BloodGroup.abPositive];
      case BloodGroup.aPositive:
        return [BloodGroup.aPositive, BloodGroup.abPositive];
      case BloodGroup.bNegative:
        return [BloodGroup.bNegative, BloodGroup.bPositive, BloodGroup.abNegative, BloodGroup.abPositive];
      case BloodGroup.bPositive:
        return [BloodGroup.bPositive, BloodGroup.abPositive];
      case BloodGroup.abNegative:
        return [BloodGroup.abNegative, BloodGroup.abPositive];
      case BloodGroup.abPositive:
        return [BloodGroup.abPositive]; // Universal recipient
    }
  }

  List<BloodGroup> get compatibleDonors {
    switch (this) {
      case BloodGroup.oNegative:
        return [BloodGroup.oNegative];
      case BloodGroup.oPositive:
        return [BloodGroup.oNegative, BloodGroup.oPositive];
      case BloodGroup.aNegative:
        return [BloodGroup.oNegative, BloodGroup.aNegative];
      case BloodGroup.aPositive:
        return [BloodGroup.oNegative, BloodGroup.oPositive, BloodGroup.aNegative, BloodGroup.aPositive];
      case BloodGroup.bNegative:
        return [BloodGroup.oNegative, BloodGroup.bNegative];
      case BloodGroup.bPositive:
        return [BloodGroup.oNegative, BloodGroup.oPositive, BloodGroup.bNegative, BloodGroup.bPositive];
      case BloodGroup.abNegative:
        return [BloodGroup.oNegative, BloodGroup.aNegative, BloodGroup.bNegative, BloodGroup.abNegative];
      case BloodGroup.abPositive:
        return BloodGroup.values; // Can receive from any group
    }
  }

  bool canDonateTo(BloodGroup recipient) {
    return compatibleRecipients.contains(recipient);
  }
}

enum BloodComponent {
  wholeBlood('Whole Blood'),
  prbc('Packed Red Blood Cells (PRBC)'),
  platelets('Platelets / Mega Unit'),
  plasma('Plasma (FFP)');

  final String label;
  const BloodComponent(this.label);
}

enum UrgencyLevel {
  high('High Priority', 'Needed within 2 Hours', 2),
  standard('Standard', 'Needed within 24 Hours', 24);

  final String title;
  final String description;
  final int maxHours;
  const UrgencyLevel(this.title, this.description, this.maxHours);
}

enum RequestStatus {
  pendingVerification('Pending Verification'),
  verified('Verified by Desk'),
  broadcasting('Broadcasting to Radius'),
  matched('Donor Matched'),
  fulfilled('Fulfilled'),
  cancelled('Cancelled');

  final String label;
  const RequestStatus(this.label);
}

class Hospital {
  final String id;
  final String name;
  final String address;
  final String district;
  final double latitude;
  final double longitude;
  final String emergencyPhone;

  const Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.emergencyPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'emergencyPhone': emergencyPhone,
    };
  }

  factory Hospital.fromMap(Map<String, dynamic> map) {
    return Hospital(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      district: map['district'] ?? 'Karachi South',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 24.8607,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 67.0011,
      emergencyPhone: map['emergencyPhone'] ?? '',
    );
  }

  // Pre-configured Karachi Hospitals
  static const List<Hospital> karachiHospitals = [
    Hospital(
      id: 'hosp-01',
      name: 'Jinnah Postgraduate Medical Centre (JPMC)',
      address: 'Rafiqui H.J. Shaheed Rd, Karachi Cantt',
      district: 'Karachi South',
      latitude: 24.8532,
      longitude: 67.0458,
      emergencyPhone: '021-99201300',
    ),
    Hospital(
      id: 'hosp-02',
      name: 'Dr. Ruth K.M. Pfau Civil Hospital',
      address: 'Mission Rd, New Dehli Colony, Karachi',
      district: 'Karachi South',
      latitude: 24.8596,
      longitude: 67.0101,
      emergencyPhone: '021-99215740',
    ),
    Hospital(
      id: 'hosp-03',
      name: 'Indus Hospital & Health Network',
      address: 'Plot C-76, Sector 31/5, Korangi Crossing',
      district: 'Korangi',
      latitude: 24.8322,
      longitude: 67.1264,
      emergencyPhone: '021-111111880',
    ),
    Hospital(
      id: 'hosp-04',
      name: 'Liaquat National Hospital',
      address: 'National Stadium Rd, Gulshan-e-Iqbal',
      district: 'Karachi East',
      latitude: 24.8935,
      longitude: 67.0702,
      emergencyPhone: '021-111456456',
    ),
    Hospital(
      id: 'hosp-05',
      name: 'South City Hospital',
      address: 'Rojhan St, Block 3, Clifton',
      district: 'Karachi South',
      latitude: 24.8197,
      longitude: 67.0289,
      emergencyPhone: '021-35862301',
    ),
  ];
}

class MatchedDonor {
  final String id;
  final String donorName; // e.g. "Ali Raza" or "Donor #D-104"
  final BloodGroup bloodGroup;
  final double distanceKm;
  final int etaMinutes;
  final String status; // Accepted Dispatch, En Route, At Hospital
  final String phoneNumber; // Direct phone: "+92 300 1234567"

  MatchedDonor({
    required this.id,
    required this.donorName,
    required this.bloodGroup,
    required this.distanceKm,
    required this.etaMinutes,
    required this.status,
    required this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorName': donorName,
      'bloodGroup': bloodGroup.label,
      'distanceKm': distanceKm,
      'etaMinutes': etaMinutes,
      'status': status,
      'phoneNumber': phoneNumber,
    };
  }

  factory MatchedDonor.fromMap(Map<String, dynamic> map, [String? id]) {
    return MatchedDonor(
      id: id ?? map['id'] ?? '',
      donorName: map['donorName'] ?? 'Verified Donor',
      bloodGroup: BloodGroup.fromString(map['bloodGroup']?.toString() ?? 'O-'),
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: (map['etaMinutes'] as num?)?.toInt() ?? 0,
      status: map['status'] ?? 'Accepted Dispatch',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}

class EmergencyRequest {
  final String id;
  final String seekerId;
  final String seekerName;
  final BloodGroup bloodGroup;
  final BloodComponent component;
  final int unitsRequired;
  final int unitsFulfilled;
  final Hospital hospital;
  final UrgencyLevel urgency;
  final String? slipImageUrl;
  final String? patientMrn;
  final String? doctorStamp;
  final String deskReviewStatus;
  final RequestStatus status;
  final int broadcastRadiusKm;
  final DateTime createdAt;
  final List<MatchedDonor> matchedDonors;
  final int activeDonorsInRadius;

  EmergencyRequest({
    required this.id,
    required this.seekerId,
    required this.seekerName,
    required this.bloodGroup,
    required this.component,
    required this.unitsRequired,
    this.unitsFulfilled = 0,
    required this.hospital,
    required this.urgency,
    this.slipImageUrl,
    this.patientMrn,
    this.doctorStamp,
    this.deskReviewStatus = 'Submitted for Verification Desk Review',
    this.status = RequestStatus.broadcasting,
    this.broadcastRadiusKm = 10,
    required this.createdAt,
    this.matchedDonors = const [],
    this.activeDonorsInRadius = 18,
  });

  EmergencyRequest copyWith({
    String? id,
    String? seekerId,
    String? seekerName,
    BloodGroup? bloodGroup,
    BloodComponent? component,
    int? unitsRequired,
    int? unitsFulfilled,
    Hospital? hospital,
    UrgencyLevel? urgency,
    String? slipImageUrl,
    String? patientMrn,
    String? doctorStamp,
    String? deskReviewStatus,
    RequestStatus? status,
    int? broadcastRadiusKm,
    DateTime? createdAt,
    List<MatchedDonor>? matchedDonors,
    int? activeDonorsInRadius,
  }) {
    return EmergencyRequest(
      id: id ?? this.id,
      seekerId: seekerId ?? this.seekerId,
      seekerName: seekerName ?? this.seekerName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      component: component ?? this.component,
      unitsRequired: unitsRequired ?? this.unitsRequired,
      unitsFulfilled: unitsFulfilled ?? this.unitsFulfilled,
      hospital: hospital ?? this.hospital,
      urgency: urgency ?? this.urgency,
      slipImageUrl: slipImageUrl ?? this.slipImageUrl,
      patientMrn: patientMrn ?? this.patientMrn,
      doctorStamp: doctorStamp ?? this.doctorStamp,
      deskReviewStatus: deskReviewStatus ?? this.deskReviewStatus,
      status: status ?? this.status,
      broadcastRadiusKm: broadcastRadiusKm ?? this.broadcastRadiusKm,
      createdAt: createdAt ?? this.createdAt,
      matchedDonors: matchedDonors ?? this.matchedDonors,
      activeDonorsInRadius: activeDonorsInRadius ?? this.activeDonorsInRadius,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seekerId': seekerId,
      'seekerName': seekerName,
      'bloodGroup': bloodGroup.label,
      'component': component.name,
      'unitsRequired': unitsRequired,
      'unitsFulfilled': unitsFulfilled,
      'hospital': hospital.toMap(),
      'urgency': urgency.name,
      'slipImageUrl': slipImageUrl,
      'patientMrn': patientMrn,
      'doctorStamp': doctorStamp,
      'deskReviewStatus': deskReviewStatus,
      'status': status.name,
      'broadcastRadiusKm': broadcastRadiusKm,
      'createdAt': createdAt.toIso8601String(),
      'activeDonorsInRadius': activeDonorsInRadius,
      'matchedDonors': matchedDonors.map((d) => d.toMap()).toList(),
    };
  }

  factory EmergencyRequest.fromMap(Map<String, dynamic> map, [String? id]) {
    BloodGroup parseBloodGroup(dynamic bg) {
      if (bg == null) return BloodGroup.oNegative;
      return BloodGroup.fromString(bg.toString());
    }

    BloodComponent parseComponent(dynamic c) {
      if (c == null) return BloodComponent.wholeBlood;
      final str = c.toString().toLowerCase();
      for (final comp in BloodComponent.values) {
        if (comp.name.toLowerCase() == str || comp.label.toLowerCase() == str) {
          return comp;
        }
      }
      return BloodComponent.wholeBlood;
    }

    UrgencyLevel parseUrgency(dynamic u) {
      if (u == null) return UrgencyLevel.high;
      final str = u.toString().toLowerCase();
      if (str.contains('standard')) return UrgencyLevel.standard;
      return UrgencyLevel.high;
    }

    RequestStatus parseStatus(dynamic s) {
      if (s == null) return RequestStatus.broadcasting;
      final str = s.toString().toLowerCase();
      for (final st in RequestStatus.values) {
        if (st.name.toLowerCase() == str || st.label.toLowerCase() == str) {
          return st;
        }
      }
      return RequestStatus.broadcasting;
    }

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

    Hospital parseHospital(dynamic h) {
      if (h is Map<String, dynamic>) {
        return Hospital.fromMap(h);
      }
      return Hospital.karachiHospitals[0];
    }

    List<MatchedDonor> parseDonors(dynamic d) {
      if (d is List) {
        return d.map((item) {
          if (item is Map<String, dynamic>) {
            return MatchedDonor.fromMap(item);
          }
          return null;
        }).whereType<MatchedDonor>().toList();
      }
      return [];
    }

    return EmergencyRequest(
      id: id ?? map['id'] ?? '',
      seekerId: map['seekerId'] ?? '',
      seekerName: map['seekerName'] ?? 'Emergency Seeker',
      bloodGroup: parseBloodGroup(map['bloodGroup']),
      component: parseComponent(map['component']),
      unitsRequired: (map['unitsRequired'] as num?)?.toInt() ?? 1,
      unitsFulfilled: (map['unitsFulfilled'] as num?)?.toInt() ?? 0,
      hospital: parseHospital(map['hospital']),
      urgency: parseUrgency(map['urgency']),
      slipImageUrl: map['slipImageUrl'],
      patientMrn: map['patientMrn'],
      doctorStamp: map['doctorStamp'],
      deskReviewStatus: map['deskReviewStatus'] ?? 'Submitted for Verification Desk Review',
      status: parseStatus(map['status']),
      broadcastRadiusKm: (map['broadcastRadiusKm'] as num?)?.toInt() ?? 10,
      createdAt: parseDate(map['createdAt']),
      matchedDonors: parseDonors(map['matchedDonors']),
      activeDonorsInRadius: (map['activeDonorsInRadius'] as num?)?.toInt() ?? 0,
    );
  }

  static final List<EmergencyRequest> seedRequests = [
    EmergencyRequest(
      id: 'REQ-8821',
      seekerId: 'seeker-1',
      seekerName: 'Ahmed Khan',
      bloodGroup: BloodGroup.oNegative,
      component: BloodComponent.prbc,
      unitsRequired: 2,
      unitsFulfilled: 0,
      hospital: Hospital.karachiHospitals[0], // JPMC
      urgency: UrgencyLevel.high,
      patientMrn: 'MRN-44918',
      doctorStamp: 'Dr. Tariq Mahmood (Trauma Surgeon)',
      deskReviewStatus: 'Submitted for Verification Desk Review',
      status: RequestStatus.broadcasting,
      broadcastRadiusKm: 10,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      activeDonorsInRadius: 18,
      matchedDonors: [
        MatchedDonor(
          id: 'donor-104',
          donorName: 'Ali Raza',
          bloodGroup: BloodGroup.oNegative,
          distanceKm: 2.3,
          etaMinutes: 12,
          status: 'Accepted Dispatch',
          phoneNumber: '+92 300 8765432',
        ),
        MatchedDonor(
          id: 'donor-208',
          donorName: 'Usman Farooq',
          bloodGroup: BloodGroup.oNegative,
          distanceKm: 5.1,
          etaMinutes: 22,
          status: 'En Route',
          phoneNumber: '+92 321 9876543',
        ),
      ],
    ),
    EmergencyRequest(
      id: 'REQ-8822',
      seekerId: 'seeker-2',
      seekerName: 'Fatima Zahra',
      bloodGroup: BloodGroup.aPositive,
      component: BloodComponent.wholeBlood,
      unitsRequired: 1,
      unitsFulfilled: 0,
      hospital: Hospital.karachiHospitals[1], // Civil Hospital
      urgency: UrgencyLevel.standard,
      patientMrn: 'MRN-7782A',
      doctorStamp: 'Dr. Farhan Ali (General Hospital)',
      deskReviewStatus: 'Under Review by Alkhidmat Desk',
      status: RequestStatus.broadcasting,
      broadcastRadiusKm: 10,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      activeDonorsInRadius: 32,
      matchedDonors: [],
    ),
    EmergencyRequest(
      id: 'REQ-8823',
      seekerId: 'seeker-3',
      seekerName: 'Zubair Sheikh',
      bloodGroup: BloodGroup.bPositive,
      component: BloodComponent.platelets,
      unitsRequired: 3,
      unitsFulfilled: 1,
      hospital: Hospital.karachiHospitals[2], // Indus Hospital
      urgency: UrgencyLevel.high,
      patientMrn: 'MRN-2219B',
      doctorStamp: 'Dr. Ayesha Siddiqui',
      deskReviewStatus: 'Submitted for Verification Desk Review',
      status: RequestStatus.matched,
      broadcastRadiusKm: 15,
      createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      activeDonorsInRadius: 24,
      matchedDonors: [
        MatchedDonor(
          id: 'donor-305',
          donorName: 'Bilal Siddiqui',
          bloodGroup: BloodGroup.bPositive,
          distanceKm: 4.8,
          etaMinutes: 19,
          status: 'At Hospital',
          phoneNumber: '+92 333 4567890',
        ),
      ],
    ),
  ];
}
