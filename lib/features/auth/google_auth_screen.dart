import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_models.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_providers.dart';
import 'profile_setup_screen.dart';

class GoogleAuthScreen extends ConsumerStatefulWidget {
  final bool isSeeker;
  const GoogleAuthScreen({super.key, required this.isSeeker});

  @override
  ConsumerState<GoogleAuthScreen> createState() => _GoogleAuthScreenState();
}

class _GoogleAuthScreenState extends ConsumerState<GoogleAuthScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final success = await ref.read(userProvider.notifier).signInWithGoogle(
            initialRole: widget.isSeeker ? UserRole.seeker : UserRole.donor,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final currentUser = ref.read(userProvider);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(
              phone: currentUser.phone.isNotEmpty ? currentUser.phone : '+92 300 1234567',
              isSeeker: widget.isSeeker,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In canceled or unavailable.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Account Sign In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Brand Icon
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLightRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bloodtype_rounded,
                  color: AppColors.primaryRed,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Welcome to QATRA',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in with your Google or University account. All notifications and emergency alerts are delivered via Email and In-App push notifications.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 36),

              // "Continue with Google" Official Style Button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: InkWell(
                  onTap: _isLoading ? null : _handleGoogleSignIn,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primaryRed)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Signing in with Google...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        ] else ...[
                          // Google 'G' Icon
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            child: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Free Tier & Zero SMS Notice (User Requirement)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '100% Free-Tier Architecture: Zero SMS costs. All verification & dispatch notices are delivered via Email and real-time In-App push notifications.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF15803D), height: 1.3),
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
  }
}
