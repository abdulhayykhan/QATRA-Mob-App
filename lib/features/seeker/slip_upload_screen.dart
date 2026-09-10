import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/blood_models.dart';
import '../../core/models/user_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import 'request_status_screen.dart';

class SlipUploadScreen extends ConsumerStatefulWidget {
  final BloodGroup bloodGroup;
  final BloodComponent component;
  final int units;
  final Hospital hospital;
  final UrgencyLevel urgency;

  const SlipUploadScreen({
    super.key,
    required this.bloodGroup,
    required this.component,
    required this.units,
    required this.hospital,
    required this.urgency,
  });

  @override
  ConsumerState<SlipUploadScreen> createState() => _SlipUploadScreenState();
}

class _SlipUploadScreenState extends ConsumerState<SlipUploadScreen> {
  bool _isProcessing = false;
  int _modalStep = 1; // 1: Extracting OCR, 2: Verification Queue Review

  void _startVerificationProcess() {
    setState(() {
      _isProcessing = true;
      _modalStep = 1;
    });

    // Simulate OCR Extraction (1.5 seconds)
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _modalStep = 2);

        // Auto-approve and publish request
        Timer(const Duration(milliseconds: 2000), () {
          if (mounted) {
            final user = ref.read(userProvider);
            final isDemoMode = ref.read(isDemoModeProvider);
            final newRequest = EmergencyRequest(
              id: 'REQ-${DateTime.now().millisecondsSinceEpoch % 10000}',
              seekerId: user.id.isNotEmpty ? user.id : 'seeker-curr',
              seekerName: user.fullName.isNotEmpty ? user.fullName : 'Emergency Seeker',
              bloodGroup: widget.bloodGroup,
              component: widget.component,
              unitsRequired: widget.units,
              hospital: widget.hospital,
              urgency: widget.urgency,
              patientMrn: 'MRN-88412',
              doctorStamp: 'Trauma Consultant Stamp (Approved)',
              deskReviewStatus: 'Submitted for Verification Desk Review',
              status: RequestStatus.broadcasting,
              broadcastRadiusKm: 10,
              createdAt: DateTime.now(),
              activeDonorsInRadius: 18,
              matchedDonors: isDemoMode
                  ? [
                      MatchedDonor(
                        id: 'donor-104',
                        donorName: 'Ali Raza',
                        bloodGroup: widget.bloodGroup,
                        distanceKm: 2.3,
                        etaMinutes: 12,
                        status: 'Accepted Dispatch',
                        phoneNumber: '+92 300 8765432',
                      ),
                    ]
                  : const [],
            );

            ref.read(emergencyRequestsRepositoryProvider).createRequest(newRequest);

            // Submit slip to 24/7 Verification Queue in Firestore
            final verificationSlip = VerificationSlip(
              id: newRequest.id,
              seekerId: user.id.isNotEmpty ? user.id : 'seeker-curr',
              hospital: widget.hospital.name,
              doctorStamp: 'Trauma Consultant Stamp (Approved)',
              mrn: 'MRN-88412',
              bloodGroup: widget.bloodGroup,
              units: '${widget.units} Bag${widget.units > 1 ? 's' : ''}',
              deskReviewStatus: 'Submitted for Verification Desk Review',
              flagged: false,
              createdAt: DateTime.now(),
            );
            ref.read(verificationRepositoryProvider).submitSlip(verificationSlip);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RequestStatusScreen(request: newRequest),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Verify Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Requisition slips must show doctor signature, hospital name, and blood group.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera viewfinder simulation with guidelines
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              width: double.infinity,
              height: 440,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24, width: 1.5),
              ),
              child: Stack(
                children: [
                  // Alignment guide box
                  Center(
                    child: Container(
                      width: 290,
                      height: 380,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryRed, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner_rounded, size: 64, color: Colors.white.withOpacity(0.6)),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Align hospital requisition slip within frame.\nEnsure Doctor Stamp, MRN & Letterhead are clearly visible.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // OCR Scan Simulation Line
                  Positioned(
                    top: 100,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primaryRed.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls & Security Note
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, color: Color(0xFF4ADE80), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '100% of requests are verified to eliminate commercial resellers. Your upload is secure and confidential.',
                          style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Shutter / Capture Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.flash_off_rounded, color: Colors.white70),
                        onPressed: () {},
                      ),
                      GestureDetector(
                        onTap: _startVerificationProcess,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: AppColors.primaryRed,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded, color: Colors.white70),
                        onPressed: _startVerificationProcess,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to Capture or Select from Gallery',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // Wireframe Screen 6: Verification Processing Modal
          if (_isProcessing)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Verification in Progress',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      _buildProcessingStep(
                        title: 'Requisition Slip Uploaded',
                        subtitle: 'MRN, Units, & Hospital Letterhead recorded',
                        isDone: true,
                      ),
                      const SizedBox(height: 16),
                      _buildProcessingStep(
                        title: 'Verification Desk Review in Progress',
                        subtitle: 'Estimated review time: < 3 mins',
                        isDone: _modalStep == 2,
                        isLoading: _modalStep == 2,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'You will receive an instant push notification once approved. You can safely keep this open or view requests.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
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

  Widget _buildProcessingStep({
    required String title,
    required String subtitle,
    required bool isDone,
    bool isLoading = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(AppColors.primaryRed)),
          )
        else
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isDone ? const Color(0xFF2E7D32) : AppColors.textLight,
            size: 22,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
