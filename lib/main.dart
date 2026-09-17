import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/user_models.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/splash_onboarding_screen.dart';
import 'features/donor/donor_home_screen.dart';
import 'features/seeker/create_request_screen.dart';
import 'features/admin/admin_verification_queue_screen.dart';
import 'features/admin/drive_management_screen.dart';
import 'providers/app_state_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase.initializeApp() notice: $e');
  }
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('SupabaseService.initialize() notice: $e');
  }
  runApp(
    const ProviderScope(
      child: QatraApp(),
    ),
  );
}

class QatraApp extends ConsumerWidget {
  const QatraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return MaterialApp(
      title: 'QATRA — Emergency Blood Response',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _resolveHomeScreen(user.role),
    );
  }

  Widget _resolveHomeScreen(UserRole role) {
    switch (role) {
      case UserRole.guest:
        return const SplashOnboardingScreen();
      case UserRole.seeker:
        return const CreateRequestScreen();
      case UserRole.donor:
        return const DonorHomeScreen();
      case UserRole.admin:
        return const AdminVerificationQueueScreen();
      case UserRole.driveOrganizer:
        return const DriveManagementScreen();
    }
  }
}
