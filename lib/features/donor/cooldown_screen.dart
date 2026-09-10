import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import '../awareness/awareness_screen.dart';

class CooldownScreen extends ConsumerWidget {
  const CooldownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final int remainingDays = user.cooldownDaysRemaining > 0 ? user.cooldownDaysRemaining : 0;
    final double progress = remainingDays > 0 ? (90 - remainingDays) / 90.0 : 1.0;

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Wireframe Screen 18: Success confirmation banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Donation Confirmed!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thank You for Saving a Life in Karachi.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Circular Cooldown Indicator
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Recovery Cooldown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation(AppColors.primaryRed),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$remainingDays',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            const Text(
                              'Days Remaining',
                              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: remainingDays > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: remainingDays > 0 ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            remainingDays > 0 ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                            color: remainingDays > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              remainingDays > 0
                                  ? 'Your donor profile is temporarily paused from emergency alerts to ensure full recovery. Day-85 reminder active.'
                                  : 'You have completed full recovery and are 100% eligible to donate blood! Keep your availability active.',
                              style: TextStyle(
                                fontSize: 11,
                                color: remainingDays > 0 ? const Color(0xFF92400E) : const Color(0xFF166534),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wireframe Screen 19: Healthy Nutrition Tips & Awareness Hub
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.restaurant_rounded, color: Color(0xFF0284C7), size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Healthy Nutrition Tips',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Rebuild your iron stores faster with these 5 delicious, iron-rich recipes designed for Pakistani donors (spinach, lentils, dates & citrus fruits).',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Explore Awareness & Health Hub Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AwarenessScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Explore Awareness & Health Hub', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Testing Debug Button: Reset Cooldown
              TextButton(
                onPressed: () {
                  ref.read(userProvider.notifier).resetCooldown();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cooldown reset for testing. You are now Eligible & Active!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  '[Dev / Review Mode: Reset 90-Day Cooldown]',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
