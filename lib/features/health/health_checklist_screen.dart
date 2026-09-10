import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../donor/donor_home_screen.dart';

class HealthChecklistScreen extends StatefulWidget {
  const HealthChecklistScreen({super.key});

  @override
  State<HealthChecklistScreen> createState() => _HealthChecklistScreenState();
}

class _HealthChecklistScreenState extends State<HealthChecklistScreen> {
  int _currentStep = 1;

  // Step 1: Basic
  bool _isAgeValid = true; // 18-65
  bool _isWeightValid = true; // >= 50kg

  // Step 2: Recent Health
  bool _hasRecentFeverOrMeds = false; // 14-day hold
  bool _hasMajorSurgeryOrTattoo = false; // 6-month hold

  // Step 3: Donation history
  bool _donatedInPast90Days = false;

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      // Completed, go to Donor Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DonorHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = _currentStep / 4.0;
    final bool isEligible = _isAgeValid &&
        _isWeightValid &&
        !_hasRecentFeverOrMeds &&
        !_hasMajorSurgeryOrTattoo &&
        !_donatedInPast90Days;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Health Eligibility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step counter & Progress bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Step $_currentStep of 4', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted, fontSize: 13)),
                  Text('${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryRed, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                ),
              ),
              const SizedBox(height: 28),

              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(isEligible),
                ),
              ),

              // Bottom Button
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentStep == 4 ? 'Complete & Go to Dashboard' : 'Continue',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isEligible) {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primaryLightRed, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.fitness_center_rounded, color: AppColors.primaryRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Basic Physical Requirements', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'To ensure donor safety, please confirm you meet the primary physiological requirements.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            _buildCheckTile(
              title: 'Age Requirement',
              subtitle: 'I am between 18 and 65 years old',
              value: _isAgeValid,
              onChanged: (val) => setState(() => _isAgeValid = val),
            ),
            const SizedBox(height: 12),
            _buildCheckTile(
              title: 'Weight Requirement',
              subtitle: 'I weigh at least 50 kg (110 lbs)',
              value: _isWeightValid,
              onChanged: (val) => setState(() => _isWeightValid = val),
            ),
          ],
        );

      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primaryLightRed, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.healing_rounded, color: AppColors.primaryRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Recent Health Condition', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Certain temporary illnesses or treatments require a brief waiting period before blood draw.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            _buildCheckTile(
              title: 'Recent Medication or Fever',
              subtitle: 'Any fever, flu, or antibiotic consumption in past 14 days (14-day hold)',
              value: _hasRecentFeverOrMeds,
              isNegative: true,
              onChanged: (val) => setState(() => _hasRecentFeverOrMeds = val),
            ),
            const SizedBox(height: 12),
            _buildCheckTile(
              title: 'Surgery, Piercing or Tattoo',
              subtitle: 'Any major surgery or tattooing within the last 6 months (6-month hold)',
              value: _hasMajorSurgeryOrTattoo,
              isNegative: true,
              onChanged: (val) => setState(() => _hasMajorSurgeryOrTattoo = val),
            ),
          ],
        );

      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primaryLightRed, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.timelapse_rounded, color: AppColors.primaryRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Donation History & Recovery', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Donors require at least 90 days between whole blood donations to replenish iron stores safely.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            _buildCheckTile(
              title: 'Donated Within Last 90 Days',
              subtitle: 'Have you donated blood within the past 90 days?',
              value: _donatedInPast90Days,
              isNegative: true,
              onChanged: (val) => setState(() => _donatedInPast90Days = val),
            ),
          ],
        );

      case 4:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isEligible ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEligible ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: isEligible ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEligible ? 'Eligible to Proceed' : 'Temporary Hold Advised',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isEligible ? const Color(0xFF1B5E20) : const Color(0xFFE65100),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isEligible
                  ? 'Based on your screening responses, you meet the initial eligibility requirements to respond to emergency dispatch requests!'
                  : 'Based on standard health guidelines, you may need a short recovery window before donating blood.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Note: This is an initial pre-screening check. Final clinical determination will be verified on-site by Alkhidmat medical staff at the blood center.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildCheckTile({
    required String title,
    required String subtitle,
    required bool value,
    bool isNegative = false,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: isNegative ? AppColors.standardUrgency : AppColors.primaryRed,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
