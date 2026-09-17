import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/blood_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/distance_calculator.dart';
import '../../providers/app_state_providers.dart';
import '../../widgets/status_badges.dart';
import '../../widgets/qatra_logo.dart';
import 'donor_contact_screen.dart';

class MatchmakerDashboardScreen extends ConsumerWidget {
  final EmergencyRequest request;
  const MatchmakerDashboardScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(emergencyRequestsRepositoryProvider);
    final reqStream = repo.getRequestStream(request.id);
    final donorsStream = repo.getAcceptedDonorsStream(request.id);
    final isDemoMode = ref.watch(isDemoModeProvider);

    return StreamBuilder<EmergencyRequest?>(
      stream: reqStream,
      initialData: request,
      builder: (context, reqSnapshot) {
        final currentRequest = reqSnapshot.data ?? request;

        return StreamBuilder<List<MatchedDonor>>(
          stream: donorsStream,
          initialData: isDemoMode ? currentRequest.matchedDonors : const [],
          builder: (context, donorsSnapshot) {
            final liveDonors = donorsSnapshot.data ?? [];
            final matchedDonors = liveDonors.isNotEmpty
                ? liveDonors
                : (isDemoMode ? currentRequest.matchedDonors : <MatchedDonor>[]);

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const QatraBrandHeader(),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Matched Donors',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${matchedDonors.length} Donors Responded via Proximity Alert',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),

                      if (matchedDonors.isEmpty) ...[
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryLightRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.radar_rounded, color: AppColors.primaryRed, size: 30),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Scanning for Nearby Donors',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Broadcasting to verified donors within ${currentRequest.broadcastRadiusKm} km of ${currentRequest.hospital.name}.\n\nAs soon as a donor accepts dispatch, their direct contact details and ETA will appear here in real time.',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // List of Proximity-Ranked Matched Donors
                        ...matchedDonors.map((donor) {
                          return _buildDonorCard(context, donor, currentRequest);
                        }),
                      ],

                      const SizedBox(height: 16),

                      // Share Verified Card to WhatsApp Button
                      OutlinedButton(
                        onPressed: () => _shareToWhatsApp(context, currentRequest),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Share Verified Card to WhatsApp',
                              style: TextStyle(
                                color: Color(0xFF1EBE5D),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareToWhatsApp(BuildContext context, EmergencyRequest req) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Request details copied.'),
            backgroundColor: Color(0xFF25D366),
          ),
        );
      }
    }
  }

  Widget _buildDonorCard(BuildContext context, MatchedDonor donor, EmergencyRequest currentRequest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const QatraLogo(size: 36),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donor.donorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${donor.bloodGroup.label} • ${donor.phoneNumber}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const VerifiedBadge(text: 'Verified'),
              ],
            ),
            const SizedBox(height: 14),

            // Distance & ETA Row
            Row(
              children: [
                const Icon(Icons.near_me_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('${DistanceCalculator.formatDistance(donor.distanceKm)} away', style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('ETA ${donor.etaMinutes} mins', style: const TextStyle(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),

            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: donor.status == 'Accepted Dispatch' ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    donor.status == 'Accepted Dispatch' ? Icons.check_circle : Icons.directions_car,
                    size: 14,
                    color: donor.status == 'Accepted Dispatch' ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    donor.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: donor.status == 'Accepted Dispatch' ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Direct Contact Donor Button (tel:+92XXX)
            ElevatedButton(
              onPressed: () async {
                final cleanPhone = donor.phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
                final uri = Uri.parse('tel:$cleanPhone');
                try {
                  await launchUrl(uri);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Direct calling ${donor.phoneNumber}...')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 18),
                  const SizedBox(width: 8),
                  Text('Contact Donor (${donor.phoneNumber})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Details & Hospital Route Button
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DonorContactScreen(donor: donor, request: currentRequest),
                    ),
                  );
                },
                child: const Text(
                  'View Hospital Destination & Coordination Details',
                  style: TextStyle(color: AppColors.primaryRed, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
