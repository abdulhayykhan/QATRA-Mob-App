import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import '../auth/google_auth_screen.dart';

class SplashOnboardingScreen extends ConsumerWidget {
  const SplashOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Language Switcher header
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language_rounded, size: 14, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text(
                        'EN / اردو',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),

              // Brand Blood Drop Icon / Logo
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'media/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Brand Title & Tagline
              const Text(
                'QATRA',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.primaryDarkRed,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Alkhidmat Foundation Pakistan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Connecting Verified Seekers to Eligible Donors\nin Minutes, Not Hours',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Primary Action: Need Blood Urgently (Seeker)
              ElevatedButton(
                onPressed: () {
                  ref.read(userProvider.notifier).switchRole(UserRole.seeker);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoogleAuthScreen(isSeeker: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Need Blood Urgently',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Emergency Seeker',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Secondary Action: Register as Voluntary Donor
              OutlinedButton(
                onPressed: () {
                  ref.read(userProvider.notifier).switchRole(UserRole.donor);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GoogleAuthScreen(isSeeker: false),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_rounded, color: AppColors.primaryRed, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Register as Voluntary Donor',
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Emergency Helpline & Footer
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent_rounded, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Text(
                    'Emergency Helpline: 112 / 1021',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'A life-saving initiative. By continuing, you agree to our Terms.',
                style: TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
