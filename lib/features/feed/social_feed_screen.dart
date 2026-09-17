import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/blood_models.dart';
import '../../core/models/user_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/distance_calculator.dart';
import '../../providers/app_state_providers.dart';
import '../../widgets/status_badges.dart';
import '../map/live_map_screen.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackToHome;
  const SocialFeedScreen({super.key, this.onBackToHome});

  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  int _tabIndex = 0; // 0: Urgent Requests, 1: Awareness Content
  BloodGroup? _filterGroup;
  UrgencyLevel? _filterUrgency;

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    final isLoading = ref.watch(activeEmergencyRequestsLoadingProvider);
    final requests = ref.watch(activeEmergencyRequestsProvider);
    final myths = ref.watch(mythFactProvider);

    // Apply filters
    var filteredRequests = requests.where((r) {
      if (_filterGroup != null && r.bloodGroup != _filterGroup) return false;
      if (_filterUrgency != null && r.urgency != _filterUrgency) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              _tabIndex == 0 ? 'Real-time Blood Requests' : 'Awareness & Knowledge Hub',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        leading: widget.onBackToHome != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackToHome,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isDemoMode)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEEBA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF856404), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DEMO MODE: Showing simulated requests.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF856404)),
                      ),
                    ),
                  ],
                ),
              ),

            // Urgent vs Awareness Tabs (Wireframe Screen 7 / PRD Section 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0 ? AppColors.primaryRed : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emergency_rounded, size: 16, color: _tabIndex == 0 ? Colors.white : AppColors.textDark),
                              const SizedBox(width: 6),
                              Text(
                                'Urgent Requests',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _tabIndex == 0 ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1 ? AppColors.primaryRed : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign_rounded, size: 16, color: _tabIndex == 1 ? Colors.white : AppColors.textDark),
                              const SizedBox(width: 6),
                              Text(
                                'Awareness',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _tabIndex == 1 ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Chips Bar (Wireframe Screen 22)
            if (_tabIndex == 0) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    // Blood Group Filter
                    PopupMenuButton<BloodGroup?>(
                      initialValue: _filterGroup,
                      onSelected: (bg) => setState(() => _filterGroup = bg),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: null, child: Text('All Blood Groups')),
                        ...BloodGroup.values.map(
                          (bg) => PopupMenuItem(value: bg, child: Text(bg.label)),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _filterGroup != null ? AppColors.primaryLightRed : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _filterGroup != null ? AppColors.primaryRed : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _filterGroup != null ? 'Blood: ${_filterGroup!.label}' : 'Blood Group',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _filterGroup != null ? AppColors.primaryDarkRed : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Urgency Filter
                    FilterChip(
                      label: const Text('High Urgency (<2h)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      selected: _filterUrgency == UrgencyLevel.high,
                      selectedColor: const Color(0xFFFFEBEE),
                      backgroundColor: Colors.white,
                      checkmarkColor: AppColors.primaryRed,
                      onSelected: (val) {
                        setState(() => _filterUrgency = val ? UrgencyLevel.high : null);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Distance Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.near_me_outlined, size: 14, color: AppColors.textMuted),
                          SizedBox(width: 4),
                          Text('Within 10 km', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Feed Content List
            Expanded(
              child: _tabIndex == 0
                  ? (isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryRed),
                        )
                      : (filteredRequests.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF2E7D32)),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'No Active Blood Requests',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _filterGroup != null || _filterUrgency != null
                                          ? 'No emergency requests match your current filters. Try resetting your filters to view all Karachi requests.'
                                          : 'There are currently no active emergency requests in the system. All hospital needs are fulfilled.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                                    ),
                                    if (_filterGroup != null || _filterUrgency != null) ...[
                                      const SizedBox(height: 14),
                                      OutlinedButton(
                                        onPressed: () => setState(() {
                                          _filterGroup = null;
                                          _filterUrgency = null;
                                        }),
                                        child: const Text('Reset Filters'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: filteredRequests.length,
                              itemBuilder: (context, index) {
                                final req = filteredRequests[index];
                                return _buildStructuredPostCard(req);
                              },
                            )))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: myths.length,
                      itemBuilder: (context, index) {
                        final mf = myths[index];
                        return _buildAwarenessCard(mf);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredPostCard(EmergencyRequest req) {
    final user = ref.watch(userProvider);
    final distanceKm = DistanceCalculator.calculateDistanceKm(
      lat1: user.currentLat,
      lon1: user.currentLng,
      lat2: req.hospital.latitude,
      lon2: req.hospital.longitude,
    );
    final etaMinutes = DistanceCalculator.estimateEtaMinutes(distanceKm);
    final distFormatted = DistanceCalculator.formatDistance(distanceKm);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Priority Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UrgencyBadge(urgency: req.urgency),
                const VerifiedBadge(text: 'Verified Slip'),
              ],
            ),
            const SizedBox(height: 14),

            // Blood Group & Distance
            Row(
              children: [
                BloodGroupBadge(bloodGroup: req.bloodGroup, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${req.bloodGroup.label} Needed • $distFormatted away',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              req.hospital.name,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Distance, ETA & Nearby Donors
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${req.broadcastRadiusKm} km radius', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('ETA $etaMinutes min', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                Text(
                  '${req.activeDonorsInRadius} donors nearby',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // One-Tap "I Can Donate" and Share Buttons (Wireframe Screen 22 / FR 3.3)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LiveMapScreen(initialRequest: req),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('I Can Help', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.textDark),
                  tooltip: 'Share formatted card',
                  onPressed: () => _shareToWhatsApp(req),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToWhatsApp(EmergencyRequest req) async {
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
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Request details copied.'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
      }
    }
  }

  Widget _buildAwarenessCard(MythFact mf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: mf.isMyth ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mf.isMyth ? 'MYTH BUSTER' : 'EVIDENCE FACT',
                style: TextStyle(
                  color: mf.isMyth ? AppColors.primaryRed : const Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(mf.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Text(mf.answer, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
