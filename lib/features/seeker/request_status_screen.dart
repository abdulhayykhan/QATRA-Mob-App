import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/blood_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import '../../widgets/status_badges.dart';
import 'matchmaker_dashboard_screen.dart';

class RequestStatusScreen extends ConsumerWidget {
  final EmergencyRequest request;
  const RequestStatusScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QATRA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDarkRed)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Main Active Request Status Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const VerifiedBadge(text: 'Verified Request #REQ-8821'),
                          UrgencyBadge(urgency: request.urgency),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Blood Group & Hospital
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          BloodGroupBadge(bloodGroup: request.bloodGroup, size: 56),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${request.bloodGroup.label} ${request.component.label} Needed',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.local_hospital, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        request.hospital.name,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Quantity and Urgency Details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('QUANTITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                              const SizedBox(height: 2),
                              Text('${request.unitsRequired} Units', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('URGENCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.primaryRed),
                                  const SizedBox(width: 4),
                                  Text(request.urgency.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryRed)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Broadcasting Alert Animation
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Broadcasting to verified donors within ${request.broadcastRadiusKm} km...',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDarkRed),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Active Donors in Radius
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, size: 18, color: AppColors.textDark),
                            const SizedBox(width: 8),
                            Text(
                              '${request.activeDonorsInRadius} Active Donors Found in Radius',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // View Matched Donors Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MatchmakerDashboardScreen(request: request),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('View Matched Donors', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            StreamBuilder<List<MatchedDonor>>(
                              stream: ref.watch(emergencyRequestsRepositoryProvider).getAcceptedDonorsStream(request.id),
                              builder: (context, snapshot) {
                                final liveDonors = snapshot.data ?? [];
                                final count = liveDonors.isNotEmpty
                                    ? liveDonors.length
                                    : (ref.watch(isDemoModeProvider) ? request.matchedDonors.length : 0);
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count Responded',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
