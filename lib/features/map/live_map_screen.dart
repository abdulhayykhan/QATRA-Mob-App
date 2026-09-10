import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/blood_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/distance_calculator.dart';
import '../../providers/app_state_providers.dart';
import '../../widgets/status_badges.dart';
import 'navigation_routing_screen.dart';

class LiveMapScreen extends ConsumerStatefulWidget {
  final EmergencyRequest? initialRequest;
  final VoidCallback? onBackToHome;

  const LiveMapScreen({super.key, this.initialRequest, this.onBackToHome});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  EmergencyRequest? _selectedRequest;
  int _activeRadiusKm = 10;

  @override
  void initState() {
    super.initState();
    _selectedRequest = widget.initialRequest;
  }

  void _acceptDispatch(EmergencyRequest req) {
    final user = ref.read(userProvider);
    final distanceKm = DistanceCalculator.calculateDistanceKm(
      lat1: user.currentLat,
      lon1: user.currentLng,
      lat2: req.hospital.latitude,
      lon2: req.hospital.longitude,
    );
    final etaMinutes = DistanceCalculator.estimateEtaMinutes(distanceKm);

    final myDonorRecord = MatchedDonor(
      id: user.id.isNotEmpty ? user.id : 'donor-me',
      donorName: '${user.fullName} (You)',
      bloodGroup: req.bloodGroup,
      distanceKm: distanceKm,
      etaMinutes: etaMinutes,
      status: 'Accepted Dispatch',
      phoneNumber: user.phone,
    );

    ref.read(emergencyRequestsRepositoryProvider).acceptDispatch(
      requestId: req.id,
      donor: myDonorRecord,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationRoutingScreen(
          request: req,
          donor: myDonorRecord,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);
    final requests = ref.watch(activeEmergencyRequestsProvider);
    final activeReq = _selectedRequest ?? (requests.isNotEmpty ? requests.first : null);

    final distanceKm = activeReq != null
        ? DistanceCalculator.calculateDistanceKm(
            lat1: user.currentLat,
            lon1: user.currentLng,
            lat2: activeReq.hospital.latitude,
            lon2: activeReq.hospital.longitude,
          )
        : 0.0;
    final etaMinutes = DistanceCalculator.estimateEtaMinutes(distanceKm);
    final distanceFormatted = DistanceCalculator.formatDistance(distanceKm);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: const Text('Live Proximity Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Live GPS Location',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Acquiring live GPS coordinates...'),
                  duration: Duration(seconds: 1),
                ),
              );
              await ref.read(userProvider.notifier).refreshLiveLocation(ref.read(locationServiceProvider));
              if (context.mounted) {
                final userLoc = ref.read(userProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Live GPS: ${userLoc.currentLat.toStringAsFixed(4)}, ${userLoc.currentLng.toStringAsFixed(4)}'),
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                );
              }
            },
          ),
          // Concentric Radius Filter (5km / 10km / 15km)
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Filter Radius',
            onSelected: (radius) {
              setState(() => _activeRadiusKm = radius);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Proximity radius set to $radius km')),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 5, child: Text('5 km (Tight Urban)')),
              const PopupMenuItem(value: 10, child: Text('10 km (Standard Default)')),
              const PopupMenuItem(value: 15, child: Text('15 km (Expanded Region)')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Interactive Custom Karachi Spatial Map Canvas
          GestureDetector(
            child: CustomPaint(
              size: Size.infinite,
              painter: KarachiMapPainter(
                hospitals: Hospital.karachiHospitals,
                selectedHospital: activeReq?.hospital ?? Hospital.karachiHospitals[0],
                radiusKm: _activeRadiusKm,
              ),
            ),
          ),

          // Top Radius & Urgency Legend
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.radar_rounded, color: AppColors.primaryRed, size: 16),
                          SizedBox(width: 6),
                          Text('Karachi Live Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                      if (isDemoMode) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFFEEBA)),
                          ),
                          child: const Text(
                            'DEMO',
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Geofence: $_activeRadiusKm km • Concentric Rings', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.highUrgency, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('High Urgency (<2h)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.standardUrgency, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Standard (<24h)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Wireframe Screen 16: Expandable Summary Card at the Bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: activeReq == null
                ? Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2E7D32), size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'No Active Emergencies in Selected Radius',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All hospitals within $_activeRadiusKm km currently report adequate supplies. Tap any hospital icon on the map to inspect location details.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hospital and Blood Group Header
                          Row(
                            children: [
                              BloodGroupBadge(bloodGroup: activeReq.bloodGroup, size: 48),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${activeReq.bloodGroup.label} Needed • ${activeReq.hospital.name}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      activeReq.urgency.description,
                                      style: const TextStyle(fontSize: 12, color: AppColors.primaryRed, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Distance, ETA and Donors Nearby Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.near_me_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('$distanceFormatted away', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.directions_car_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('$etaMinutes min ETA', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text('${activeReq.activeDonorsInRadius} Donors', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Action Buttons: Accept Dispatch / Decline
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () => _acceptDispatch(activeReq),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryRed,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_outline, size: 18),
                                      SizedBox(width: 8),
                                      Text('Accept Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Request declined. Next ranked donor alerted.')),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    side: const BorderSide(color: AppColors.border),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Decline', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Karachi Spatial Concentric Radar Map
class KarachiMapPainter extends CustomPainter {
  final List<Hospital> hospitals;
  final Hospital selectedHospital;
  final int radiusKm;

  KarachiMapPainter({
    required this.hospitals,
    required this.selectedHospital,
    required this.radiusKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);

    // Map Background grid lines (Karachi arterial roads representation)
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Concentric Radial Rings (5 km, 10 km, 15 km)
    final ringPaint = Paint()
      ..color = AppColors.primaryRed.withOpacity(0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final ringFillPaint = Paint()
      ..color = AppColors.primaryLightRed.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    // Draw concentric circles
    final double scale = size.width / 36.0; // scale factor
    final double r5 = 5.0 * scale;
    final double r10 = 10.0 * scale;
    final double r15 = 15.0 * scale;

    canvas.drawCircle(center, r15, ringFillPaint);
    canvas.drawCircle(center, r15, ringPaint);
    canvas.drawCircle(center, r10, ringPaint);
    canvas.drawCircle(center, r5, ringPaint);

    // Arterial road lines (Shahrah-e-Faisal, M-9, University Rd, Korangi Rd)
    canvas.drawLine(Offset(center.dx - 180, center.dy + 80), Offset(center.dx + 180, center.dy - 80), gridPaint);
    canvas.drawLine(Offset(center.dx - 150, center.dy - 120), Offset(center.dx + 150, center.dy + 120), gridPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);

    // Draw User Location (Blue pulse dot)
    final userPaint = Paint()..color = const Color(0xFF1D4ED8);
    final userAura = Paint()..color = const Color(0xFF93C5FD).withOpacity(0.5);
    canvas.drawCircle(center, 16, userAura);
    canvas.drawCircle(center, 8, userPaint);

    // Draw Karachi Hospital Pins
    final List<Offset> hospitalOffsets = [
      Offset(center.dx + 25, center.dy - 35), // JPMC
      Offset(center.dx - 45, center.dy + 15), // Civil
      Offset(center.dx + 85, center.dy + 65), // Indus
      Offset(center.dx + 40, center.dy - 95), // Liaquat National
      Offset(center.dx - 20, center.dy + 80), // South City
    ];

    for (int i = 0; i < hospitals.length && i < hospitalOffsets.length; i++) {
      final pos = hospitalOffsets[i];
      final isSelected = hospitals[i].id == selectedHospital.id;

      final pinColor = (i % 2 == 0) ? AppColors.highUrgency : AppColors.standardUrgency;
      final pinPaint = Paint()..color = pinColor;

      // Outer halo if selected
      if (isSelected) {
        final selectHalo = Paint()..color = pinColor.withOpacity(0.25);
        canvas.drawCircle(pos, 22, selectHalo);
      }

      // Hospital Pin Marker
      canvas.drawCircle(pos, isSelected ? 14 : 10, pinPaint);
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawCircle(pos, isSelected ? 5 : 3, whitePaint);
    }
  }

  @override
  bool shouldRepaint(covariant KarachiMapPainter oldDelegate) {
    return oldDelegate.selectedHospital != selectedHospital || oldDelegate.radiusKm != radiusKm;
  }
}
