import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import 'fraud_audit_screen.dart';
import 'drive_management_screen.dart';

class AdminVerificationQueueScreen extends ConsumerStatefulWidget {
  const AdminVerificationQueueScreen({super.key});

  @override
  ConsumerState<AdminVerificationQueueScreen> createState() => _AdminVerificationQueueScreenState();
}

class _AdminVerificationQueueScreenState extends ConsumerState<AdminVerificationQueueScreen> {
  int _selectedQueueIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pendingSlips = ref.watch(pendingVerificationSlipsProvider);
    final isDemoMode = ref.watch(isDemoModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('24/7 Verification Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.security_update_warning_rounded, color: AppColors.primaryRed),
            tooltip: 'Fraud Audit & Blacklist',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FraudAuditScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.textDark),
            tooltip: 'Campus Drive Scanner',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriveManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: pendingSlips.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_outlined, size: 48, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Queue Clear',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No pending requisition slips require review.\nAll requests have been verified or resolved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            : _buildQueueContent(context, pendingSlips, isDemoMode),
      ),
    );
  }

  Widget _buildQueueContent(
    BuildContext context,
    List<VerificationSlip> pendingSlips,
    bool isDemoMode,
  ) {
    final selectedIndex = _selectedQueueIndex.clamp(0, pendingSlips.length - 1);
    final currentSlip = pendingSlips[selectedIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Queue Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Verification (${pendingSlips.length} in Queue)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Row(
                children: [
                  if (isDemoMode)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DEMO DATA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Target SLA: < 3 mins',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Queue chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(pendingSlips.length, (index) {
                final isSelected = selectedIndex == index;
                final item = pendingSlips[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${item.id} • ${item.bloodGroup.label}'),
                    selected: isSelected,
                    selectedColor: AppColors.primaryRed,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedQueueIndex = index);
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Wireframe Screen 21: Split Layout (Scanned Requisition Slip & OCR Metadata)
          // 1. Scanned Slip Image View
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_rounded, size: 48, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(height: 8),
                      Text(
                        'Uploaded Hospital Slip (${currentSlip.id})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Letterhead: ${currentSlip.hospital} • Stamp Verified',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Zoom Slip', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Extracted OCR Data Table (Wireframe Screen 21)
          Card(
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
                      const Text('Requisition Slip Metadata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: currentSlip.flagged ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentSlip.deskReviewStatus,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: currentSlip.flagged ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildOcrRow('Hospital', currentSlip.hospital, Icons.local_hospital),
                  const Divider(height: 16),
                  _buildOcrRow('Doctor Stamp', currentSlip.doctorStamp, Icons.verified_rounded),
                  const Divider(height: 16),
                  _buildOcrRow('Patient MRN', currentSlip.mrn, Icons.badge_outlined),
                  const Divider(height: 16),
                  _buildOcrRow('Blood Group', currentSlip.bloodGroup.label, Icons.bloodtype),
                  const Divider(height: 16),
                  _buildOcrRow('Units Required', currentSlip.units, Icons.medication),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (currentSlip.flagged) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentSlip.flagReason,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Approve & Publish vs Reject Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async {
                    final slipId = currentSlip.id;
                    try {
                      await ref.read(verificationRepositoryProvider).approveSlip(slipId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Request $slipId approved & broadcasted to nearby donors!'),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to approve request: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 18),
                      SizedBox(width: 6),
                      Text('Approve & Publish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () async {
                    final slipId = currentSlip.id;
                    try {
                      await ref.read(verificationRepositoryProvider).rejectSlip(
                            slipId,
                            'Flagged during desk review - verification documents unclear or hospital unconfirmed',
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Request $slipId rejected.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to reject request: $e')),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: AppColors.primaryRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOcrRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }
}
