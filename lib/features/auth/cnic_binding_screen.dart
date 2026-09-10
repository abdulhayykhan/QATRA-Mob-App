import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cnic_validator.dart';
import '../../providers/app_state_providers.dart';
import '../../widgets/qatra_logo.dart';
import '../health/health_checklist_screen.dart';

class CnicBindingScreen extends ConsumerStatefulWidget {
  const CnicBindingScreen({super.key});

  @override
  ConsumerState<CnicBindingScreen> createState() => _CnicBindingScreenState();
}

class _CnicBindingScreenState extends ConsumerState<CnicBindingScreen> {
  final TextEditingController _cnicController =
      TextEditingController(text: '42101-1234567-1');
  bool _frontUploaded = true;
  bool _backUploaded = true;
  String? _errorMessage;

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  void _submitCnic() {
    final cnic = _cnicController.text.trim();
    if (!CnicValidator.isValid(cnic)) {
      setState(() {
        _errorMessage = 'Please enter a valid 13-digit CNIC (e.g. 42101-1234567-1)';
      });
      return;
    }

    ref.read(userProvider.notifier).verifyCnic(cnic);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HealthChecklistScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const QatraBrandHeader(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Donor Identity Verification',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please provide your valid CNIC details to ensure a secure, verified donation process for emergency patients.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),

              // CNIC Number Input
              const Text(
                'CNIC Number',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '42101-XXXXXXX-X',
                  errorText: _errorMessage,
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primaryRed),
                ),
                onChanged: (val) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Front and Back Photos
              const Text(
                'Upload CNIC Photos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _frontUploaded = true),
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: _frontUploaded ? AppColors.primaryLightRed.withOpacity(0.4) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _frontUploaded ? AppColors.primaryRed : AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _frontUploaded ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
                              color: _frontUploaded ? AppColors.primaryRed : AppColors.textMuted,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _frontUploaded ? 'Front CNIC Added' : 'Front CNIC Image',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _frontUploaded ? AppColors.primaryDarkRed : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _backUploaded = true),
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          color: _backUploaded ? AppColors.primaryLightRed.withOpacity(0.4) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _backUploaded ? AppColors.primaryRed : AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _backUploaded ? Icons.check_circle_rounded : Icons.add_a_photo_outlined,
                              color: _backUploaded ? AppColors.primaryRed : AppColors.textMuted,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _backUploaded ? 'Back CNIC Added' : 'Back CNIC Image',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _backUploaded ? AppColors.primaryDarkRed : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Security & Vault Banner (PRD Section 4.4 & 7.3)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_rounded, color: Color(0xFF15803D), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Data is AES-256 encrypted in an isolated vault and never exposed publicly. Used solely for Alkhidmat verification & anti-fraud audit.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF166534),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Submit & Proceed Button
              ElevatedButton(
                onPressed: _submitCnic,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Submit & Proceed to Health Check', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
