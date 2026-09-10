import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/blood_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import '../../widgets/status_badges.dart';
import '../../widgets/role_switch_sheet.dart';
import '../../widgets/qatra_bottom_nav.dart';
import 'geo_alert_modal.dart';
import 'cooldown_screen.dart';
import '../map/live_map_screen.dart';
import '../feed/social_feed_screen.dart';
import '../awareness/awareness_screen.dart';
import '../profile/profile_screen.dart';

class DonorHomeScreen extends ConsumerStatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  ConsumerState<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends ConsumerState<DonorHomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    // If not on Home tab (index 0), route to the corresponding tab
    if (_navIndex == 1) {
      return SocialFeedScreen(onBackToHome: () => setState(() => _navIndex = 0));
    } else if (_navIndex == 2) {
      return LiveMapScreen(onBackToHome: () => setState(() => _navIndex = 0));
    } else if (_navIndex == 3) {
      return AwarenessScreen(onBackToHome: () => setState(() => _navIndex = 0));
    } else if (_navIndex == 4) {
      return ProfileScreen(onBackToHome: () => setState(() => _navIndex = 0));
    }

    final user = ref.watch(userProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);
    final isLoading = ref.watch(activeEmergencyRequestsLoadingProvider);
    final emergencyRequests = ref.watch(activeEmergencyRequestsProvider);
    final urgentRequests = emergencyRequests.where((r) => r.urgency == UrgencyLevel.high).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('QATRA', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDarkRed)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {
              // Trigger Wireframe Screen 15: Geo-Fenced Push Notification Modal
              if (urgentRequests.isNotEmpty) {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => GeoAlertModal(request: urgentRequests.first),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryRed),
            tooltip: 'Switch Persona',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => const RoleSwitchSheet(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: QatraBottomNav(
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDemoMode)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFEEBA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF856404), size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'DEMO MODE: Showing simulated training data.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.read(isDemoModeProvider.notifier).state = false,
                        child: const Text('Exit Demo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // Wireframe Screen 14: Available to Donate Location Toggle
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available to Donate',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.isAvailableToDonate
                                ? 'Location-based alerts active'
                                : 'Paused (Excluded from matching pool)',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: user.isAvailableToDonate ? const Color(0xFF22C55E) : AppColors.textLight,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.isAvailableToDonate ? 'Online & Geo-Indexed' : 'Offline',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: user.isAvailableToDonate ? const Color(0xFF15803D) : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: user.isAvailableToDonate,
                        activeThumbColor: AppColors.primaryRed,
                        onChanged: (val) {
                          ref.read(userProvider.notifier).toggleAvailable(val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Badges & Lives Saved Row
              Row(
                children: [
                  // Status: Ready & Eligible
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (user.isOnCooldown) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CooldownScreen()),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: user.isOnCooldown ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                user.isOnCooldown ? Icons.timelapse : Icons.check_circle_rounded,
                                color: user.isOnCooldown ? AppColors.standardUrgency : const Color(0xFF2E7D32),
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                            const SizedBox(height: 2),
                            Text(
                              user.isOnCooldown ? 'Cooldown (${user.cooldownDaysRemaining}d)' : 'Ready & Eligible',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: user.isOnCooldown ? AppColors.standardUrgency : const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Lives Saved Card (Crimson Box)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                          const SizedBox(height: 10),
                          Text(
                            '${user.livesSaved}',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          const Text(
                            'Lives Saved • Silver Tier',
                            style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Local Alerts Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emergency_share_rounded, color: AppColors.primaryRed, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Local Proximity Alerts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(() => _navIndex = 2), // Go to Map
                    child: const Text('View All', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Proximity Alert Card
              if (isLoading)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryRed),
                      ),
                      SizedBox(width: 12),
                      Text('Connecting to live Karachi emergency feed...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                )
              else if (urgentRequests.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFECACA)),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primaryRed, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${urgentRequests.length} Verified Emergencies Near You',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDarkRed),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(left: 26),
                        child: Text(
                          'Karachi South & East • Within 10 km radius',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => GeoAlertModal(request: urgentRequests.first),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Review Emergency Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
                          SizedBox(width: 6),
                          Text(
                            'All Clear • 0 Active Emergencies Near You',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.only(left: 26),
                        child: Text(
                          'No hospital alerts in Karachi South & East within 10 km.',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => setState(() => _navIndex = 2), // Go to Map
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Karachi Coverage Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Recent Requests List Preview
              const Text('Active Karachi Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: AppColors.primaryRed),
                  ),
                )
              else if (emergencyRequests.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Pending Blood Requests',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'All hospital emergency requests in Karachi are currently fulfilled. Thank you for being on standby!',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...emergencyRequests.take(2).map((req) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          BloodGroupBadge(bloodGroup: req.bloodGroup, size: 44),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${req.bloodGroup.label} Needed • ${req.hospital.name}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${req.unitsRequired} Units • ${req.urgency.title}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          UrgencyBadge(urgency: req.urgency),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
