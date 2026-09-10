import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/blood_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/distance_calculator.dart';
import '../../providers/app_state_providers.dart';
import '../donor/cooldown_screen.dart';

class NavigationRoutingScreen extends ConsumerWidget {
  final EmergencyRequest request;
  final MatchedDonor donor;

  const NavigationRoutingScreen({
    super.key,
    required this.request,
    required this.donor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final distanceKm = DistanceCalculator.calculateDistanceKm(
      lat1: user.currentLat,
      lon1: user.currentLng,
      lat2: request.hospital.latitude,
      lon2: request.hospital.longitude,
    );
    final etaMinutes = DistanceCalculator.estimateEtaMinutes(distanceKm);
    final distanceFormatted = DistanceCalculator.formatDistance(distanceKm);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('QATRA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDarkRed)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Turn-by-Turn Instruction Banner (Wireframe Screen 17)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  const Icon(Icons.turn_right_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('In 200m', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(
                          'Turn right onto Rafiqui H.J. Shaheed Rd',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$etaMinutes min', style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(distanceFormatted, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            // Route Visualization Canvas / Map Simulation
            Expanded(
              flex: 4,
              child: Container(
                color: const Color(0xFFF1F5F9),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.navigation_rounded, color: AppColors.primaryRed, size: 36),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Navigating toward JPMC Blood Bank',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Rafiqui H.J. Shaheed Rd, Karachi Cantt',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Destination & Coordination Details Sheet
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('VERIFIED DESTINATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 4),
                  Text(
                    '${request.hospital.name} — Blood Bank & Transfusion Center',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 14),

                  // Recipient direct coordination info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 20, color: AppColors.textDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Recipient: ${request.seekerName} • ${request.bloodGroup.label}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('URGENT', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Open in Google Maps Button
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening turn-by-turn navigation to ${request.hospital.name}...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions, size: 18),
                        SizedBox(width: 8),
                        Text('Open in Google Maps / Navigation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Complete Blood Draw & Initialize Cooldown
                  ElevatedButton(
                    onPressed: () {
                      ref.read(userProvider.notifier).completeDonation();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const CooldownScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18),
                        SizedBox(width: 8),
                        Text('I Have Reached & Donated Blood', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cancel Dispatch fallback (re-opens request to next ranked donor)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ref.read(emergencyRequestsRepositoryProvider).cancelDispatch(
                          requestId: request.id,
                          donorId: donor.id,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dispatch cancelled. Request re-opened to next-ranked donor.')),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel Dispatch (Release to Next Donor)',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
